import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../model/place_model.dart';

class RepositoryException implements Exception {
  final String message;
  RepositoryException(this.message);
  @override
  String toString() => message;
}

class KakaoMapRepository {
  Future<List<PlaceModel>> searchPlace({
    required String keyword,
    required double lat,
    required double lng,
  }) async {
    final restApiKey = dotenv.env['KAKAO_REST_API_KEY'];
    if (restApiKey == null || restApiKey.isEmpty) {
      throw RepositoryException('REST API KEY is missing. Please check .env file.');
    }

    // Kakao Local API uses 'x' for longitude and 'y' for latitude.
    final url = Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword&x=$lng&y=$lat');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $restApiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] as List;
        
        return documents.map((e) => PlaceModel.fromJson(e)).toList();
      } else {
        throw RepositoryException('Search API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Failed to search places: $e');
    }
  }

  Future<String> coordToAddress({required double lat, required double lng}) async {
    final restApiKey = dotenv.env['KAKAO_REST_API_KEY'];
    if (restApiKey == null || restApiKey.isEmpty) {
      return '알 수 없음';
    }

    final url = Uri.parse('https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $restApiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] as List;
        if (documents.isNotEmpty) {
          final address = documents[0]['address'];
          final roadAddress = documents[0]['road_address'];
          if (roadAddress != null && roadAddress['address_name'] != null) {
            return roadAddress['address_name'];
          } else if (address != null && address['address_name'] != null) {
            return address['address_name'];
          }
        }
      }
    } catch (e) {
      debugPrint('coordToAddress error: $e');
    }
    return '알 수 없음';
  }
}
