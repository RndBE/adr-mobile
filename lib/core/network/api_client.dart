import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      RetryInterceptor(
        dio: _dio,
        retries: 2,
        retryDelays: const [Duration(seconds: 1), Duration(seconds: 2)],
      ),
      LogInterceptor(requestBody: true, responseBody: false),
    ]);
  }

  static ApiClient get instance => _instance ??= ApiClient._();

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  dynamic unwrap(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  List<dynamic> unwrapList(Response response) {
    final data = unwrap(response);
    return data is List<dynamic> ? data : const [];
  }

  Map<String, dynamic>? unwrapMap(Response response) {
    final data = unwrap(response);
    return data is Map<String, dynamic> ? data : null;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      SecureStorage.clearSession();
    }
    handler.next(err);
  }
}
