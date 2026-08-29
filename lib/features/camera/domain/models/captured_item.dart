import 'package:equatable/equatable.dart';

class CapturedItem extends Equatable {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  const CapturedItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.timestamp,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      };

  factory CapturedItem.fromJson(Map<String, dynamic> json) {
    return CapturedItem(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        filePath,
        fileName,
        fileSizeBytes,
        timestamp,
        latitude,
        longitude,
      ];
}
