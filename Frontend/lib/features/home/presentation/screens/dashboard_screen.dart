import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:connecthub_app/core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.electricBlue.withOpacity(0.1),
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Ionicons.home_outline),
              selectedIcon: Icon(Ionicons.home, color: AppColors.electricBlue),
              label: 'Лента',
            ),
            NavigationDestination(
              icon: Icon(Ionicons.search_outline),
              selectedIcon: Icon(Ionicons.search, color: AppColors.electricBlue),
              label: 'Поиск',
            ),
            NavigationDestination(
              icon: Icon(Ionicons.chatbox_outline),
              selectedIcon: Icon(Ionicons.chatbox, color: AppColors.electricBlue),
              label: 'Чат',
            ),
            NavigationDestination(
              icon: Icon(Ionicons.calendar_outline),
              selectedIcon: Icon(Ionicons.calendar, color: AppColors.electricBlue),
              label: 'События',
            ),
            NavigationDestination(
              icon: Icon(Ionicons.person_outline),
              selectedIcon: Icon(Ionicons.person, color: AppColors.electricBlue),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}
