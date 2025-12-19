import 'package:connecthub_app/core/config/environment.dart';
import 'package:dio/dio.dart';

import '../utils/secure_storage.dart';
import 'api_error.dart';
import 'api_exception.dart';

String baseUrl = Environment.apiURL;

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 3000),
      responseType: ResponseType.json,
      // Добавляем заголовки против кеширования на уровне всех запросов
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    ),
  );

  static Dio get instance => _dio;

  static void initialize() {
    // Очищаем все возможные кеши
    _dio.interceptors.clear();

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Добавляем timestamp для уникальности каждого запроса
          final timestamp = DateTime.now().millisecondsSinceEpoch;

          // Обновляем query parameters или создаем новые
          options.queryParameters = {
            ...options.queryParameters,
            '_t': timestamp.toString(), // Антикеш параметр
          };

          // Гарантируем заголовки против кеширования
          options.headers['Cache-Control'] =
              'no-cache, no-store, must-revalidate';
          options.headers['Pragma'] = 'no-cache';
          options.headers['Expires'] = '0';
          options.headers['If-Modified-Since'] =
              'Mon, 26 Jul 1997 05:00:00 GMT';

          // Для POST/PUT/DELETE также отключаем кеши
          if (options.method != 'GET') {
            options.headers['Cache-Control'] = 'no-store';
          }

          final token =
              await SecureStorage.getToken(SecureStorage.keyAccessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Убеждаемся, что ответ не кешируется
          if (response.headers.value('Cache-Control') == null) {
            response.headers.add('Cache-Control', 'no-store');
          }

          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Try to parse the error response if available
          if (error.response?.data != null &&
              error.response?.data is Map<String, dynamic>) {
            final data = error.response!.data as Map<String, dynamic>;
            if (data.containsKey('error')) {
              final errorData = data['error'];
              if (errorData is Map<String, dynamic>) {
                final apiError = ApiError.fromJson(errorData);
                return handler.next(
                  DioException(
                    requestOptions: error.requestOptions,
                    response: error.response,
                    type: DioExceptionType.badResponse,
                    error: ApiException(
                        error: apiError,
                        statusCode: error.response?.statusCode),
                    message: apiError.message,
                  ),
                );
              }
            }
          }

          if (error.response?.statusCode == 401) {
            final refreshToken =
                await SecureStorage.getToken(SecureStorage.keyRefreshToken);
            if (refreshToken != null) {
              try {
                // Создаем отдельный Dio для refresh без interceptor'ов
                final dioRefresh = Dio(
                  BaseOptions(
                    baseUrl: _dio.options.baseUrl,
                    headers: {
                      'Cache-Control': 'no-store', // Отключаем кеш для refresh
                    },
                  ),
                );

                final response = await dioRefresh.post(
                  '/auth/refresh',
                  data: {'token': refreshToken},
                  options: Options(
                    headers: {
                      'Cache-Control': 'no-store',
                    },
                  ),
                );

                final newAccess = response.data['accessToken'];
                final newRefresh = response.data['refreshToken'];

                await SecureStorage.saveTokens(newAccess, newRefresh);

                // Retry original request с новыми заголовками
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccess';
                opts.headers['Cache-Control'] = 'no-store'; // Обновляем

                // Добавляем новый timestamp для повторного запроса
                final newTimestamp = DateTime.now().millisecondsSinceEpoch;
                opts.queryParameters['_t'] = newTimestamp.toString();

                final clonedRequest = await _dio.request(
                  opts.path,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                  ),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(clonedRequest);
              } catch (e) {
                await SecureStorage.clearTokens();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Метод для принудительной очистки всех соединений и кешей
  static Future<void> clearCache() async {
    // Закрываем все соединения
    try {
      _dio.close(force: true);
    } catch (e) {
      // Ignore if already closed
    }

    // Создаем новый инстанс
    // Note: Это радикальный метод, используй только при серьезных проблемах
  }

  // Метод для создания запроса с гарантированным отсутствием кеша
  static Options getNoCacheOptions({String? method}) {
    return Options(
      method: method,
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
        'If-Modified-Since': 'Mon, 26 Jul 1997 05:00:00 GMT',
      },
      extra: {
        'disableCache': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Удобный метод для GET запросов без кеша
  static Future<Response<T>> getNoCache<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final mergedQuery = {
      ...?queryParameters,
      '_t': timestamp.toString(),
    };

    return _dio.get<T>(
      path,
      queryParameters: mergedQuery,
      options: options?.copyWith(
            headers: {
              ...?options?.headers,
              'Cache-Control': 'no-cache',
            },
          ) ??
          getNoCacheOptions(),
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // Удобный метод для POST запросов без кеша
  static Future<Response<T>> postNoCache<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final mergedQuery = {
      ...?queryParameters,
      '_t': timestamp.toString(),
    };

    return _dio.post<T>(
      path,
      data: data,
      queryParameters: mergedQuery,
      options: options?.copyWith(
            headers: {
              ...?options?.headers,
              'Cache-Control': 'no-store',
            },
          ) ??
          Options(
            headers: {'Cache-Control': 'no-store'},
          ),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

// Дополнительный класс для работы с запросами
class NoCacheApi {
  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return ApiClient.getNoCache<T>(
      path,
      queryParameters: query,
    );
  }

  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    return ApiClient.postNoCache<T>(
      path,
      data: data,
      queryParameters: query,
    );
  }
}
