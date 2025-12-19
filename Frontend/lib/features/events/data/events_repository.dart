import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';

class EventsRepository {
  final Dio _client = ApiClient.instance;

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    try {
      // Map frontend keys to backend keys
      final requestBody = {
        'title': eventData['title'],
        'description': eventData['description'],
        'venue': eventData['location'], // Mapped from location
        'category': eventData['type'], // Mapped from type
        'maxUsersCount': eventData['maxUsersCount'],
        'startDate': eventData['startDate'],
        'endDate': eventData['endDate'],
        'prize': eventData['prize'],
      };

      final response = await _client.post('/events/', data: requestBody);

      // Try to add tags if event ID is returned
      // Swagger says response schema is {}, but usually ID is returned for reference.
      // We check typical patterns: "id" in body or Location header (Dio follows redirects but headers persist)

      String? eventId;
      if (response.data is Map && response.data['id'] != null) {
        eventId = response.data['id'].toString();
      }

      if (eventId != null && eventData['tags'] != null) {
        final tags =
            (eventData['tags'] as List).map((e) => e.toString()).toList();
        if (tags.isNotEmpty) {
          await _client.post('/events/$eventId/tags', data: {'tags': tags});
        }
        if (eventData["imageFile"] != null) {
          await uploadEventImage(eventId, eventData["imageFile"].path);
        }
      }
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateEvent(
      String eventId, Map<String, dynamic> eventData) async {
    try {
      final requestBody = {
        'title': eventData['title'],
        'description': eventData['description'],
        'venue': eventData['venue'],
        'category': eventData['type'],
        'maxUsersCount': eventData['maxUsersCount'],
        'startDate': eventData['startDate'],
        'endDate': eventData['endDate'],
        'status': eventData['status'],
        'prize': eventData['prize'] ?? 0,
      };

      await _client.put('/events/$eventId/edit', data: requestBody);

      // добавляем только новые теги, как строки
      final newTags =
          (eventData['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (newTags.isNotEmpty) {
        await addTagsToEvent(eventId, newTags);
      }

      // удаляем теги по одному id
      final tagsToDelete = (eventData['tagsToDelete'] as List<int>?) ?? [];

      final response = await deleteTagInEvent(eventId, tagsToDelete);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _client.delete('/events/$eventId/remove');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTagsToEvent(String eventId, List<String> tags) async {
    try {
      await _client.post('/events/$eventId/tags', data: {'tags': tags});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteTagInEvent(
      String eventId, List<int> tagList) async {
    try {
      final response = await _client
          .delete('/events/$eventId/tags', data: {"tagIds": tagList});
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addUsersToEvent(String eventId, List<String> userIds) async {
    try {
      await _client.post('/events/$eventId/users', data: {'userIds': userIds});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinEvent(String eventId) async {
    try {
      await _client.post('/events/$eventId/add');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveEvent(String eventId) async {
    try {
      await _client.post('/events/$eventId/leave');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEventInfo(String eventId) async {
    try {
      final response = await _client.get('/events/$eventId/info');
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
          await _client.get('/events/recommendation', queryParameters: {
        'text': text,
        'offset': offset,
        'limit': limit,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> searchEvents({
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
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFriendEvents({
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get('/events/friends', queryParameters: {
        'offset': offset,
        'limit': limit,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadEventImage(String eventId, String filePath) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });
      await _client.post('/files/events/$eventId/image', data: formData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEventImage(String eventId) async {
    try {
      await _client.delete('/files/events/$eventId/image');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserEvents() async {
    final response = await _client.get('/users/events');

    final List<dynamic> rawList = response.data["events"] ?? [];

    return rawList.cast<Map<String, dynamic>>();
  }
}
