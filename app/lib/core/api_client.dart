import 'package:dio/dio.dart';
import 'auth_storage.dart';
import 'constants.dart';

/// Cliente HTTP compartido por toda la app. Agrega el JWT automáticamente y,
/// ante un 401, intenta un refresh silencioso una sola vez antes de reintentar
/// la request original. Si el refresh falla, notifica a [onSessionExpired]
/// (la app navega a Login) y propaga el error.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorage.instance.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isAuthEndpoint = path.startsWith('/auth/');
          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            final refreshed = await _refreshTokens();
            if (refreshed) {
              try {
                final response = await _retry(error.requestOptions);
                return handler.resolve(response);
              } catch (_) {
                // sigue al catch-all de abajo con el error original
              }
            } else {
              onSessionExpired?.call();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  /// Callback que la app registra para reaccionar cuando la sesión expira de verdad
  /// (refresh token también inválido/vencido) — típicamente navega a Login.
  void Function()? onSessionExpired;

  Dio get dio => _dio;

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await AuthStorage.instance.accessToken;
    final options = Options(method: requestOptions.method, headers: {
      ...requestOptions.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    });
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<bool>? _refreshInFlight;

  Future<bool> _refreshTokens() {
    // evita disparar múltiples refresh en paralelo si varias requests fallan a la vez
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await AuthStorage.instance.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: kApiBaseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      await AuthStorage.instance.saveTokens(
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await AuthStorage.instance.clear();
      return false;
    }
  }
}
