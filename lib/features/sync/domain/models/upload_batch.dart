import 'package:equatable/equatable.dart';
import '../../../camera/domain/models/captured_item.dart';
import 'sync_status.dart';

class UploadBatch extends Equatable {
  final String id;
  final String batchName;
  final List<CapturedItem> items;
  final int totalBytes;
  final int uploadedBytes;
  final double progress;
  final SyncStatus status;
  final DateTime createdAt;
  final int retryCount;

  const UploadBatch({
    required this.id,
    required this.batchName,
    required this.items,
    required this.totalBytes,
    this.uploadedBytes = 0,
    this.progress = 0.0,
    this.status = SyncStatus.inQueue,
    required this.createdAt,
    this.retryCount = 0,
  });

  UploadBatch copyWith({
    String? id,
    String? batchName,
    List<CapturedItem>? items,
    int? totalBytes,
    int? uploadedBytes,
    double? progress,
    SyncStatus? status,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return UploadBatch(
      id: id ?? this.id,
      batchName: batchName ?? this.batchName,
      items: items ?? this.items,
      totalBytes: totalBytes ?? this.totalBytes,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'batchName': batchName,
        'items': items.map((i) => i.toJson()).toList(),
        'totalBytes': totalBytes,
        'uploadedBytes': uploadedBytes,
        'progress': progress,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory UploadBatch.fromJson(Map<String, dynamic> json) {
    return UploadBatch(
      id: json['id'] as String,
      batchName: json['batchName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => CapturedItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalBytes: json['totalBytes'] as int,
      uploadedBytes: json['uploadedBytes'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: SyncStatus.values[json['status'] as int? ?? 0],
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        batchName,
        items,
        totalBytes,
        uploadedBytes,
        progress,
        status,
        createdAt,
        retryCount,
      ];
}
