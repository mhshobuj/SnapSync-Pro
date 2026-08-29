import 'package:flutter/material.dart';

class ZoomControlsWidget extends StatelessWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final List<double> presetZooms;
  final ValueChanged<double> onZoomChanged;

  const ZoomControlsWidget({
    super.key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.presetZooms,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Side Vertical Zoom Slider matching PDF design
        Positioned(
          right: 12,
          top: MediaQuery.of(context).size.height * 0.25,
          bottom: MediaQuery.of(context).size.height * 0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: currentZoom.clamp(minZoom, maxZoom),
                  min: minZoom,
                  max: maxZoom,
                  onChanged: onZoomChanged,
                ),
              ),
            ),
          ),
        ),

        // Rounded Zoom Pills (0.5x, 1x, 2x) at the bottom center above shutter
        Positioned(
          left: 0,
          right: 0,
          bottom: 195,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: presetZooms.map((zoom) {
                  final isSelected = (currentZoom - zoom).abs() < 0.15;
                  return GestureDetector(
                    onTap: () => onZoomChanged(zoom),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.amberAccent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          zoom < 1 ? '${zoom}x' : '${zoom.toInt()}x',
                          style: TextStyle(
                            color: isSelected ? Colors.amberAccent : Colors.white,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
