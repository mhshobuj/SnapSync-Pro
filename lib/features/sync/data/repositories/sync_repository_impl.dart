import '../../domain/models/upload_batch.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_local_datasource.dart';
import '../../../../core/network/mock_network_service.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncLocalDataSource localDataSource;
  final MockNetworkService networkService;

  SyncRepositoryImpl({
    required this.localDataSource,
    required this.networkService,
  });

  @override
  Future<void> saveBatch(UploadBatch batch) async {
    await localDataSource.saveBatch(batch);
  }

  @override
  List<UploadBatch> getBatches() {
    return localDataSource.getAllBatches();
  }

  @override
  Future<void> deleteBatch(String batchId) async {
    await localDataSource.deleteBatch(batchId);
  }

  @override
  Stream<double> uploadBatch(UploadBatch batch, {bool simulateFailure = false}) {
    return networkService.uploadBatchStream(
      batchId: batch.id,
      totalBytes: batch.totalBytes,
      simulateFailure: simulateFailure,
    );
  }

  @override
  void setNetworkCondition(NetworkCondition condition) {
    networkService.setCondition(condition);
  }

  @override
  NetworkCondition getNetworkCondition() {
    return networkService.condition;
  }
}
