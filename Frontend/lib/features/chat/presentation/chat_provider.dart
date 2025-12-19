import 'dart:async';
import 'dart:convert';

import 'package:connecthub_app/core/utils/secure_storage.dart';
import 'package:connecthub_app/features/auth/presentation/auth_provider.dart';
import 'package:connecthub_app/features/chat/data/chat_repository.dart';
import 'package:connecthub_app/features/chat/domain/chat_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository());

class ChatListState {
  final List<ChatThread> threads;
  final bool isLoading;
  final String? error;

  ChatListState({
    this.threads = const [],
    this.isLoading = false,
    this.error,
  });

  ChatListState copyWith({
    List<ChatThread>? threads,
    bool? isLoading,
    String? error,
  }) {
    return ChatListState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  return ChatListNotifier(ref.read(chatRepositoryProvider));
});

class ChatListNotifier extends StateNotifier<ChatListState> {
  final ChatRepository _repository;

  ChatListNotifier(this._repository) : super(ChatListState()) {
    loadThreads();
  }

  Future<void> loadThreads() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final threads = await _repository.getThreads();
      state = state.copyWith(threads: threads, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class ChatState {
  final String chatId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.chatId,
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      chatId: chatId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>((ref, id) {
  final repo = ref.read(chatRepositoryProvider);
  final currentUser = ref.read(authProvider).value;
  return ChatNotifier(
    id,
    repo,
    currentUserId: currentUser?.uuid,
  );
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final String? _currentUserId;

  StreamSubscription? _socketSub;

  ChatNotifier(
    String chatId,
    this._repository, {
    String? currentUserId,
  })  : _currentUserId = currentUserId,
        super(ChatState(chatId: chatId)) {
    loadMessages();
    _connectSocket();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _repository.getMessages(state.chatId);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _connectSocket() async {
    try {
      final token = await SecureStorage.getToken(SecureStorage.keyAccessToken);
      if (token == null) return;

      final channel = _repository.connectWebSocket(state.chatId, token);

      _socketSub = channel.stream.listen((event) {
        try {
          final data = jsonDecode(event as String) as Map<String, dynamic>;

          final msg = ChatMessage(
            id: data['id'].toString(),
            chatId: data['chatId'].toString(),
            text: data['content'] as String? ?? '',
            senderId: data["senderId"],
            createdAt: data['createdAt'] != null
                ? DateTime.parse(data['createdAt'] as String)
                : DateTime.now(),
          );

          state = state.copyWith(
            messages: [...state.messages, msg],
          );
        } catch (_) {
          // ignore malformed message
        }
      });
    } catch (_) {
      // можно залогировать
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      final token = await SecureStorage.getToken(SecureStorage.keyAccessToken);
      if (token == null) return;

      final channel = _repository.connectWebSocket(state.chatId, token);
      channel.sink.add(jsonEncode({'content': trimmed}));
      await channel.sink.close();
    } catch (_) {
      // в проде можно откатить optimistic, если нужно
    }
  }
}
