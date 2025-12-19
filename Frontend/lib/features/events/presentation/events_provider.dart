import 'package:connecthub_app/features/auth/domain/user.dart';
import 'package:connecthub_app/features/auth/presentation/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/events_repository.dart';

final eventsRepositoryProvider = Provider((ref) => EventsRepository());

final eventsProvider =
    StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  // Получаем текущего пользователя
  final user = ref.watch(authProvider).valueOrNull;
  return EventsNotifier(
    ref.read(eventsRepositoryProvider),
    currentUser: user, // Передаем пользователя
  );
});

class EventsState {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> filteredEvents;
  final bool isLoading;
  final String selectedType; // 'all' | 'created' | 'attending' | 'past'
  final String selectedStatus; // 'all' | 'upcoming' | 'ongoing' | 'completed'
  final User? currentUser;

  final Map<String, Map<String, dynamic>>? eventDataCache;

  EventsState({
    this.events = const [],
    this.filteredEvents = const [],
    this.isLoading = false,
    this.selectedType = 'all',
    this.selectedStatus = 'all',
    this.eventDataCache,
    this.currentUser,
  });

  EventsState copyWith({
    List<Map<String, dynamic>>? events,
    List<Map<String, dynamic>>? filteredEvents,
    bool? isLoading,
    String? selectedType,
    String? selectedStatus,
    Map<String, Map<String, dynamic>>? eventDataCache,
    User? currentUser,
  }) {
    return EventsState(
      events: events ?? this.events,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      isLoading: isLoading ?? this.isLoading,
      selectedType: selectedType ?? this.selectedType,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      eventDataCache: eventDataCache ?? this.eventDataCache,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class EventsNotifier extends StateNotifier<EventsState> {
  final EventsRepository _repository;

  EventsNotifier(
    this._repository, {
    User? currentUser,
  }) : super(EventsState(currentUser: currentUser)) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true);
    final events = await _repository.getUserEvents();
    state = state.copyWith(events: events, isLoading: false);
    _applyFilters();
  }

  Future<Map<String, dynamic>> getEventData(String eventId) async {
    try {
      return await _repository.getEventInfo(eventId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _repository.deleteEvent(eventId);
      await loadEvents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinEvent(String eventId) async {
    try {
      await _repository.joinEvent(eventId);
      await loadEvents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveEvent(String eventId) async {
    try {
      await _repository.leaveEvent(eventId);
      await loadEvents();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEventDataWithCache(String eventId) async {
    final cachedData = state.eventDataCache?[eventId];
    if (cachedData != null) {
      return cachedData;
    }

    state = state.copyWith(isLoading: true);
    try {
      final eventData = await _repository.getEventInfo(eventId);

      final updatedCache = {...?state.eventDataCache};
      updatedCache[eventId] = eventData;

      state = state.copyWith(
        isLoading: false,
        eventDataCache: updatedCache,
      );

      return eventData;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEventAndUpdateList(String eventId) async {
    state = state.copyWith(isLoading: true);
    try {
      final eventData = await _repository.getEventInfo(eventId);

      final index = state.events.indexWhere((e) => e['id'] == eventId);
      if (index != -1) {
        final updatedEvents = List<Map<String, dynamic>>.from(state.events);
        updatedEvents[index] = {...updatedEvents[index], ...eventData};
        state = state.copyWith(
          events: updatedEvents,
          isLoading: false,
        );
        _applyFilters();
      } else {
        state = state.copyWith(isLoading: false);
      }

      return eventData;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createEvent(eventData);
      await loadEvents();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateEvent(
      Map<String, dynamic> eventData, String eventId) async {
    state = state.copyWith(isLoading: true);
    try {
      return await _repository.updateEvent(eventId, eventData);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void updateUser(User user) {
    state = state.copyWith(currentUser: user);
    _applyFilters();
  }

  void setFilterType(String type) {
    state = state.copyWith(selectedType: type);
    _applyFilters();
  }

  void setStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = state.events;

    if (state.currentUser != null) {
      final userUuid = state.currentUser!.uuid;

      if (state.selectedType == 'created') {
        filtered = filtered.where((e) {
          final owners = e['owners'] as List<dynamic>? ?? [];
          return owners.any((owner) => owner['uuid'] == userUuid);
        }).toList();
      } else if (state.selectedType == 'attending') {
        filtered = filtered.where((e) {
          final owners = e['owners'] as List<dynamic>? ?? [];
          final isOwner = owners.any((owner) => owner['uuid'] == userUuid);

          if (isOwner) return false;

          final participants = e['participants'] as List<dynamic>? ?? [];
          final isParticipant = participants.any((p) => p['uuid'] == userUuid);

          final isAttending = e['isAttending'] == true;

          final endDate = DateTime.tryParse(e['endDate'] ?? '');
          final isPast = endDate != null && endDate.isBefore(DateTime.now());

          return (isParticipant || isAttending) && !isPast;
        }).toList();
      } else if (state.selectedType == 'past') {
        filtered = filtered.where((e) {
          final endDate = DateTime.tryParse(e['endDate'] ?? '');
          if (endDate == null || !endDate.isBefore(DateTime.now())) {
            return false;
          }

          final userUuid = state.currentUser!.uuid;
          final owners = e['owners'] as List<dynamic>? ?? [];
          final participants = e['participants'] as List<dynamic>? ?? [];

          final isOwner = owners.any((owner) => owner['uuid'] == userUuid);
          final isParticipant = participants.any((p) => p['uuid'] == userUuid);

          return isOwner || isParticipant;
        }).toList();
      }
    }

    // Status filter
    if (state.selectedStatus != 'all') {
      filtered = filtered.where((e) {
        final status = _determineEventStatus(e);
        return status == state.selectedStatus;
      }).toList();
    }

    state = state.copyWith(filteredEvents: filtered);
  }

  String _determineEventStatus(Map<String, dynamic> event) {
    final now = DateTime.now();
    final startDate = DateTime.tryParse(event['startDate'] ?? '');
    final endDate = DateTime.tryParse(event['endDate'] ?? '');

    if (startDate == null || endDate == null) {
      return 'upcoming';
    }

    if (now.isBefore(startDate)) {
      return 'upcoming';
    } else if (now.isAfter(startDate) && now.isBefore(endDate)) {
      return 'ongoing';
    } else if (now.isAfter(endDate)) {
      return 'completed';
    }

    return 'upcoming';
  }
}
