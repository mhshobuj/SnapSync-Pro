import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/sync_status.dart';
import '../../domain/models/upload_batch.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../../../core/network/mock_network_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncRepository repository;
  StreamSubscription? _connectivitySubscription;
  final Map<String, StreamSubscription> _uploadSubscriptions = {};

  SyncBloc({required this.repository}) : super(const SyncState()) {
    on<LoadSyncQueueEvent>(_onLoadSyncQueue);
    on<CreateBatchAndQueueEvent>(_onCreateBatchAndQueue);
    on<StartSyncProcessEvent>(_onStartSyncProcess);
    on<SetNetworkConditionEvent>(_onSetNetworkCondition);
    on<TogglePauseAllEvent>(_onTogglePauseAll);
    on<DeleteBatchEvent>(_onDeleteBatch);
    on<BatchProgressUpdatedEvent>(_onBatchProgressUpdated);
    on<BatchStatusUpdatedEvent>(_onBatchStatusUpdated);

    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && state.networkCondition == NetworkCondition.disconnected) {
        add(const SetNetworkConditionEvent(NetworkCondition.stable));
      } else if (!hasConnection) {
        add(const SetNetworkConditionEvent(NetworkCondition.disconnected));
      }
    });
  }

  Future<void> _onLoadSyncQueue(
    LoadSyncQueueEvent event,
    Emitter<SyncState> emit,
  ) async {
    var batches = repository.getBatches();

    // Purge legacy sample dummy data if present in local Hive storage
    if (batches.any((b) => b.id == '1' || b.id == '2' || b.id == '3' || b.id == '4' || b.id == '5')) {
      for (var b in batches.toList()) {
        if (b.id == '1' || b.id == '2' || b.id == '3' || b.id == '4' || b.id == '5') {
          await repository.deleteBatch(b.id);
        }
      }
      batches = repository.getBatches();
    }

    _recalculateProgress(batches, emit);
  }

  Future<void> _onCreateBatchAndQueue(
    CreateBatchAndQueueEvent event,
    Emitter<SyncState> emit,
  ) async {
    if (event.items.isEmpty) return;

    for (int i = 0; i < event.items.length; i++) {
      final item = event.items[i];
      final batch = UploadBatch(
        id: item.id,
        batchName: item.fileName,
        items: [item],
        totalBytes: item.fileSizeBytes > 0 ? item.fileSizeBytes : 250 * 1024,
        status: state.networkCondition == NetworkCondition.disconnected
            ? SyncStatus.waitingConnection
            : SyncStatus.inQueue,
        createdAt: item.timestamp,
      );
      await repository.saveBatch(batch);
    }

    final updatedList = repository.getBatches();
    _recalculateProgress(updatedList, emit);

    // Auto-start sync if connected
    if (state.networkCondition != NetworkCondition.disconnected && !state.isPaused) {
      add(StartSyncProcessEvent());
    }
  }

  Future<void> _onStartSyncProcess(
    StartSyncProcessEvent event,
    Emitter<SyncState> emit,
  ) async {
    if (state.isPaused || state.networkCondition == NetworkCondition.disconnected) {
      return;
    }

    final pendingBatches = state.batches.where((b) =>
        b.status == SyncStatus.inQueue ||
        b.status == SyncStatus.waitingConnection ||
        b.status == SyncStatus.retrying ||
        b.status == SyncStatus.failed).toList();

    if (pendingBatches.isEmpty) return;

    emit(state.copyWith(isSyncing: true));

    for (var batch in pendingBatches) {
      if (state.isPaused || state.networkCondition == NetworkCondition.disconnected) break;
      _uploadSingleBatch(batch);
    }
  }

  void _uploadSingleBatch(UploadBatch batch) {
    _uploadSubscriptions[batch.id]?.cancel();

    add(BatchStatusUpdatedEvent(batch.id, SyncStatus.uploading));

    final stream = repository.uploadBatch(
      batch,
      simulateFailure: state.simulateFailures && state.networkCondition == NetworkCondition.lowBandwidth,
    );

    _uploadSubscriptions[batch.id] = stream.listen(
      (progress) {
        add(BatchProgressUpdatedEvent(batch.id, progress));
      },
      onError: (error) {
        add(BatchStatusUpdatedEvent(
          batch.id,
          state.networkCondition == NetworkCondition.disconnected
              ? SyncStatus.waitingConnection
              : SyncStatus.retrying,
          error: error.toString(),
        ));
      },
      onDone: () {
        add(BatchStatusUpdatedEvent(batch.id, SyncStatus.synced));
        _uploadSubscriptions.remove(batch.id);
      },
    );
  }

  Future<void> _onBatchProgressUpdated(
    BatchProgressUpdatedEvent event,
    Emitter<SyncState> emit,
  ) async {
    final batchIndex = state.batches.indexWhere((b) => b.id == event.batchId);
    if (batchIndex == -1) return;

    final oldBatch = state.batches[batchIndex];
    final uploadedBytes = (oldBatch.totalBytes * event.progress).toInt();
    final updatedBatch = oldBatch.copyWith(
      progress: event.progress,
      uploadedBytes: uploadedBytes,
      status: SyncStatus.uploading,
    );

    await repository.saveBatch(updatedBatch);
    final currentBatches = repository.getBatches();
    _recalculateProgress(currentBatches, emit);
  }

  Future<void> _onBatchStatusUpdated(
    BatchStatusUpdatedEvent event,
    Emitter<SyncState> emit,
  ) async {
    final batchIndex = state.batches.indexWhere((b) => b.id == event.batchId);
    if (batchIndex == -1) return;

    final oldBatch = state.batches[batchIndex];
    final SyncStatus status = event.status as SyncStatus;
    
    final updatedBatch = oldBatch.copyWith(
      status: status,
      retryCount: status == SyncStatus.retrying ? oldBatch.retryCount + 1 : oldBatch.retryCount,
      progress: status == SyncStatus.synced ? 1.0 : oldBatch.progress,
      uploadedBytes: status == SyncStatus.synced ? oldBatch.totalBytes : oldBatch.uploadedBytes,
    );

    await repository.saveBatch(updatedBatch);
    final currentBatches = repository.getBatches();
    _recalculateProgress(currentBatches, emit, lastMsg: event.error);
  }

  Future<void> _onSetNetworkCondition(
    SetNetworkConditionEvent event,
    Emitter<SyncState> emit,
  ) async {
    repository.setNetworkCondition(event.condition);
    emit(state.copyWith(networkCondition: event.condition));

    if (event.condition == NetworkCondition.disconnected) {
      // Pause active upload streams and update status to waiting
      for (var sub in _uploadSubscriptions.values) {
        sub.cancel();
      }
      _uploadSubscriptions.clear();

      final updated = state.batches.map((b) {
        if (b.status == SyncStatus.uploading || b.status == SyncStatus.inQueue) {
          return b.copyWith(status: SyncStatus.waitingConnection);
        }
        return b;
      }).toList();

      for (var b in updated) {
        await repository.saveBatch(b);
      }
      _recalculateProgress(updated, emit);
    } else {
      // Automatically retry uploads when network is restored!
      add(StartSyncProcessEvent());
    }
  }

  Future<void> _onTogglePauseAll(
    TogglePauseAllEvent event,
    Emitter<SyncState> emit,
  ) async {
    final newPausedState = !state.isPaused;

    if (newPausedState) {
      for (var sub in _uploadSubscriptions.values) {
        sub.cancel();
      }
      _uploadSubscriptions.clear();

      final updated = state.batches.map((b) {
        if (b.status == SyncStatus.uploading) {
          return b.copyWith(status: SyncStatus.paused);
        }
        return b;
      }).toList();

      for (var b in updated) {
        await repository.saveBatch(b);
      }
      _recalculateProgress(updated, emit);
      emit(state.copyWith(isPaused: true, isSyncing: false));
    } else {
      emit(state.copyWith(isPaused: false));
      add(StartSyncProcessEvent());
    }
  }

  Future<void> _onDeleteBatch(
    DeleteBatchEvent event,
    Emitter<SyncState> emit,
  ) async {
    _uploadSubscriptions[event.batchId]?.cancel();
    _uploadSubscriptions.remove(event.batchId);

    await repository.deleteBatch(event.batchId);
    final currentBatches = repository.getBatches();
    _recalculateProgress(currentBatches, emit);
  }

  void _recalculateProgress(
    List<UploadBatch> batches,
    Emitter<SyncState> emit, {
    String? lastMsg,
  }) {
    int totalBytes = 0;
    int uploadedBytes = 0;

    for (var b in batches) {
      totalBytes += b.totalBytes;
      uploadedBytes += b.uploadedBytes;
    }

    final overallProgress = totalBytes > 0 ? (uploadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
    final isStillSyncing = batches.any((b) => b.status == SyncStatus.uploading);

    emit(state.copyWith(
      batches: batches,
      totalQueueBytes: totalBytes,
      totalUploadedBytes: uploadedBytes,
      overallProgress: overallProgress,
      isSyncing: isStillSyncing,
      lastMessage: lastMsg,
    ));
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    for (var sub in _uploadSubscriptions.values) {
      sub.cancel();
    }
    return super.close();
  }
}
