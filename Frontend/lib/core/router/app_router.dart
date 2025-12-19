import 'package:connecthub_app/features/auth/presentation/auth_provider.dart';
import 'package:connecthub_app/features/auth/presentation/screens/login_screen.dart';
import 'package:connecthub_app/features/auth/presentation/screens/register_screen.dart';
import 'package:connecthub_app/features/auth/presentation/screens/welcome_screen.dart';
import 'package:connecthub_app/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:connecthub_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:connecthub_app/features/events/presentation/screens/create_event_screen.dart';
import 'package:connecthub_app/features/events/presentation/screens/event_detail_screen.dart';
import 'package:connecthub_app/features/events/presentation/screens/event_edit_screen.dart';
import 'package:connecthub_app/features/events/presentation/screens/events_list_screen.dart';
import 'package:connecthub_app/features/friends/screens/friends_screen.dart';
import 'package:connecthub_app/features/home/presentation/screens/dashboard_screen.dart';
import 'package:connecthub_app/features/home/presentation/screens/home_screen.dart';
import 'package:connecthub_app/features/home/presentation/screens/profile_screen.dart';
import 'package:connecthub_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:connecthub_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:connecthub_app/features/search/presentation/screens/search_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.value != null;
      final isAuthRoute =
          state.uri.path == '/' || state.uri.path.startsWith('/auth');

      if (isLoading) return null; // Or return a splash screen route

      if (!isAuthenticated && !isAuthRoute) {
        return '/'; // Redirect to Welcome if not authenticated and trying to access protected
      }

      if (isAuthenticated && isAuthRoute) {
        return '/home'; // Redirect to Home if authenticated and trying to access Auth screens
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'auth/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'auth/register',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ChatScreen(
                      chatId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const CreateEventScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        EventDetailScreen(eventId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                      path: ':id/edit',
                      builder: (context, state) {
                        final event = state.extra as Map<String, dynamic>;
                        return EventEditScreen(event: event);
                      }),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
    ],
  );
});
