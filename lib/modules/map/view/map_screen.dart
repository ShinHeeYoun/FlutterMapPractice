import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../controller/map_controller.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mapController = MapController(
      onOutOfBoundary: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('국내 위치만 지원하여 서울 중심으로 이동합니다.'),
              duration: Duration(seconds: 3),
            ),
          );
        });
      },
    );
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
                return KakaoMap(
                  center: _mapController.currentLocation,
                  onMapCreated: (controller) {
                    _mapController.onMapCreated(controller);
                  },
                  markers: _mapController.markers.toList(),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.search, color: Colors.grey),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: const InputDecoration(
                              hintText: '장소 검색',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              _mapController.searchPlace(value);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _unfocusAndClear();
                          },
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _mapController,
                    builder: (context, child) {
                      if (!_mapController.hasSearched && !_mapController.isSearching) {
                        return const SizedBox.shrink();
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(top: 8.0),
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildSearchResults(),
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
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                _unfocusAndClear();
                _mapController.moveToCurrentLocation();
              },
              child: const Icon(Icons.my_location, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_mapController.isSearching) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_mapController.searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            '검색 결과가 없습니다',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _mapController.searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = _mapController.searchResults[index];
        // Kakao Local API returns distance in meters as a string if 'sort' is distance and x, y are provided.
        final distanceStr = place['distance'] as String?;
        String distanceText = '';
        if (distanceStr != null && distanceStr.isNotEmpty) {
          final distanceVal = int.tryParse(distanceStr);
          if (distanceVal != null) {
            if (distanceVal < 1000) {
              distanceText = '${distanceVal}m';
            } else {
              distanceText = '${(distanceVal / 1000).toStringAsFixed(1)}km';
            }
          }
        }

        return ListTile(
          title: Text(place['place_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(place['address_name'] ?? ''),
          trailing: distanceText.isNotEmpty 
            ? Text(distanceText, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500))
            : null,
          onTap: () {
            _searchFocusNode.unfocus();
            _searchController.text = place['place_name'] ?? '';
            _mapController.selectPlace(place);
          },
        );
      },
    );
  }
}
