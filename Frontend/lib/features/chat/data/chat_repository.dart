import 'package:connecthub_app/core/api/api_client.dart';
import 'package:connecthub_app/features/chat/domain/chat_models.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Репозиторий для работы с HTTP‑эндпоинтами чатов и WebSocket.
///
/// HTTP:
///   GET /api/chats/
///   GET /api/chats/{chat_id}/messages
///
/// WebSocket:
///   ws://<host>/api/chats/ws/{chat_id}?token=<access_token>
class ChatRepository {
  final Dio _client = ApiClient.instance;

  Future<List<ChatThread>> getThreads() async {
    final response = await _client.get('/chats/');
    final List<dynamic> data = response.data as List<dynamic>;

    return data.map((raw) {
      final map = raw as Map<String, dynamic>;
      final companion = map['companion'] as Map<String, dynamic>?;

      return ChatThread(
        id: map['id'].toString(),
        title: companion != null
            ? (companion['name'] as String? ??
                companion['tag'] as String? ??
                'Чат')
            : 'Чат',
        lastMessage: map['lastMessage'] as String?,
        updatedAt: map['lastMessageAt'] != null
            ? DateTime.tryParse(map['lastMessageAt'] as String)
            : null,
        hasUnread: false,
      );
    }).toList();
  }

  Future<List<ChatMessage>> getMessages(String chatId) async {
    final response = await _client.get('/chats/$chatId/messages');
    final List<dynamic> data = response.data as List<dynamic>;

    return data.map((raw) {
      final map = raw as Map<String, dynamic>;
      return ChatMessage(
        id: map['id'].toString(),
        chatId: map['chatId'].toString(),
        text: map['content'] as String? ?? '',
        senderId: map["senderId"],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
      );
    }).toList();
  }

  /// Создаёт WebSocket‑канал для чата.
  WebSocketChannel connectWebSocket(String chatId, String token) {
    final httpUri = Uri.parse(baseUrl);
    final isSecure = httpUri.scheme == 'https';
    final wsScheme = isSecure ? 'wss' : 'ws';

    final wsUri = Uri(
      scheme: wsScheme,
      host: httpUri.host,
      port: httpUri.hasPort ? httpUri.port : null,
      path: '${httpUri.path}/chats/ws/$chatId',
      queryParameters: {'token': token},
    );

    return WebSocketChannel.connect(wsUri);
  }
}
