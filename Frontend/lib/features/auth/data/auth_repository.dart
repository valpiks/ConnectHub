import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/secure_storage.dart';
import '../domain/user.dart';

class AuthRepository {
  final Dio _client = ApiClient.instance;

  Future<void> login(String email, String password) async {
    try {
      final response = await _client.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final accessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];

      await SecureStorage.saveTokens(accessToken, refreshToken);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error!;
      }
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      final response = await _client.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });

      final accessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];

      await SecureStorage.saveTokens(accessToken, refreshToken);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error!;
      }
      rethrow;
    }
  }

  Future<User?> getUser() async {
    try {
      final response = await _client
          .get('/users/profile'); // Assuming endpoint based on context
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    final token = await SecureStorage.getToken(SecureStorage.keyRefreshToken);
    if (token != null) {
      try {
        await _client.post('/auth/logout', data: {'token': token});
      } catch (e) {
        // Ignore logout errors
      }
    }
    await SecureStorage.clearTokens();
  }
}
