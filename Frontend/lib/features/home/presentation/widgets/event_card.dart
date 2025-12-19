import 'package:connecthub_app/core/utils/formaters.dart';
import 'package:connecthub_app/core/widgets/avatar_builder.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isCurrent;

  const EventCard({
    super.key,
    required this.event,
    this.isCurrent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Image (60% height to match UserCard proportions)
            Expanded(
              flex: 40,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  buildEventImage(event['imageUrl']?.toString()),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Text(
                        (event['category'] as String? ?? 'Event').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.electricBlue,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.8)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Text(
                      event['title'] ?? 'Без названия',
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              flex: 40,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        Ionicons.calendar_outline,
                        '${formatDate(event['startDate'], "day")} • ${formatDate(event['startDate'], "time")}',
                        AppColors.electricBlue),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                        Ionicons.location_outline,
                        event['venue'] == '' ? 'Онлайн' : event['venue'],
                        AppColors.sunsetOrange),
                    const SizedBox(height: 16),
                    Text(
                      event['description'] ?? '',
                      maxLines: 2, // Increased maxLines
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (event['prize'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.goldYellow.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.goldYellow.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Ionicons.trophy,
                                color: AppColors.goldYellow, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ПРИЗОВОЙ ФОНД',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    event['prize'].toString(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
