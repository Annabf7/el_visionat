import 'package:el_visionat/screens/create_password_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result == RegistrationStep.approvedNeedPassword) {
        if (mounted) {
          final licenseId = authProvider.pendingLicenseId;
          final email = authProvider.pendingEmail;
          if (licenseId != null && email != null) {
            Navigator.of(context).pushReplacementNamed(
              '/create-password',
              arguments: CreatePasswordPageArguments(
                licenseId: licenseId,
                email: email,
              ),
            );
          }
        }
      }
      // If login succeeded, navigate to Home and clear stack so we don't
      // leave the user stuck on the login/profile view.
      if (authProvider.isAuthenticated) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firebaseUserPresent = authProvider.isAuthenticated;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // IMPORTANT: Do not render Profile UI inside the login view. If the user
    // is already authenticated and somehow reached this widget, redirect to
    // /home and show a small loading indicator while navigating.
    if (firebaseUserPresent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      });
      return const Center(child: CircularProgressIndicator());
    }

    final bool showError =
        authProvider.errorMessage != null &&
        authProvider.currentStep == RegistrationStep.initial;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ja tens compte?', style: textTheme.headlineMedium),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Introdueix un correu vàlid'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contrasenya'),
                obscureText: true,
                validator: (value) => (value == null || value.length < 6)
                    ? 'Mínim 6 caràcters'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    /* TODO: Implementar recuperació contrasenya */
                  },
                  child: const Text('He oblidat la meva contrasenya'),
                ),
              ),
              const SizedBox(height: 16),
              if (authProvider.isLoading &&
                  authProvider.currentStep == RegistrationStep.initial)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submit,
                  child: const Text('Iniciar sessió'),
                ),
              if (showError)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    authProvider.errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
