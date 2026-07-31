import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda los tokens JWT. Si el usuario elige "mantener sesión iniciada", se
/// persisten en almacenamiento seguro (Keychain/Keystore nativos) y sobreviven
/// a un reinicio de la app. Si no, solo quedan en memoria durante la sesión
/// actual y se pierden al cerrar la app (comportamiento típico de "recordarme").
class AuthStorage {
  AuthStorage._();
  static final AuthStorage instance = AuthStorage._();

  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  String? _memoryAccessToken;
  String? _memoryRefreshToken;
  bool _persist = true;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool? persist,
  }) async {
    _memoryAccessToken = accessToken;
    _memoryRefreshToken = refreshToken;
    // si no se especifica (ej. al renovar el token automáticamente), se respeta
    // la preferencia que el usuario eligió en el login original.
    _persist = persist ?? _persist;
    if (_persist) {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } else {
      // por si había una sesión persistida de un login anterior con "recordarme"
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    }
  }

  Future<String?> get accessToken async =>
      _memoryAccessToken ?? await _storage.read(key: _accessTokenKey);

  Future<String?> get refreshToken async =>
      _memoryRefreshToken ?? await _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
