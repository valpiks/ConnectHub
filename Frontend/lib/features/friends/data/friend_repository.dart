import 'package:connecthub_app/core/api/api_client.dart';
import 'package:connecthub_app/features/friends/domain/friend.dart';
import 'package:dio/dio.dart';

class FriendRepository {
  final Dio _apiClient = ApiClient.instance;

  Future<List<Friend>> getFriends({String? text}) async {
    try {
      final response = await _apiClient.get(
        '/users/friends',
        queryParameters: {
          if (text != null && text.isNotEmpty) 'text': text,
        },
      );
      final data = (response.data['friends'] ??
              response.data['friendsList'] ??
              []) as List<dynamic>;
      return data
          .map((item) => Friend.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load friends: $e');
    }
  }

  Future<List<Friend>> getFriendRequests({String? text}) async {
    try {
      final response = await _apiClient.get(
        '/users/friend-requests',
        queryParameters: {
          if (text != null && text.isNotEmpty) 'text': text,
        },
      );
      final List<dynamic> data = response.data['requests'] ?? [];
      return data
          .map((item) => Friend.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load friend requests: $e');
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    try {
      await _apiClient.post('/users/match', data: {
        'id': userId,
      });
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _apiClient.post('/users/match-confirmation?status=ACCEPTED', data: {
        'id': requestId,
      });
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _apiClient.post('/users/match-confirmation?status=REJECT', data: {
        'id': requestId,
      });
    } catch (e) {
      throw Exception('Failed to reject friend request: $e');
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await _apiClient.post('/users/friends/remove', data: {"id": friendId});
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }
}
