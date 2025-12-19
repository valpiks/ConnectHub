import 'package:cached_network_image/cached_network_image.dart';
import 'package:connecthub_app/core/api/api_client.dart';
import 'package:connecthub_app/features/auth/domain/user.dart';
import 'package:connecthub_app/features/profile/presentation/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

class ProfileHeader extends ConsumerWidget {
  final String? avatarUrl;
  final String name;
  final bool showEditButton;
  final VoidCallback? onAvatarUpdated;

  const ProfileHeader({
    super.key,
    this.avatarUrl,
    required this.name,
    this.showEditButton = false,
    this.onAvatarUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUploadState = ref.watch(avatarUploadProvider);
    final avatarUploadNotifier = ref.read(avatarUploadProvider.notifier);

    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF007AFF),
            ),
            child: Container(
              color: const Color(0xFF007AFF).withOpacity(0.7),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Stack(
                children: [
                  _buildAvatarContent(avatarUploadState, avatarUrl, context),
                  if (showEditButton)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _buildEditButton(
                        context,
                        avatarUploadNotifier,
                        avatarUploadState,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(
    AvatarUploadState state,
    String? currentAvatarUrl,
    BuildContext context,
  ) {
    if (state.isLoading) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: const Color(0xFFE3F2FD),
        ),
        child: Center(
          child: CircularProgressIndicator(
            value: state.uploadProgress > 0 ? state.uploadProgress : null,
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }

    if (state.selectedImage != null) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: const Color(0xFFE3F2FD),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.file(
            state.selectedImage!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        color: const Color(0xFFE3F2FD),
      ),
      child: currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: CachedNetworkImage(
                imageUrl: "$baseUrl/files/$currentAvatarUrl",
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (_, __, ___) => _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildEditButton(
    BuildContext context,
    AvatarUploadNotifier notifier,
    AvatarUploadState state,
  ) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF8F9FA), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Ionicons.camera,
          size: 16,
          color: Color(0xFF007AFF),
        ),
      ),
      onSelected: (value) async {
        if (value == 'gallery') {
          await notifier.pickImageFromGallery();
        } else if (value == 'camera') {
          await notifier.takePhoto();
        }

        if (state.selectedImage != null) {
          final shouldUpload = await _showUploadConfirmation(context);
          if (shouldUpload == true) {
            try {
              await notifier.uploadAvatar();
              if (onAvatarUpdated != null) {
                onAvatarUpdated!();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Аватар успешно обновлен!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка загрузки: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            notifier.reset();
          }
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<String>(
            value: 'gallery',
            child: Row(
              children: [
                Icon(Ionicons.images_outline, size: 20),
                SizedBox(width: 8),
                Text('Выбрать из галереи'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'camera',
            child: Row(
              children: [
                Icon(Ionicons.camera_outline, size: 20),
                SizedBox(width: 8),
                Text('Сделать фото'),
              ],
            ),
          ),
        ];
      },
    );
  }

  Future<bool?> _showUploadConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Обновить аватар?'),
          content:
              const Text('Вы уверены, что хотите обновить аватар профиля?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child:
                  const Text('Обновить', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Color(0xFF007AFF),
        ),
      ),
    );
  }
}

class ProfileInfo extends StatelessWidget {
  final String name;
  final String? tag;
  final String? city;
  final String? specialization;

  const ProfileInfo({
    super.key,
    required this.name,
    this.tag,
    this.city,
    this.specialization,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                name,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              if (tag != null)
                Text(
                  '@$tag',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Ionicons.location_outline,
                  city != "" ? city! : 'Город не указан',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(Ionicons.briefcase_outline,
                    specialization != "" ? specialization! : 'Специализация'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF666666)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
        ],
      ),
    );
  }
}

class ProfileBio extends StatelessWidget {
  final String? bio;

  const ProfileBio({super.key, this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Ionicons.person_outline, size: 20, color: Color(0xFF007AFF)),
              SizedBox(width: 8),
              Text('О себе',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              (bio != null && bio!.isNotEmpty)
                  ? bio!
                  : 'Пользователь не рассказал о себе.',
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTags extends StatelessWidget {
  final List<Tag> ownTags;
  final List<Tag> seekingTags;

  const ProfileTags(
      {super.key, required this.ownTags, required this.seekingTags});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSection(
            'Мои навыки',
            Ionicons.checkmark_circle_outline,
            const Color(0xFF007AFF),
            ownTags,
            const Color(0xFF007AFF),
            const Color(0xFFE3F2FD)),
        _buildSection('Ищу', Ionicons.search_outline, const Color(0xFFFF6B35),
            seekingTags, const Color(0xFFFF6B35), const Color(0xFFFFF3E0)),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, Color iconColor,
      List<dynamic> tags, Color textColor, Color bgColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (tags.isEmpty)
            const Text('Не указано',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
          else
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(tag.name,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13)),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileActions extends StatelessWidget {
  final bool isOwnProfile;
  final String friendStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onLogout;
  final VoidCallback? onConnect;

  const ProfileActions({
    super.key,
    required this.isOwnProfile,
    this.friendStatus = 'none',
    this.onEdit,
    this.onLogout,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Ionicons.pencil,
                        size: 18, color: Colors.white),
                    label: const Text('Редактировать',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundBuilder: null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.log_out_outline,
                        size: 20, color: Color(0xFFFF3B30)),
                    SizedBox(width: 8),
                    Text('Выйти',
                        style: TextStyle(
                            color: Color(0xFFFF3B30),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      String label;
      IconData icon;
      bool enabled = true;

      switch (friendStatus) {
        case 'friend':
          label = 'Удалить из друзей';
          icon = Ionicons.person_remove_outline;
          break;
        case 'outgoing':
          label = 'Запрос отправлен';
          icon = Ionicons.time_outline;
          enabled = false;
          break;
        case 'incoming':
          label = 'Принять заявку';
          icon = Ionicons.person_add_outline;
          break;
        default:
          label = 'Добавить в друзья';
          icon = Ionicons.person_add_outline;
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: enabled ? onConnect : null,
                icon: Icon(icon, size: 18, color: Colors.white),
                label: Text(label, style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
