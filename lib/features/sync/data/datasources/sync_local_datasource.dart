import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/upload_batch.dart';

class SyncLocalDataSource {
  static const String boxName = 'upload_batches_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(boxName);
  }

  Box<String> get _box => Hive.box<String>(boxName);

  Future<void> saveBatch(UploadBatch batch) async {
    final jsonStr = jsonEncode(batch.toJson());
    await _box.put(batch.id, jsonStr);
  }

  List<UploadBatch> getAllBatches() {
    final list = <UploadBatch>[];
    for (var key in _box.keys) {
      final jsonStr = _box.get(key);
      if (jsonStr != null) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          list.add(UploadBatch.fromJson(map));
        } catch (_) {}
      }
    }
    // Sort newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> deleteBatch(String batchId) async {
    await _box.delete(batchId);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
