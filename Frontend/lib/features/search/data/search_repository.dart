import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../auth/domain/user.dart';

class SearchRepository {
  final Dio _client = ApiClient.instance;

  Future<List<User>> searchUsers({
    String? text,
    String? tags,
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get('/users/search', queryParameters: {
        'text': text,
        'tags': tags,
        'offset': offset,
        'limit': limit,
      });

      final list = (response.data["users"] as List)
          .map((e) => User.fromJson(e))
          .toList();

      return list;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchEvents({
    String? text,
    String? tags,
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get('/events/search', queryParameters: {
        'text': text,
        'tags': tags,
        'offset': offset,
        'limit': limit,
      });

      final events = (response.data['events'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      return events;
    } catch (e) {
      return [];
    }
  }
}
