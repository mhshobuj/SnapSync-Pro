import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/upload_batch.dart';
import '../../domain/models/sync_status.dart';

class ImageViewerDialog extends StatelessWidget {
  final UploadBatch batch;

  const ImageViewerDialog({super.key, required this.batch});

  static void show(BuildContext context, UploadBatch batch) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => ImageViewerDialog(batch: batch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = batch.items.isNotEmpty ? batch.items.first : null;
    final filePath = item?.filePath ?? '';
    final hasFile = filePath.isNotEmpty && File(filePath).existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Filename & Close Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          batch.batchName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white10, height: 1),

                // Image Viewer Area with Pinch-to-Zoom
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.black,
                        child: hasFile
                            ? InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: Image.file(
                                  File(filePath),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.broken_image_outlined, color: Colors.white38, size: 64),
                                    SizedBox(height: 12),
                                    Text(
                                      'Image file preview unavailable',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                // Image Metadata Info Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Captured: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(batch.createdAt)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'File Size: ${(batch.totalBytes / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: batch.status == SyncStatus.synced
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: batch.status == SyncStatus.synced
                                ? const Color(0xFF10B981)
                                : Colors.blue,
                          ),
                        ),
                        child: Text(
                          batch.status.label,
                          style: TextStyle(
                            color: batch.status == SyncStatus.synced
                                ? const Color(0xFF10B981)
                                : Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
