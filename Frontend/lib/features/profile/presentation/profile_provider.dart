import 'dart:io';

import 'package:connecthub_app/features/profile/data/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository();
});

final avatarUploadProvider =
    StateNotifierProvider<AvatarUploadNotifier, AvatarUploadState>((ref) {
  return AvatarUploadNotifier(ref.read(profileRepositoryProvider));
});

class AvatarUploadState {
  final bool isLoading;
  final double uploadProgress;
  final String? error;
  final String? uploadedAvatarUrl;
  final File? selectedImage;

  AvatarUploadState({
    this.isLoading = false,
    this.uploadProgress = 0.0,
    this.error,
    this.uploadedAvatarUrl,
    this.selectedImage,
  });

  AvatarUploadState copyWith({
    bool? isLoading,
    double? uploadProgress,
    String? error,
    String? uploadedAvatarUrl,
    File? selectedImage,
  }) {
    return AvatarUploadState(
      isLoading: isLoading ?? this.isLoading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error ?? this.error,
      uploadedAvatarUrl: uploadedAvatarUrl ?? this.uploadedAvatarUrl,
      selectedImage: selectedImage ?? this.selectedImage,
    );
  }
}

class AvatarUploadNotifier extends StateNotifier<AvatarUploadState> {
  final ProfileRepository _repository;
  final ImagePicker _picker = ImagePicker();

  AvatarUploadNotifier(this._repository) : super(AvatarUploadState());

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(
          selectedImage: File(image.path),
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Ошибка выбора изображения: $e',
      );
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        state = state.copyWith(
          selectedImage: File(photo.path),
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Ошибка камеры: $e',
      );
    }
  }

  Future<void> uploadAvatar() async {
    if (state.selectedImage == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final avatarUrl = await _repository.uploadAvatar(
        state.selectedImage!,
      );

      state = state.copyWith(
        isLoading: false,
        uploadedAvatarUrl: avatarUrl,
        selectedImage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки: $e',
      );
      rethrow;
    }
  }

  void reset() {
    state = AvatarUploadState();
  }
}
