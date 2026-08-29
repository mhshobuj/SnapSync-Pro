import '../models/upload_batch.dart';
import '../../../../core/network/mock_network_service.dart';

abstract class SyncRepository {
  Future<void> saveBatch(UploadBatch batch);
  List<UploadBatch> getBatches();
  Future<void> deleteBatch(String batchId);
  Stream<double> uploadBatch(UploadBatch batch, {bool simulateFailure = false});
  void setNetworkCondition(NetworkCondition condition);
  NetworkCondition getNetworkCondition();
}
