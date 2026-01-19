import 'package:dio/dio.dart';
import '../utils/api_constants.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    // Interceptor for logging and retry
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        print("API Error: ${error.message}");
        handler.next(error);
      },
    ));
  }

  // Genel GET isteği (Veri çekmek için) - OPTİMİZE
  Future<dynamic> getData(
    String endpoint, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _dio.get(
        endpoint, 
        queryParameters: params,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } on DioException catch (e) {
      print("API Hatası: ${e.type} - ${e.message}");
      return null;
    } catch (e) {
      print("API Hatası: $e");
      return null;
    }
  }

  // POST isteği (Gerekirse)
  Future<dynamic> postData(String endpoint, dynamic data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      print("API Post Hatası: ${e.type} - ${e.message}");
      return null;
    } catch (e) {
      print("API Post Hatası: $e");
      return null;
    }
  }
}
