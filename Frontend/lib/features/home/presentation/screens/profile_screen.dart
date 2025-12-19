import 'package:connecthub_app/features/auth/presentation/auth_provider.dart';
import 'package:connecthub_app/features/profile/presentation/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    // In loaded state, user should not be null in Protected route
    final user = authState.value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ProfileView(
        user: user,
        isOwnProfile: true,
        friendStatus: 'none',
        onEditProfile: () {
          context.push('/profile/edit');
        },
        onLogout: () {
          authNotifier.logout();
        },
      ),
    );
  }
}
