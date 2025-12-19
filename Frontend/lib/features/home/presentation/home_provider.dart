import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user.dart';
import '../data/home_repository.dart';

final homeRepositoryProvider = Provider((ref) => HomeRepository());

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.read(homeRepositoryProvider));
});

enum HomeMode { users, events }

class HomeState {
  final List<User> users;
  final List<Map<String, dynamic>> events;
  final bool isLoading;
  final HomeMode mode;
  final int currentIndex;

  final int usersOffset;
  final int eventsOffset;
  final int pageSize;

  HomeState({
    this.users = const [],
    this.events = const [],
    this.isLoading = true,
    this.mode = HomeMode.users,
    this.currentIndex = 0,
    this.usersOffset = 0,
    this.eventsOffset = 0,
    this.pageSize = 10,
  });

  HomeState copyWith({
    List<User>? users,
    List<Map<String, dynamic>>? events,
    bool? isLoading,
    HomeMode? mode,
    int? currentIndex,
    int? usersOffset,
    int? eventsOffset,
    int? pageSize,
  }) {
    return HomeState(
      users: users ?? this.users,
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      mode: mode ?? this.mode,
      currentIndex: currentIndex ?? this.currentIndex,
      usersOffset: usersOffset ?? this.usersOffset,
      eventsOffset: eventsOffset ?? this.eventsOffset,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;

  HomeNotifier(this._repository) : super(HomeState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final users = await _repository.getUsers(
        offset: 0,
        limit: state.pageSize,
      );
      final events = await _repository.getEvents(
        offset: 0,
        limit: state.pageSize,
      );

      state = state.copyWith(
        users: users,
        events: events,
        isLoading: false,
        currentIndex: 0,
        usersOffset: users.length,
        eventsOffset: events.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setMode(HomeMode mode) {
    state = state.copyWith(
      mode: mode,
      currentIndex: 0, // Сбрасываем индекс при смене режима
    );
  }

  void setCurrentIndex(int index) {
    final maxIndex = state.mode == HomeMode.users
        ? state.users.length - 1
        : state.events.length - 1;
    final safeIndex = index.clamp(0, maxIndex);
    state = state.copyWith(currentIndex: safeIndex);
  }

  void swipeRight() {
    _handleSwipe(true);
  }

  void swipeLeft() {
    _handleSwipe(false);
  }

  void _handleSwipe(bool isLike) {
    final listLength =
        state.mode == HomeMode.users ? state.users.length : state.events.length;

    if (state.currentIndex >= listLength) {
      return;
    }

    // Логика для отправки на сервер (лайк/дизлайк)
    // и локальное удаление просмотренной карточки
    if (state.mode == HomeMode.users) {
      final users = List<User>.from(state.users);
      final user = users[state.currentIndex];
      if (isLike) {
        _repository.matchUser(user.uuid);
      } else {
        _repository.passUser(user.uuid);
      }
      users.removeAt(state.currentIndex);
      final newIndex =
          users.isEmpty ? 0 : state.currentIndex.clamp(0, users.length - 1);
      state = state.copyWith(users: users, currentIndex: newIndex);
    } else {
      final events = List<Map<String, dynamic>>.from(state.events);
      final event = events[state.currentIndex];
      final eventId = event['id'];
      if (isLike) {
        _repository.registerEvent(eventId);
      } else {
        _repository.passEvent(eventId);
      }
      events.removeAt(state.currentIndex);
      final newIndex =
          events.isEmpty ? 0 : state.currentIndex.clamp(0, events.length - 1);
      state = state.copyWith(events: events, currentIndex: newIndex);
    }

    // Если осталось мало карточек, загружаем новые
    final newListLength =
        state.mode == HomeMode.users ? state.users.length : state.events.length;
    final remaining = newListLength - state.currentIndex;
    if (remaining <= 3) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    try {
      if (state.mode == HomeMode.users) {
        final newUsers = await _repository.getUsers(
          offset: state.usersOffset,
          limit: state.pageSize,
        );
        if (newUsers.isNotEmpty) {
          state = state.copyWith(
            users: [...state.users, ...newUsers],
            usersOffset: state.usersOffset + newUsers.length,
          );
        }
      } else {
        final newEvents = await _repository.getEvents(
          offset: state.eventsOffset,
          limit: state.pageSize,
        );
        if (newEvents.isNotEmpty) {
          state = state.copyWith(
            events: [...state.events, ...newEvents],
            eventsOffset: state.eventsOffset + newEvents.length,
          );
        }
      }
    } catch (e) {
      // можно залогировать, но сейчас просто глушим
    }
  }

  // Опционально: метод для сброса до начала
  void resetToStart() {
    state = state.copyWith(currentIndex: 0);
  }
}
