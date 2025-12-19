import 'package:cached_network_image/cached_network_image.dart';
import 'package:connecthub_app/core/api/api_client.dart';
import 'package:connecthub_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

Widget buildUserAvatar({
  required String? avatarFileName,
  required String displayName,
  double size = 40,
}) {
  final hasImage = avatarFileName != null &&
      avatarFileName.isNotEmpty &&
      avatarFileName != '';

  return SizedBox(
    width: size,
    height: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: '$baseUrl/files/$avatarFileName',
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: AppColors.backgroundSecondary),
              errorWidget: (context, url, error) =>
                  _buildAvatarFallback(displayName, size),
            )
          : _buildAvatarFallback(displayName, size),
    ),
  );
}

Widget _buildAvatarFallback(String name, double size) {
  final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
  return Container(
    color: AppColors.electricBlue,
    child: Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

Widget buildEventImage(String? imageUrl) {
  final hasImage =
      imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null';

  if (!hasImage) {
    return Container(
      color: AppColors.backgroundSecondary,
      child: const Center(
        child: Icon(
          Ionicons.calendar_outline,
          size: 48,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  return CachedNetworkImage(
    imageUrl: '$baseUrl/files/$imageUrl',
    fit: BoxFit.cover,
    placeholder: (context, url) =>
        Container(color: AppColors.backgroundSecondary),
    errorWidget: (context, url, error) =>
        Container(color: AppColors.backgroundSecondary),
  );
}
