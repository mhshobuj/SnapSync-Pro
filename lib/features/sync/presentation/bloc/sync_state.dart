import 'package:equatable/equatable.dart';
import '../../domain/models/upload_batch.dart';
import '../../../../core/network/mock_network_service.dart';

class SyncState extends Equatable {
  final List<UploadBatch> batches;
  final double overallProgress;
  final int totalUploadedBytes;
  final int totalQueueBytes;
  final NetworkCondition networkCondition;
  final bool isSyncing;
  final bool isPaused;
  final bool simulateFailures;
  final String? lastMessage;

  const SyncState({
    this.batches = const [],
    this.overallProgress = 0.0,
    this.totalUploadedBytes = 0,
    this.totalQueueBytes = 0,
    this.networkCondition = NetworkCondition.stable,
    this.isSyncing = false,
    this.isPaused = false,
    this.simulateFailures = false,
    this.lastMessage,
  });

  SyncState copyWith({
    List<UploadBatch>? batches,
    double? overallProgress,
    int? totalUploadedBytes,
    int? totalQueueBytes,
    NetworkCondition? networkCondition,
    bool? isSyncing,
    bool? isPaused,
    bool? simulateFailures,
    String? lastMessage,
  }) {
    return SyncState(
      batches: batches ?? this.batches,
      overallProgress: overallProgress ?? this.overallProgress,
      totalUploadedBytes: totalUploadedBytes ?? this.totalUploadedBytes,
      totalQueueBytes: totalQueueBytes ?? this.totalQueueBytes,
      networkCondition: networkCondition ?? this.networkCondition,
      isSyncing: isSyncing ?? this.isSyncing,
      isPaused: isPaused ?? this.isPaused,
      simulateFailures: simulateFailures ?? this.simulateFailures,
      lastMessage: lastMessage,
    );
  }

  @override
  List<Object?> get props => [
        batches,
        overallProgress,
        totalUploadedBytes,
        totalQueueBytes,
        networkCondition,
        isSyncing,
        isPaused,
        simulateFailures,
        lastMessage,
      ];
}
