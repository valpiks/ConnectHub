import 'package:connecthub_app/core/theme/app_theme.dart';
import 'package:connecthub_app/features/events/presentation/widgets/events_filter_bar.dart';
import 'package:connecthub_app/features/home/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../events_provider.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventsProvider);
    final notifier = ref.read(eventsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мероприятия',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          EventsFilterBar(
            selectedType: state.selectedType,
            onTypeChange: notifier.setFilterType,
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredEvents.isEmpty
                    ? const Center(child: Text('Нет мероприятий'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.filteredEvents.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () => context.push(
                                  '/events/${state.filteredEvents[index]['id']}'),
                              child: SizedBox(
                                height: 440,
                                child: EventCard(
                                  event: state.filteredEvents[index],
                                  isCurrent: false,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/events/new'),
        backgroundColor: AppColors.electricBlue,
        child: const Icon(Ionicons.add, color: Colors.white),
      ),
    );
  }
}
