// features/friends/widgets/request_item.dart
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../domain/friend.dart';

class RequestItem extends StatelessWidget {
  final Friend request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const RequestItem({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Аватар
            GestureDetector(
              onTap: onTap,
              child: CircleAvatar(
                radius: 24,
                backgroundImage: request.avatarUrl != null
                    ? NetworkImage(request.avatarUrl!)
                    : const AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
              ),
            ),
            const SizedBox(width: 16),

            // Информация
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (request.tag != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        request.tag!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      request.isIncoming
                          ? 'Хочет добавить вас в друзья'
                          : 'Отправлен запрос',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Кнопки действий
            if (request.isIncoming) ...[
              IconButton(
                icon: const Icon(
                  Ionicons.checkmark,
                  color: Colors.green,
                  size: 24,
                ),
                onPressed: onAccept,
              ),
              IconButton(
                icon: const Icon(
                  Ionicons.close,
                  color: Colors.red,
                  size: 24,
                ),
                onPressed: onReject,
              ),
            ] else ...[
              Chip(
                label: const Text('Ожидание'),
                backgroundColor: const Color(0xFFF2F2F7),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
