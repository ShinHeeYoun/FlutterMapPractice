import 'package:flutter/material.dart';
import '../../controller/alarm_controller.dart';
import '../../controller/map_controller.dart';


class ActiveAlarmPanel extends StatefulWidget {
  final AlarmController alarmController;
  final MapController mapController;
  final double panelHeight;
  final double peekHeight;
  final Function(double) onHeightChanged;

  const ActiveAlarmPanel({
    super.key,
    required this.alarmController,
    required this.mapController,
    required this.panelHeight,
    required this.peekHeight,
    required this.onHeightChanged,
  });

  @override
  State<ActiveAlarmPanel> createState() => _ActiveAlarmPanelState();
}

class _ActiveAlarmPanelState extends State<ActiveAlarmPanel> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHeightChanged(_isExpanded ? widget.panelHeight : widget.peekHeight);
    });
  }

  void _togglePanel() {
    setState(() {
      _isExpanded = !_isExpanded;
      widget.onHeightChanged(_isExpanded ? widget.panelHeight : widget.peekHeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.alarmController.destination;
    if (destination == null) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: _isExpanded ? 0 : -(widget.panelHeight - widget.peekHeight),
      height: widget.panelHeight,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0 && _isExpanded) {
            // Swipe down
            _togglePanel();
          } else if (details.primaryVelocity! < 0 && !_isExpanded) {
            // Swipe up
            _togglePanel();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              GestureDetector(
                onTap: _togglePanel,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              // Peek content (always visible when peeked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        destination.placeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: widget.alarmController,
                      builder: (context, child) {
                        final dist = widget.alarmController.remainingDistance;
                        return Text(
                          dist > 0 ? '${dist.toStringAsFixed(0)}m 남음' : '계산 중...',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Expanded actions
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('알림 반경 설정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        AnimatedBuilder(
                          animation: widget.alarmController,
                          builder: (context, child) {
                            return Slider(
                              value: widget.alarmController.radius,
                              min: 100,
                              max: 2000,
                              divisions: 19,
                              label: '${widget.alarmController.radius.toInt()}m',
                              onChanged: (value) {
                                widget.alarmController.setRadius(value);
                              },
                              onChangeEnd: (value) async {
                                final current = widget.mapController.currentLocation;
                                String startName = '현재 위치';
                                if (current != null) {
                                  startName = '위도: ${current.latitude.toStringAsFixed(3)}, 경도: ${current.longitude.toStringAsFixed(3)}';
                                }
                                await widget.alarmController.startAlarm(startName: startName);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('반경이 ${value.toInt()}m로 적용되었습니다.')),
                                  );
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await widget.alarmController.stopAlarm();
                              widget.onHeightChanged(0);
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('알림 끄기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
