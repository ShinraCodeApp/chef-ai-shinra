import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Decide qué pantalla mostrar al arrancar la app según haya o no una sesión
/// válida guardada. Reemplaza a un splash screen tradicional.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return Scaffold(
          backgroundColor: kShinraSplashBg,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icon/app_icon_chosen.png', width: 140, height: 140),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
