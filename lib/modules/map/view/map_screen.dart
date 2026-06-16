import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../controller/map_controller.dart';
import '../controller/alarm_controller.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/search_result_overlay.dart';
import 'widgets/menu_bottom_sheet.dart';
import 'widgets/alarm_setup_bottom_sheet.dart';
import 'alarm_ringing_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  final AlarmController _alarmController = AlarmController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mapController = MapController(
      onLocationError: (message) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 3),
            ),
          );
        });
      },
    );
    _initForegroundTaskListener();
  }

  void _initForegroundTaskListener() {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is String && data.startsWith('ALARM_TRIGGERED')) {
      final parts = data.split('_');
      final distance = parts.length > 2 ? parts[2] : '0';
      
      // Prevent pushing multiple times
      if (ModalRoute.of(context)?.settings.name != '/alarm') {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/alarm'),
            builder: (_) => AlarmRingingScreen(distance: distance),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _unfocusAndClear() {
    _searchFocusNode.unfocus();
    _mapController.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: _unfocusAndClear,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _mapController,
              builder: (context, child) {
                if (!_mapController.isLocationInitialized) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }
                return Listener(
                  onPointerDown: (_) {
                    // Disable tracking when user touches the map to pan
                    _mapController.disableTrackingMode();
                  },
                  child: KakaoMap(
                    center: _mapController.currentLocation,
                    onMapCreated: (controller) {
                      _mapController.onMapCreated(controller);
                    },
                    markers: _mapController.markers.toList(),
                  ),
                );
              },
            ),
          ),
          // Tracking Direction Overlay
          AnimatedBuilder(
            animation: _mapController,
            builder: (context, child) {
              if (_mapController.isTrackingMode) {
                return Center(
                  child: Transform.rotate(
                    angle: _mapController.heading * (3.1415926535897932 / 180),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.redAccent,
                      size: 40,
                      shadows: [
                        Shadow(color: Colors.white, blurRadius: 10),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchBarWidget(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onSubmitted: (value) {
                      _mapController.searchPlace(value);
                    },
                    onClear: () {
                      _searchController.clear();
                      _unfocusAndClear();
                    },
                    onMenuPressed: () {
                      _unfocusAndClear();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => MenuBottomSheet(
                          mapController: _mapController,
                          alarmController: _alarmController,
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _mapController,
                    builder: (context, child) {
                      return SearchResultOverlay(
                        isSearching: _mapController.isSearching,
                        hasSearched: _mapController.hasSearched,
                        searchResults: _mapController.searchResults,
                        onPlaceSelected: (place) {
                          _searchFocusNode.unfocus();
                          _searchController.text = place.placeName;
                          _mapController.selectPlace(place);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: AnimatedBuilder(
              animation: _mapController,
              builder: (context, child) {
                return FloatingActionButton(
                  backgroundColor: _mapController.isTrackingMode ? Colors.blueAccent : Colors.white,
                  onPressed: () {
                    _unfocusAndClear();
                    _mapController.toggleTrackingMode();
                  },
                  child: Icon(
                    _mapController.isTrackingMode ? Icons.explore : Icons.my_location,
                    color: _mapController.isTrackingMode ? Colors.white : Colors.blueAccent,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

