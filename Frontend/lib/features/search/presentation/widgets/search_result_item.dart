import 'package:connecthub_app/core/theme/app_theme.dart';
import 'package:connecthub_app/core/widgets/avatar_builder.dart';
import 'package:connecthub_app/features/auth/domain/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:ionicons/ionicons.dart';

class SearchResultItem extends StatelessWidget {
  final dynamic item; // User или Map<String, dynamic>
  final String mode; // 'users' или 'events'
  final Function(String) onPress;

  const SearchResultItem({
    super.key,
    required this.item,
    required this.mode,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    try {
      if (mode == 'users') {
        return _buildUserCard();
      } else {
        return _buildEventCard();
      }
    } catch (e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        color: Colors.red[100],
        child: Text('Ошибка: $e'),
      );
    }
  }

  Widget _buildUserCard() {
    final User user;
    if (item is User) {
      user = item as User;
    } else if (item is Map<String, dynamic>) {
      user = User.fromJson(item as Map<String, dynamic>);
    } else {
      throw Exception('Неподдерживаемый тип данных для пользователя');
    }

    return GestureDetector(
      onTap: () => onPress(user.uuid),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: SizedBox(
                width: 60,
                height: 60,
                child: buildUserAvatar(
                  avatarFileName: user.avatarUrl,
                  displayName: user.name,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.tag != '' ? '@${user.tag}' : '@Tag',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  if (user.city != null && user.city!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Ionicons.location,
                            size: 14, color: Color(0xFF666666)),
                        const SizedBox(width: 4),
                        Text(
                          user.city!,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard() {
    final Map<String, dynamic> event;
    if (item is Map<String, dynamic>) {
      event = item as Map<String, dynamic>;
    } else {
      throw Exception('Неподдерживаемый тип данных для события');
    }

    final title = event['title']?.toString() ?? 'Без названия';
    final imageUrl = event['imageUrl']?.toString();
    final startDate = event['startDate']?.toString();
    final venue = event['venue']?.toString() ?? 'Не указано';
    final id = event['id']?.toString() ?? '';

    // Форматирование даты
    String formattedDate = 'Не указано';
    if (startDate != null && startDate.isNotEmpty) {
      try {
        final date = DateTime.tryParse(startDate);
        if (date != null) {
          formattedDate = DateFormat('dd.MM.yyyy').format(date);
        }
      } catch (e) {
        formattedDate = startDate;
      }
    }

    return GestureDetector(
      onTap: () => onPress(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: buildEventImage(imageUrl),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Ionicons.calendar,
                          size: 14, color: Color(0xFF666666)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formattedDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF666666)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Ionicons.location,
                          size: 14, color: Color(0xFF666666)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF666666)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      color: AppColors.electricBlue,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEventPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Ionicons.calendar_outline,
          size: 32,
          color: Colors.grey,
        ),
      ),
    );
  }
}
