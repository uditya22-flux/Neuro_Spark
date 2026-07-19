import 'package:dio/dio.dart';

/// One authenticated HTTP boundary. Feature repositories own endpoint details.
class ApiClient {
  ApiClient({Dio? dio, required String baseUrl})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }
}
