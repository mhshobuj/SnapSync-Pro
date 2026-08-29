import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/mock_network_service.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';

class SyncHeaderStatus extends StatelessWidget {
  final SyncState state;

  const SyncHeaderStatus({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (state.networkCondition) {
      case NetworkCondition.stable:
        statusColor = const Color(0xFF10B981);
        statusText = 'STABLE LINK';
        statusIcon = Icons.wifi;
        break;
      case NetworkCondition.lowBandwidth:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'LOW BANDWIDTH';
        statusIcon = Icons.network_check;
        break;
      case NetworkCondition.disconnected:
        statusColor = const Color(0xFFEF4444);
        statusText = 'NO INTERNET';
        statusIcon = Icons.wifi_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title & Connection Badge
              const Text(
                'Upload Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Network Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Network Simulation Controls (For testing offline/low bandwidth retries easily)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Simulate Net: ',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('Stable'),
                  selected: state.networkCondition == NetworkCondition.stable,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<SyncBloc>().add(const SetNetworkConditionEvent(NetworkCondition.stable));
                    }
                  },
                  selectedColor: const Color(0xFF10B981).withOpacity(0.3),
                  labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('Low BW'),
                  selected: state.networkCondition == NetworkCondition.lowBandwidth,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<SyncBloc>().add(const SetNetworkConditionEvent(NetworkCondition.lowBandwidth));
                    }
                  },
                  selectedColor: const Color(0xFFF59E0B).withOpacity(0.3),
                  labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('Offline'),
                  selected: state.networkCondition == NetworkCondition.disconnected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<SyncBloc>().add(const SetNetworkConditionEvent(NetworkCondition.disconnected));
                    }
                  },
                  selectedColor: const Color(0xFFEF4444).withOpacity(0.3),
                  labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
