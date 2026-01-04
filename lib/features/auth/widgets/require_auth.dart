import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// RequireAuth: reusable widget that ensures a Firebase user is present.
/// If no user is present, redirect to '/login' and clear navigation stack.
class RequireAuth extends StatelessWidget {
  final Widget child;
  const RequireAuth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Només escoltem els canvis d'autenticació, no tots els canvis del provider
    final isAuthenticated = context.select<AuthProvider, bool>(
      (auth) => auth.isAuthenticated,
    );
    final isInitialized = context.select<AuthProvider, bool>(
      (auth) => auth.isInitialized,
    );
    // Logging to help diagnose routing/build decisions during auth transitions.
    debugPrint(
      'RequireAuth.build — isInitialized=$isInitialized isAuthenticated=$isAuthenticated',
    );
    if (!isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        debugPrint('RequireAuth redirecting to /login');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      });
      return const Scaffold();
    }
    debugPrint('RequireAuth allowing child ${child.runtimeType}');
    return child;
  }
}
