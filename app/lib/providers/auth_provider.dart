import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/auth_storage.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  User? currentUser;
  String? errorMessage;
  bool isLoading = false;

  final _dio = ApiClient.instance.dio;

  AuthProvider() {
    ApiClient.instance.onSessionExpired = () {
      currentUser = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
    };
  }

  Future<void> tryAutoLogin() async {
    final token = await AuthStorage.instance.accessToken;
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final response = await _dio.get('/users/me');
      currentUser = User.fromJson(response.data as Map<String, dynamic>);
      status = AuthStatus.authenticated;
    } catch (_) {
      await AuthStorage.instance.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return _submitAuth(
      () => _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      }),
      rememberMe: true,
    );
  }

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    return _submitAuth(
      () => _dio.post('/auth/login', data: {'email': email, 'password': password}),
      rememberMe: rememberMe,
    );
  }

  Future<bool> _submitAuth(
    Future<dynamic> Function() request, {
    required bool rememberMe,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await request();
      await AuthStorage.instance.saveTokens(
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
        persist: rememberMe,
      );
      final me = await _dio.get('/users/me');
      currentUser = User.fromJson(me.data as Map<String, dynamic>);
      status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> patch) async {
    final response = await _dio.patch('/users/me', data: patch);
    currentUser = User.fromJson(response.data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> logout() async {
    final refreshToken = await AuthStorage.instance.refreshToken;
    if (refreshToken != null) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // best-effort: igual limpiamos la sesión local aunque el backend falle
      }
    }
    await AuthStorage.instance.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    if (error is Exception) {
      final dioError = error;
      try {
        // ignore: avoid_dynamic_calls
        final data = (dioError as dynamic).response?.data;
        if (data is Map && data['message'] != null) {
          final message = data['message'];
          return message is List ? message.join(', ') : message.toString();
        }
      } catch (_) {}
    }
    return 'Ocurrió un error. Probá de nuevo.';
  }
}
