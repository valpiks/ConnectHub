import 'package:connecthub_app/core/theme/app_theme.dart';
import 'package:connecthub_app/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../search_provider.dart';
import '../widgets/search_result_item.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Загружаем начальные данные при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(searchProvider.notifier);
      notifier.loadInitialData(); // Загружаем без query
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    // Синхронизируем состояние поиска с контроллером
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchController.text != state.query) {
        _searchController.text = state.query;
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomTextField(
                controller: _searchController,
                onChanged: (value) => notifier.search(value),
                placeholder: 'Поиск...',
                prefixIcon: Ionicons.search,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Ionicons.close_circle,
                          color: AppColors.electricBlue,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          notifier.search('');
                        },
                      )
                    : null,
              ),
            ),

            // Mode Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTab('Люди', 'users', state.mode, notifier),
                  const SizedBox(width: 12),
                  _buildTab('Мероприятия', 'events', state.mode, notifier),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Results Counter
            if (state.query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      state.mode == 'users'
                          ? 'Найдено ${state.users.length} человек'
                          : 'Найдено ${state.events.length} мероприятий',
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: _buildContent(state, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    String label,
    String value,
    String currentMode,
    SearchNotifier notifier,
  ) {
    final isActive = value == currentMode;
    return GestureDetector(
      onTap: () => notifier.setMode(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF8E8E93),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(SearchState state, BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Если строка поиска пустая - показываем начальные данные
    if (state.query.isEmpty) {
      return _buildInitialContent(state, context);
    }

    // Если есть поиск - показываем результаты
    if (state.mode == 'users') {
      if (state.users.isEmpty) {
        return _buildEmptyState(
          icon: Ionicons.people_outline,
          title: 'Пользователи не найдены',
          subtitle: 'Попробуйте изменить запрос',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.users.length,
        itemBuilder: (context, index) {
          final user = state.users[index];
          return SearchResultItem(
            item: user.toJson(),
            mode: 'users',
            onPress: (id) => context.push('/profile/$id'),
          );
        },
      );
    } else {
      if (state.events.isEmpty) {
        return _buildEmptyState(
          icon: Ionicons.calendar_outline,
          title: 'Мероприятия не найдены',
          subtitle: 'Попробуйте изменить запрос',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.events.length,
        itemBuilder: (context, index) {
          final event = state.events[index];
          return SearchResultItem(
            item: event,
            mode: 'events',
            onPress: (id) => context.push('/events/$id'),
          );
        },
      );
    }
  }

  Widget _buildInitialContent(SearchState state, BuildContext context) {
    // Используем существующие users/events из состояния (которые уже загружены)
    final hasUsers = state.users.isNotEmpty;
    final hasEvents = state.events.isNotEmpty;

    // Если нет данных вообще
    if (!hasUsers && !hasEvents) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.search_outline,
              size: 64,
              color: Color(0xFFC7C7CC),
            ),
            SizedBox(height: 16),
            Text(
              'Начните вводить запрос',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Показываем начальные данные
    if (state.mode == 'users' && hasUsers) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.users.length,
        itemBuilder: (context, index) {
          final user = state.users[index];
          return SearchResultItem(
            item: user.toJson(),
            mode: 'users',
            onPress: (id) => context.push('/profile/$id'),
          );
        },
      );
    } else if (state.mode == 'events' && hasEvents) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.events.length,
        itemBuilder: (context, index) {
          final event = state.events[index];
          return SearchResultItem(
            item: event,
            mode: 'events',
            onPress: (id) => context.push('/events/$id'),
          );
        },
      );
    }

    // Если в текущем режиме нет данных
    return _buildEmptyState(
      icon: state.mode == 'users'
          ? Ionicons.people_outline
          : Ionicons.calendar_outline,
      title: state.mode == 'users' ? 'Нет пользователей' : 'Нет мероприятий',
      subtitle: 'Попробуйте переключить режим поиска',
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFFC7C7CC),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
