import 'package:flutter/material.dart';

import '../../auth/domain/user.dart';
import 'widgets/profile_widgets.dart';

class ProfileView extends StatelessWidget {
  final User user;
  final bool isOwnProfile;
  final String? friendStatus;
  final VoidCallback? onEditAvatar;
  final VoidCallback? onEditProfile;
  final VoidCallback? onLogout;
  final VoidCallback? onConnect;

  const ProfileView({
    super.key,
    required this.user,
    this.isOwnProfile = true,
    this.friendStatus,
    this.onEditAvatar,
    this.onEditProfile,
    this.onLogout,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // На весь экран фон
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA), // Текущий цвет или любой другой
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            children: [
              ProfileHeader(
                avatarUrl: user.avatarUrl,
                name: user.name,
                showEditButton: isOwnProfile,
                onAvatarUpdated: onEditAvatar,
              ),
              ProfileInfo(
                name: user.name,
                tag: user.tag,
                city: user.city,
                specialization: user.specialization,
              ),
              ProfileBio(bio: user.bio),
              ProfileTags(ownTags: user.ownTags, seekingTags: user.seekingTags),
              ProfileActions(
                isOwnProfile: isOwnProfile,
                friendStatus: friendStatus ?? 'none',
                onEdit: onEditProfile,
                onLogout: onLogout,
                onConnect: onConnect,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
