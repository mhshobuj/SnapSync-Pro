import 'package:equatable/equatable.dart';
import '../../../camera/domain/models/captured_item.dart';
import '../../../../core/network/mock_network_service.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class LoadSyncQueueEvent extends SyncEvent {}

class CreateBatchAndQueueEvent extends SyncEvent {
  final List<CapturedItem> items;
  const CreateBatchAndQueueEvent(this.items);

  @override
  List<Object?> get props => [items];
}

class StartSyncProcessEvent extends SyncEvent {}

class SetNetworkConditionEvent extends SyncEvent {
  final NetworkCondition condition;
  const SetNetworkConditionEvent(this.condition);

  @override
  List<Object?> get props => [condition];
}

class TogglePauseAllEvent extends SyncEvent {}

class DeleteBatchEvent extends SyncEvent {
  final String batchId;
  const DeleteBatchEvent(this.batchId);

  @override
  List<Object?> get props => [batchId];
}

class BatchProgressUpdatedEvent extends SyncEvent {
  final String batchId;
  final double progress;
  const BatchProgressUpdatedEvent(this.batchId, this.progress);

  @override
  List<Object?> get props => [batchId, progress];
}

class BatchStatusUpdatedEvent extends SyncEvent {
  final String batchId;
  final dynamic status;
  final String? error;
  const BatchStatusUpdatedEvent(this.batchId, this.status, {this.error});

  @override
  List<Object?> get props => [batchId, status, error];
}
