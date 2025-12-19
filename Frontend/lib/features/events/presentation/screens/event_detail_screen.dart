import 'package:connecthub_app/core/theme/app_theme.dart';
import 'package:connecthub_app/core/utils/formaters.dart';
import 'package:connecthub_app/core/widgets/avatar_builder.dart';
import 'package:connecthub_app/core/widgets/primary_button.dart';
import 'package:connecthub_app/features/auth/domain/user.dart';
import 'package:connecthub_app/features/auth/presentation/auth_provider.dart';
import 'package:connecthub_app/features/events/presentation/events_provider.dart';
import 'package:connecthub_app/features/home/presentation/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  Map<String, dynamic>? _cachedEvent;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final eventsNotifier = ref.read(eventsProvider.notifier);
      final event = await eventsNotifier.getEventData(widget.eventId);
      setState(() {
        _cachedEvent = event;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Обрабатываем результат, если экран редактирования был открыт
          final result = ModalRoute.of(context)?.settings.arguments;
          if (result is Map<String, dynamic>) {
            _updateEventData(result);
          }
        }
      },
      child: _buildContent(context),
    );
  }

  void _updateEventData(Map<String, dynamic> updatedEvent) {
    setState(() {
      _cachedEvent = updatedEvent;
    });
    // Также обновляем данные в провайдере
    ref.invalidate(eventsProvider);
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError(context, _error.toString());
    }

    if (_cachedEvent == null) {
      return _buildNotFound(context);
    }

    final event = _cachedEvent!;
    final currentUser = ref.read(authProvider).value;
    final bool isOwner = _checkIfOwner(event, currentUser);
    final bool isParticipant = _checkIfParticipant(event, currentUser);

    return _buildEventDetail(
      context,
      event,
      isOwner: isOwner,
      isParticipant: isParticipant,
    );
  }

  bool _checkIfOwner(Map<String, dynamic> event, User? user) {
    if (user == null) return false;

    final owners = event['owners'] as List<dynamic>? ?? [];
    return owners.any((owner) {
      if (owner is Map<String, dynamic>) {
        return owner['uuid'] == user.uuid;
      }
      return false;
    });
  }

  bool _checkIfParticipant(Map<String, dynamic> event, User? user) {
    if (user == null) return false;

    final participants = event['participants'] as List<dynamic>? ?? [];
    return participants.any((participant) {
      if (participant is Map<String, dynamic>) {
        return participant['uuid'] == user.uuid;
      }
      return false;
    });
  }

  Widget _buildLoading() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Ionicons.alert_circle_outline,
                  size: 60, color: AppColors.error),
              const SizedBox(height: 20),
              const Text(
                'Ошибка загрузки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: PrimaryButton(
                  text: 'Попробовать снова',
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadEvent();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Ionicons.search_outline,
                size: 80, color: AppColors.textTertiary),
            const SizedBox(height: 20),
            const Text(
              'Событие не найдено',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Возможно, оно было удалено',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                text: 'Вернуться назад',
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetail(
    BuildContext context,
    Map<String, dynamic> event, {
    required bool isOwner,
    required bool isParticipant,
  }) {
    final user = ref.read(authProvider).value;
    final eventsNotifier = ref.read(eventsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.white,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Ionicons.arrow_back, color: Colors.black),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: isOwner
                    ? [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Ionicons.ellipsis_vertical,
                                color: Colors.black),
                            onPressed: () {
                              _showOwnerOptions(context, event, eventsNotifier);
                            },
                          ),
                        ),
                      ]
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildEventImage(event),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: _buildEventCategory(event),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _buildEventStatus(event),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок и действие для владельца
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event['title'] ?? 'Без названия',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Информация о участниках/слотах
                      _buildParticipantsInfo(event),

                      const SizedBox(height: 24),

                      // Info Rows
                      _buildDetailRow(
                        Ionicons.calendar_outline,
                        'Дата и время',
                        _formatEventDate(event),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Ionicons.location_outline,
                        'Место проведения',
                        event['venue'] == '' ? 'Онлайн' : event['venue'],
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'О мероприятии',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event['description'] ?? 'Описание отсутствует',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),

                      if (event['prize'] != null &&
                          event['prize'].toString().isNotEmpty &&
                          event['prize'] != '0' &&
                          event['prize'] != 0) ...[
                        const SizedBox(height: 32),
                        _buildPrizeCard(event),
                      ],

                      // Теги
                      if ((event['tags'] as List<dynamic>? ?? [])
                          .isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'Теги',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTags(event),
                      ],

                      const SizedBox(height: 32),

                      const Text(
                        'Участники',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Participants
                      _buildParticipants(event),

                      // Список владельцев (только для владельцев)
                      if ((event['owners'] as List<dynamic>? ?? [])
                          .isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'Организаторы',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildOwners(context, event),
                      ],

                      if (!isOwner)
                        const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Button
          if (!isOwner)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: _buildUserActionButton(
                  context,
                  event,
                  user,
                  isParticipant,
                  eventsNotifier,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserActionButton(
    BuildContext context,
    Map<String, dynamic> event,
    User? user,
    bool isParticipant,
    EventsNotifier eventsNotifier,
  ) {
    if (user == null) {
      return PrimaryButton(
        text: 'Войти для участия',
        onPressed: () {
          context.push('/login');
        },
      );
    }

    if (isParticipant) {
      return PrimaryButton(
        text: 'Вы участвуете',
        isSecondary: true,
        icon: Ionicons.checkmark_circle,
        onPressed: () {
          _showLeaveEventDialog(context, event, eventsNotifier);
        },
      );
    }

    // Проверка на заполненность ивента
    final maxUsers = event['maxUsersCount'] ?? 0;
    final currentParticipants =
        (event['participants'] as List<dynamic>? ?? []).length;

    if (maxUsers > 0 && currentParticipants >= maxUsers) {
      return PrimaryButton(
        text: 'Мест нет',
        isSecondary: true,
        onPressed: () {},
      );
    }

    return PrimaryButton(
      text: 'Участвовать',
      icon: Ionicons.person_add_outline,
      onPressed: () {
        _showJoinEventDialog(context, event, eventsNotifier);
      },
    );
  }

  void _showJoinEventDialog(BuildContext context, Map<String, dynamic> event,
      EventsNotifier eventsNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Участие в мероприятии'),
        content: const Text(
            'Вы уверены, что хотите присоединиться к этому мероприятию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Ваша логика присоединения к ивенту
                await eventsNotifier.joinEvent(event['id']);

                // Обновляем данные
                await _loadEvent();
                // Обновляем рекомендации на главном экране
                ref.read(homeProvider.notifier).loadData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Вы успешно присоединились к мероприятию!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Присоединиться'),
          ),
        ],
      ),
    );
  }

  void _showLeaveEventDialog(BuildContext context, Map<String, dynamic> event,
      EventsNotifier eventsNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отмена участия'),
        content: const Text('Вы уверены, что хотите отменить свое участие?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await eventsNotifier.leaveEvent(event['id']);

                await _loadEvent();
                // Обновляем рекомендации на главном экране
                ref.read(homeProvider.notifier).loadData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Вы вышли из мероприятия'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _showOwnerOptions(BuildContext context, Map<String, dynamic> event,
      EventsNotifier eventsNotifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Ionicons.share_outline, color: AppColors.text),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                _shareEvent(context, event);
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Ionicons.pencil, color: AppColors.electricBlue),
              title: const Text('Редактировать',
                  style: TextStyle(color: AppColors.electricBlue)),
              onTap: () {
                _navigateToEditScreen(context, event);
              },
            ),
            ListTile(
              leading:
                  const Icon(Ionicons.trash_outline, color: AppColors.error),
              title: const Text('Удалить',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, event, eventsNotifier);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditScreen(
      BuildContext context, Map<String, dynamic> event) async {
    Navigator.pop(context); // Закрываем bottom sheet

    // Используем push с ожиданием результата
    final result = await context.push<Map<String, dynamic>>(
      '/events/${event['id']}/edit',
      extra: event,
    );

    if (result != null && result is Map<String, dynamic>) {
      // Обновляем данные с полученным результатом
      _updateEventData(result);
    }
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> event,
      EventsNotifier eventsNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление мероприятия'),
        content: const Text(
            'Вы уверены, что хотите удалить это мероприятие? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await eventsNotifier.deleteEvent(event['id']);

                // Обновляем рекомендации на главном экране
                ref.read(homeProvider.notifier).loadData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Мероприятие удалено'),
                    backgroundColor: AppColors.success,
                  ),
                );

                if (context.mounted) {
                  context.pop();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _shareEvent(BuildContext context, Map<String, dynamic> event) {
    // Реализация шаринга
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция шаринга будет реализована позже')),
    );
  }

  Widget _buildEventImage(Map<String, dynamic> event) {
    final imageUrl = event['imageUrl']?.toString();
    return buildEventImage(imageUrl);
  }

  Widget _buildEventCategory(Map<String, dynamic> event) {
    final category = event['category'] as String? ?? 'Event';
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.electricBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ));
  }

  Widget _buildEventStatus(Map<String, dynamic> event) {
    final status = event['status'] as String? ?? 'PLANNED';
    Color statusColor;
    String statusText;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        statusColor = AppColors.success;
        statusText = 'Завершено';
        break;
      case 'CANCELLED':
        statusColor = AppColors.error;
        statusText = 'Отменено';
        break;
      case 'ACTIVE':
        statusColor = AppColors.neonPink;
        statusText = 'Активно';
        break;
      default:
        statusColor = AppColors.goldYellow;
        statusText = 'Запланировано';
    }

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          border: Border.all(color: statusColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ));
  }

  Widget _buildParticipantsInfo(Map<String, dynamic> event) {
    final maxUsers = event['maxUsersCount'] ?? 0;
    final currentParticipants =
        (event['participants'] as List<dynamic>? ?? []).length;

    if (maxUsers == 0) {
      return Row(
        children: [
          const Icon(Ionicons.people_outline,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$currentParticipants участников',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    final availableSpots = maxUsers - currentParticipants;
    return Row(
      children: [
        const Icon(Ionicons.people_outline,
            size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$currentParticipants/$maxUsers участников',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: availableSpots > 0
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            availableSpots > 0 ? '$availableSpots мест' : 'Мест нет',
            style: TextStyle(
              color: availableSpots > 0 ? AppColors.success : AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrizeCard(Map<String, dynamic> event) {
    final prize = event['prize'].toString();
    final prizeText = prize == '0' ? 'Бесплатно' : prize;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.goldYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldYellow),
      ),
      child: Row(
        children: [
          const Icon(Ionicons.trophy, color: AppColors.goldYellow, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Призовой фонд',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                Text(prizeText,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTags(Map<String, dynamic> event) {
    final tags = event['tags'] as List<dynamic>? ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final tagName =
            tag is Map<String, dynamic> ? tag['name'] : tag.toString();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '#$tagName',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOwners(BuildContext context, Map<String, dynamic> event) {
    final owners = event['owners'] as List<dynamic>? ?? [];
    return Column(
      children: owners.map((owner) {
        final ownerData = owner as Map<String, dynamic>;
        final userName = ownerData['name'].trim();
        final userUuid = ownerData['uuid']?.toString() ?? '';
        final isFriend = ownerData['isFriend'] == true;

          return ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                buildUserAvatar(
                  avatarFileName: ownerData['avatarUrl']?.toString(),
                  displayName: userName,
                  size: 40,
                ),
                if (isFriend)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Ionicons.star,
                        size: 14,
                        color: AppColors.electricBlue,
                      ),
                    ),
                  ),
              ],
            ),
          title: Text(
            userName.isNotEmpty ? userName : 'Без имени',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          subtitle: const Text(
            'Организатор',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          onTap: userUuid.isNotEmpty
              ? () => _navigateToUserProfile(context, userUuid)
              : null,
        );
      }).toList(),
    );
  }

  void _navigateToUserProfile(BuildContext context, String userUuid) {
    context.push('/profile/$userUuid');
  }

  Widget _buildParticipants(Map<String, dynamic> event) {
    final participants = event['participants'] as List<dynamic>? ?? [];

    if (participants.isEmpty) {
      return const Text('Пока никто не участвует в событии');
    }

    return Row(
      children: [
          ...participants.take(3).map((participant) {
            final data = participant as Map<String, dynamic>;
            final user = User.fromJson(data);
            final isFriend = data['isFriend'] == true;
            return GestureDetector(
              onTap: user.uuid.isNotEmpty
                  ? () => _navigateToUserProfile(context, user.uuid)
                  : null,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    buildUserAvatar(
                      avatarFileName: user.avatarUrl,
                      displayName: user.name,
                      size: 50,
                    ),
                    if (isFriend)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Ionicons.star,
                            size: 16,
                            color: AppColors.electricBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
        }).toList(),
        if (participants.length > 3)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundSecondary,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                '+${participants.length - 3}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatEventDate(Map<String, dynamic> event) {
    final startDate = event['startDate'];
    final endDate = event['endDate'];

    if (startDate == null) return 'Дата не указана';

    final startFormatted =
        '${formatDate(startDate, "day") ?? ''} • ${formatDate(startDate, "time") ?? ''}';

    if (endDate == null) return startFormatted;

    final endFormatted =
        '${formatDate(endDate, "day") ?? ''} • ${formatDate(endDate, "time") ?? ''}';

    return '$startFormatted\n - $endFormatted';
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.electricBlue, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
