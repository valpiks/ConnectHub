import 'package:connecthub_app/features/auth/domain/user.dart';
import 'package:connecthub_app/features/auth/presentation/auth_provider.dart';
import 'package:connecthub_app/features/friends/friend_provider.dart'; // <-- добавить
import 'package:connecthub_app/features/profile/data/profile_repository.dart';
import 'package:connecthub_app/features/profile/presentation/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final userProfileProvider =
    FutureProvider.family<User?, String>((ref, userId) async {
  return ref.read(profileRepositoryProvider).getUserById(userId);
});

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userAsync = ref.watch(userProfileProvider(userId));
    final friendsState = ref.watch(friendProvider);
    final friendsNotifier = ref.read(friendProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      extendBodyBehindAppBar: true,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Пользователь не найден'),
            );
          }

          final isOwnProfile = userId == authState.value?.uuid;

          final isFriend =
              friendsState.friends.any((f) => f.user.uuid == userId);
          final hasIncoming = friendsState.friendRequests.any(
            (f) => f.user.uuid == userId && f.isIncoming,
          );
          final hasOutgoing = friendsState.friendRequests.any(
            (f) => f.user.uuid == userId && !f.isIncoming,
          );

          String friendStatus = 'none';
          if (isFriend) {
            friendStatus = 'friend';
          } else if (hasOutgoing) {
            friendStatus = 'outgoing';
          } else if (hasIncoming) {
            friendStatus = 'incoming';
          }

          return ProfileView(
            user: user,
            isOwnProfile: isOwnProfile,
            friendStatus: friendStatus,
            onConnect: () {
              if (isOwnProfile) return;

              if (isFriend) {
                // Удалить из друзей
                friendsNotifier.removeFriend(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Пользователь удалён из друзей'),
                  ),
                );
              } else if (hasOutgoing) {
                // Уже отправляли заявку
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Запрос уже отправлен'),
                  ),
                );
              } else if (hasIncoming) {
                // Принимать входящую заявку (упрощённо, без “отклонить”)
                friendsNotifier.acceptRequest(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заявка принята'),
                  ),
                );
              } else {
                // Новая заявка
                friendsNotifier.sendFriendRequest(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Запрос в друзья отправлен'),
                  ),
                );
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }
}
