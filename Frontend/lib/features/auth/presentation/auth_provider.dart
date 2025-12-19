import 'dart:io';

import 'package:connecthub_app/core/utils/secure_storage.dart';
import 'package:connecthub_app/features/auth/data/auth_repository.dart';
import 'package:connecthub_app/features/auth/domain/user.dart';
import 'package:connecthub_app/features/profile/data/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());
final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(profileRepositoryProvider),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  AuthNotifier(this._authRepository, this._profileRepository)
      : super(const AsyncValue.loading()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final token = await SecureStorage.getToken(SecureStorage.keyAccessToken);
      if (token != null) {
        final user = await _authRepository.getUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.login(email, password);
      final user = await _authRepository.getUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.register(email, password, name);
      final user = await _authRepository.getUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Separate tags from profile data
      final ownTagsData = data["ownTags"] as List<dynamic>? ?? [];
      final seekingTagsData = data["seekingTags"] as List<dynamic>? ?? [];

      // Extract just the names
      final ownTags = ownTagsData
          .map((e) => e is Map ? e['name'] as String : e.toString())
          .toList();
      final seekingTags = seekingTagsData
          .map((e) => e is Map ? e['name'] as String : e.toString())
          .toList();

      // Clean profile data
      final profileUpdates = Map<String, dynamic>.from(data);
      profileUpdates.remove('ownTags');
      profileUpdates.remove('seekingTags');

      await _profileRepository.updateUser(profileUpdates);

      if (ownTags.isNotEmpty) {
        await _profileRepository.addTags(ownTags, "OWN");
      }
      if (seekingTags.isNotEmpty) {
        await _profileRepository.addTags(seekingTags, "SEEKING");
      }

      return _profileRepository.getMe();
    });
  }

  Future<void> removeTag(int tagId, String type) async {
    await _profileRepository.removeTag(tagId, type);
    // Refresh user data to reflect removal
    final user = await _authRepository.getUser();
    state = AsyncValue.data(user);
  }

  Future<void> uploadAvatar(File file) async {
    await _profileRepository.uploadAvatar(file);
    final user = await _authRepository.getUser();
    state = AsyncValue.data(user);
  }
}
