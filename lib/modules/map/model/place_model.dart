class PlaceModel {
  final String placeName;
  final String addressName;
  final double lat; // y
  final double lng; // x
  final String distanceText;

  PlaceModel({
    required this.placeName,
    required this.addressName,
    required this.lat,
    required this.lng,
    required this.distanceText,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    // Kakao Local API returns distance in meters as a string
    final distanceStr = json['distance'] as String?;
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

    return PlaceModel(
      placeName: json['place_name'] ?? '',
      addressName: json['address_name'] ?? '',
      lat: double.tryParse(json['y']?.toString() ?? '0') ?? 0,
      lng: double.tryParse(json['x']?.toString() ?? '0') ?? 0,
      distanceText: distanceText,
    );
  }
}
