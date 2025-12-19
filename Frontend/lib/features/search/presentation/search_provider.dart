import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user.dart';
import '../data/search_repository.dart';

final searchRepositoryProvider = Provider((ref) => SearchRepository());

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(searchRepositoryProvider));
});

class SearchState {
  final List<User> users;
  final List<Map<String, dynamic>> events;
  final bool isLoading;
  final String mode; // 'users' | 'events'
  final String query;

  SearchState({
    this.users = const [],
    this.events = const [],
    this.isLoading = false,
    this.mode = 'users',
    this.query = '',
  });

  SearchState copyWith({
    List<User>? users,
    List<Map<String, dynamic>>? events,
    bool? isLoading,
    String? mode,
    String? query,
  }) {
    return SearchState(
      users: users ?? this.users,
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      mode: mode ?? this.mode,
      query: query ?? this.query,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;

  SearchNotifier(this._repository) : super(SearchState());

  Future<void> loadInitialData() async {
    await search('');
  }

  void setMode(String mode) {
    state = state.copyWith(mode: mode);
    search(state.query);
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true);

    try {
      if (state.mode == 'users') {
        final users = await _repository.searchUsers(text: query);
        state = state.copyWith(users: users, isLoading: false);
      } else {
        final events = await _repository.searchEvents(text: query);
        state = state.copyWith(events: events, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}
