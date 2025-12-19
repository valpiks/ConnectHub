import 'dart:io';

import 'package:connecthub_app/core/api/api_client.dart';
import 'package:dio/dio.dart';

import '../../auth/domain/user.dart';

class ProfileRepository {
  final Dio _client = ApiClient.instance;

  Future<User?> getMe() async {
    try {
      final response = await _client.get('/users/profile');
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final response = await _client.get('/users/profile/$userId');
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    try {
      await _client.put('/users/edit', data: data);
    } on DioException catch (e) {
      // Log or handle specific errors
      rethrow;
    }
  }

  Future<void> addTags(List<String> tags, String type) async {
    try {
      await _client.post('/users/tags/add?type=$type', data: {"tags": tags});
    } on DioException catch (e) {
      // Log or handle specific errors
      rethrow;
    }
  }

  Future<void> removeTag(int tagId, String type) async {
    try {
      await _client.delete('/users/tags/remove/$tagId?type=$type');
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> searchUsers({
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
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRecommendations({
    String? text,
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response =
          await _client.get('/users/recommendation', queryParameters: {
        'text': text,
        'offset': offset,
        'limit': limit,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFriends({
    String? text,
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get('/users/friends', queryParameters: {
        'text': text,
        'offset': offset,
        'limit': limit,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFriendRequests({
    String? text,
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response =
          await _client.get('/users/friend-requests', queryParameters: {
        'text': text,
        'offset': offset,
        'limit': limit,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    try {
      await _client.post('/users/match', data: {'id': userId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmFriendRequest(String userId, String status) async {
    try {
      await _client.post('/users/match-confirmation',
          queryParameters: {'status': status}, data: {'id': userId});
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadAvatar(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      Response<String> response =
          await _client.post('/files/profile/avatar', data: formData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAvatar() async {
    try {
      await _client.delete('/files/profile/avatar');
    } catch (e) {
      rethrow;
    }
  }
}
