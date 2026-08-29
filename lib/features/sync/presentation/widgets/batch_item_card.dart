import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/upload_batch.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import 'image_viewer_dialog.dart';

class BatchItemCard extends StatelessWidget {
  final UploadBatch batch;

  const BatchItemCard({super.key, required this.batch});

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  Color get _statusColor {
    switch (batch.status) {
      case SyncStatus.synced:
        return const Color(0xFF10B981);
      case SyncStatus.uploading:
        return const Color(0xFF3B82F6);
      case SyncStatus.waitingConnection:
        return const Color(0xFFF59E0B);
      case SyncStatus.retrying:
        return const Color(0xFFEF4444);
      case SyncStatus.inQueue:
        return Colors.white54;
      case SyncStatus.failed:
        return const Color(0xFFEF4444);
      case SyncStatus.paused:
        return Colors.purpleAccent;
    }
  }

  IconData get _fileIcon {
    if (batch.batchName.endsWith('.png') || batch.batchName.endsWith('.jpg')) {
      return Icons.image_outlined;
    } else if (batch.batchName.endsWith('.csv') || batch.batchName.endsWith('.json')) {
      return Icons.insert_chart_outlined;
    } else if (batch.batchName.endsWith('.zip') || batch.batchName.endsWith('.dat')) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  bool get _hasThumbnail {
    if (batch.items.isNotEmpty && batch.items.first.filePath.isNotEmpty) {
      return File(batch.items.first.filePath).existsSync();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ImageViewerDialog.show(context, batch),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // File Type Avatar / Image Thumbnail Box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: _hasThumbnail
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(batch.items.first.filePath),
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                    ),
                  )
                : Icon(_fileIcon, color: Colors.white70, size: 24),
          ),

          const SizedBox(width: 12),

          // File Information & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        batch.batchName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        context.read<SyncBloc>().add(DeleteBatchEvent(batch.id));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  _formatBytes(batch.totalBytes),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),

                // Status Label Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _statusColor.withOpacity(0.4), width: 0.8),
                  ),
                  child: Text(
                    batch.status == SyncStatus.retrying && batch.retryCount > 0
                        ? 'RETRYING... (${batch.retryCount})'
                        : batch.status.label,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                if (batch.status == SyncStatus.uploading) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: batch.progress,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
