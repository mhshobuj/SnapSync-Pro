import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';
import '../widgets/batch_item_card.dart';
import '../widgets/overall_progress_bar.dart';
import '../widgets/sync_header_status.dart';

class UploadManagerScreen extends StatefulWidget {
  const UploadManagerScreen({super.key});

  @override
  State<UploadManagerScreen> createState() => _UploadManagerScreenState();
}

class _UploadManagerScreenState extends State<UploadManagerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SyncBloc>().add(LoadSyncQueueEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'PENDING UPLOADS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, syncState) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Connectivity Status Card
                      SyncHeaderStatus(state: syncState),

                      const SizedBox(height: 16),

                      // Overall Progress Card
                      OverallProgressBar(state: syncState),

                      const SizedBox(height: 24),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PENDING UPLOADS (${syncState.batches.length})',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<SyncBloc>().add(StartSyncProcessEvent());
                            },
                            child: const Text(
                              'FORCE SYNC NOW',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // List of Batches
                      if (syncState.batches.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          child: const Center(
                            child: Text(
                              'No pending uploads in queue.',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: syncState.batches.length,
                          itemBuilder: (context, index) {
                            final batch = syncState.batches[index];
                            return BatchItemCard(batch: batch);
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Button matching PDF mockup: "START NEW UPLOAD BATCH"
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Back to camera preview
                      },
                      child: const Text(
                        'START NEW UPLOAD BATCH',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
