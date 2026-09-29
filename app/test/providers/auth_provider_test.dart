import 'package:flutter_test/flutter_test.dart';
import 'package:chef_ai_app/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    test('estado inicial es unknown', () {
      final provider = AuthProvider();
      expect(provider.status, AuthStatus.unknown);
      expect(provider.currentUser, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });
}
