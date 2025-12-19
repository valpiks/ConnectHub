import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart'; // Added
import '../../auth/domain/user.dart';

class HomeRepository {
  final Dio _client = ApiClient.instance;

  Future<List<User>> getUsers({int offset = 0, int limit = 10}) async {
    try {
      final response =
          await _client.get('/users/recommendation', queryParameters: {
        'offset': offset,
        'limit': limit,
      });

      final list = (response.data['users'] as List)
          .map((e) => User.fromJson(e))
          .toList();

      return list;
    } catch (e) {
      // Return empty list on error for now
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEvents(
      {int offset = 0, int limit = 10}) async {
    try {
      final response =
          await _client.get('/events/recommendation', queryParameters: {
        'offset': offset,
        'limit': limit,
      });

      if (response.data != null && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data;

        if (data.containsKey('events') && data['events'] is List) {
          return List<Map<String, dynamic>>.from(data['events']);
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> matchUser(String userId) async {
    try {
      await _client.post('/users/match', data: {'id': userId});
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error!;
      }
      rethrow;
    }
  }

  // MARK: - Swipes API Markup

  /// User disliked (swiped left)
  Future<void> passUser(String userId) async {
    try {
      await _client.post('/users/cancel', data: {'id': userId});
    } catch (e) {
      // Handle error
    }
  }

  /// Event liked/interested (swiped right)
  Future<void> registerEvent(dynamic eventId) async {
    try {
      await _client.post('/events/$eventId/add');
    } catch (e) {
      // Handle error
    }
  }

  /// Event skipped (swiped left)
  Future<void> passEvent(dynamic eventId) async {
    try {
      await _client.post('/events/$eventId/cancel');
    } catch (e) {
      // Handle error
    }
  }
}
