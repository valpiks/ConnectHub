// features/friends/screens/friends_screen.dart
import 'package:connecthub_app/core/theme/app_theme.dart';
import 'package:connecthub_app/core/widgets/custom_text_field.dart';
import 'package:connecthub_app/features/friends/domain/friend.dart';
import 'package:connecthub_app/features/friends/friend_provider.dart';
import 'package:connecthub_app/features/friends/widgets/friend_item.dart';
import 'package:connecthub_app/features/friends/widgets/request_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendProvider);
    final notifier = ref.read(friendProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Друзья'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh),
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: _searchController,
              onChanged: (value) {
                notifier.setSearchQuery(value);
                // Поиск сразу при очистке
                if (value.isEmpty) {
                  notifier.refresh();
                }
                // Для непустого значения можно добавить кнопку поиска отдельно
              },
              placeholder: 'Поиск друзей...',
              prefixIcon: Ionicons.search,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Ionicons.close_circle,
                        color: AppColors.electricBlue,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        notifier.setSearchQuery('');
                        notifier.refresh();
                      },
                    ),
                ],
              ),
            ),
          ),

          // Табы
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTab('Мои друзья', 'friends', state.currentTab, notifier),
                const SizedBox(width: 12),
                _buildTab('Запросы', 'requests', state.currentTab, notifier),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Счетчик
          if (state.currentTab == 'friends')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${state.friends.length} друзей',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (state.searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () => notifier.searchFriends(),
                      child: const Text(
                        'Найти',
                        style: TextStyle(
                          color: AppColors.electricBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          if (state.currentTab == 'requests')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${state.friendRequests.length} запросов',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Контент
          Expanded(
            child: _buildContent(state, notifier, context),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    String label,
    String value,
    String currentTab,
    FriendNotifier notifier,
  ) {
    final isActive = value == currentTab;
    return GestureDetector(
      onTap: () => notifier.setTab(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF8E8E93),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      FriendState state, FriendNotifier notifier, BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Ionicons.warning_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка: ${state.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.currentTab == 'friends') {
      if (state.friends.isEmpty) {
        return _buildEmptyState(
          icon: Ionicons.people_outline,
          title: state.searchQuery.isNotEmpty
              ? 'Друзья не найдены'
              : 'У вас пока нет друзей',
          subtitle: state.searchQuery.isNotEmpty
              ? 'Попробуйте изменить запрос'
              : 'Найдите друзей через поиск',
          actionText: state.searchQuery.isNotEmpty ? null : 'Найти друзей',
          onAction: state.searchQuery.isNotEmpty
              ? null
              : () => context.push('/search'),
        );
      }

      return RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: state.friends.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final friend = state.friends[index];
            return FriendItem(
              friend: friend,
              onTap: () => context.push('/profile/${friend.id}'),
              onRemove: () => _showRemoveDialog(context, friend, notifier),
            );
          },
        ),
      );
    } else {
      // Вкладка запросов
      if (state.friendRequests.isEmpty) {
        return _buildEmptyState(
          icon: Ionicons.person_add_outline,
          title: 'Нет запросов в друзья',
          subtitle: 'Когда кто-то отправит вам запрос, он появится здесь',
        );
      }

      return RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: state.friendRequests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final request = state.friendRequests[index];
            return RequestItem(
              request: request,
              onAccept: () => notifier.acceptRequest(request.id),
              onReject: () => notifier.rejectRequest(request.id),
              onTap: () => context.push('/profile/${request.id}'),
            );
          },
        ),
      );
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: const Color(0xFFC7C7CC),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(
    BuildContext context,
    Friend friend,
    FriendNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из друзей?'),
        content:
            Text('Вы уверены, что хотите удалить ${friend.name} из друзей?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Color(0xFF8E8E93)),
            ),
          ),
          TextButton(
            onPressed: () {
              notifier.removeFriend(friend.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
