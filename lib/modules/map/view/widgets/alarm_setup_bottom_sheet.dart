import 'package:flutter/material.dart';
import '../../controller/alarm_controller.dart';
import '../../controller/map_controller.dart';
import '../../model/place_model.dart';
import 'package:provider/provider.dart';

class AlarmSetupBottomSheet extends StatefulWidget {
  final MapController mapController;
  final AlarmController alarmController;

  const AlarmSetupBottomSheet({
    super.key,
    required this.mapController,
    required this.alarmController,
  });

  @override
  State<AlarmSetupBottomSheet> createState() => _AlarmSetupBottomSheetState();
}

class _AlarmSetupBottomSheetState extends State<AlarmSetupBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceModel> _localSearchResults = [];
  bool _isSearching = false;

  void _searchPlace(String keyword) async {
    if (keyword.isEmpty) return;
    setState(() {
      _isSearching = true;
    });

    try {
      final lat = widget.mapController.currentLocation?.latitude ?? 37.4979;
      final lng = widget.mapController.currentLocation?.longitude ?? 127.0276;
      
      // Use mapController's repository to search (we can expose a method or just use searchPlace but it updates main UI)
      // Since we don't want to affect main map search state immediately, we could call repository directly 
      // but MapController's searchPlace modifies its own state. 
      // Let's just use the controller's state. Wait, if we use it, the main screen will also show results.
      await widget.mapController.searchPlace(keyword);
      setState(() {
        _localSearchResults = widget.mapController.searchResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const Text(
            '목적지 알림 설정',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Search Input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '목적지 검색 (예: 강남역)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _localSearchResults.clear();
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: _searchPlace,
          ),
          const SizedBox(height: 16),
          
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_localSearchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _localSearchResults.length,
                itemBuilder: (context, index) {
                  final place = _localSearchResults[index];
                  return ListTile(
                    title: Text(place.placeName),
                    subtitle: Text(place.roadAddressName.isNotEmpty ? place.roadAddressName : place.addressName),
                    onTap: () {
                      widget.alarmController.setDestination(place);
                      widget.mapController.selectPlace(place);
                      setState(() {
                        _localSearchResults.clear();
                        _searchController.text = place.placeName;
                      });
                    },
                  );
                },
              ),
            )
          else if (widget.alarmController.destination != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '현재 목적지: ${widget.alarmController.destination!.placeName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('알림 반경 설정', style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: widget.alarmController.radius,
              min: 100,
              max: 2000,
              divisions: 19,
              label: '${widget.alarmController.radius.toInt()}m',
              onChanged: (value) {
                widget.alarmController.setRadius(value);
                setState((){});
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.alarmController.isAlarmActive ? Colors.redAccent : Colors.blueAccent,
                ),
                onPressed: () async {
                  if (widget.alarmController.isAlarmActive) {
                    await widget.alarmController.stopAlarm();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('알림이 해제되었습니다.')),
                      );
                      setState((){});
                    }
                  } else {
                    final success = await widget.alarmController.startAlarm();
                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('알림이 설정되었습니다! 앱을 내려도 동작합니다.')),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('권한이 부족하여 알림을 설정할 수 없습니다.')),
                        );
                      }
                    }
                  }
                },
                child: Text(
                  widget.alarmController.isAlarmActive ? '알림 끄기' : '알림 켜기',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Text('위 검색창에서 목적지를 검색해주세요.'),
              ),
            ),
        ],
      ),
    );
  }
}
