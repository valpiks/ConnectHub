// features/friends/provider/friend_provider.dart
import 'package:connecthub_app/features/friends/data/friend_repository.dart';
import 'package:connecthub_app/features/friends/domain/friend.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final friendRepositoryProvider = Provider((ref) => FriendRepository());

class FriendState {
  final List<Friend> friends;
  final List<Friend> friendRequests;
  final bool isLoading;
  final String? error;
  final String currentTab; // 'friends' или 'requests'
  final String searchQuery;

  FriendState({
    this.friends = const [],
    this.friendRequests = const [],
    this.isLoading = false,
    this.error,
    this.currentTab = 'friends',
    this.searchQuery = '',
  });

  FriendState copyWith({
    List<Friend>? friends,
    List<Friend>? friendRequests,
    bool? isLoading,
    String? error,
    String? currentTab,
    String? searchQuery,
  }) {
    return FriendState(
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final friendProvider =
    StateNotifierProvider<FriendNotifier, FriendState>((ref) {
  return FriendNotifier(ref.read(friendRepositoryProvider));
});

class FriendNotifier extends StateNotifier<FriendState> {
  final FriendRepository _repository;

  FriendNotifier(this._repository) : super(FriendState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final [friends, requests] = await Future.wait([
        _repository.getFriends(),
        _repository.getFriendRequests(),
      ]);

      state = state.copyWith(
        friends: friends,
        friendRequests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setTab(String tab) {
    if (tab != state.currentTab) {
      state = state.copyWith(currentTab: tab);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refresh() async {
    await loadInitialData();
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _repository.acceptFriendRequest(requestId);
      await loadInitialData(); // Перезагружаем данные
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _repository.rejectFriendRequest(requestId);
      await loadInitialData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await _repository.removeFriend(friendId);
      await loadInitialData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    try {
      await _repository.sendFriendRequest(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> searchFriends() async {
    if (state.searchQuery.isEmpty) {
      await loadInitialData();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getFriends(text: state.searchQuery),
        _repository.getFriendRequests(text: state.searchQuery),
      ]);
      final friends = results[0] as List<Friend>;
      final requests = results[1] as List<Friend>;

      state = state.copyWith(
        friends: friends,
        friendRequests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
