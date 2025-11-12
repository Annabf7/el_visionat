import 'package:el_visionat/screens/create_password_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
            // Before navigating, require the user to provide the activation
            // token and validate it with the backend. This prevents client-
            // side bypass by ensuring the server accepts the token+email pair.
            await _showTokenValidationDialog(licenseId, email);
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

  // Shows a modal dialog to ask the user for the activation token, calls
  // the `validateActivationToken` Cloud Function and navigates only on
  // successful validation.
  Future<void> _showTokenValidationDialog(
    String licenseId,
    String email,
  ) async {
    String token = '';
    bool isLoading = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Introdueix el codi d\'activació'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Revisa el teu correu i introdueix el codi rebut.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Codi',
                      errorText: errorText,
                    ),
                    onChanged: (v) => setState(() => token = v.trim()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel·lar'),
                ),
                ElevatedButton(
                  onPressed: (isLoading || token.isEmpty)
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                            errorText = null;
                          });

                          // Capture navigator instances before the async gap so we
                          // don't use BuildContext after await (avoids analyzer
                          // warning about using context across async gaps).
                          final dialogNavigator = Navigator.of(context);
                          final rootNavigator = Navigator.of(
                            context,
                            rootNavigator: true,
                          );

                          try {
                            final functions = FirebaseFunctions.instance;
                            final callable = functions.httpsCallable(
                              'validateActivationToken',
                            );
                            final res = await callable.call(<String, dynamic>{
                              'email': email,
                              'token': token,
                            });

                            final data = res.data as Map<dynamic, dynamic>?;
                            final success =
                                data != null &&
                                (data['success'] == true || data['ok'] == true);
                            if (success) {
                              // Close dialog and navigate to create-password
                              dialogNavigator.pop();
                              if (!mounted) return;
                              rootNavigator.pushReplacementNamed(
                                '/create-password',
                                arguments: CreatePasswordPageArguments(
                                  licenseId: licenseId,
                                  email: email,
                                ),
                              );
                            } else {
                              setState(() {
                                errorText =
                                    (data != null && data['message'] != null)
                                    ? data['message'].toString()
                                    : 'Codi invàlid';
                                isLoading = false;
                              });
                            }
                          } on FirebaseFunctionsException catch (e) {
                            setState(() {
                              errorText = e.message ?? 'Error del servidor';
                              isLoading = false;
                            });
                          } catch (e) {
                            setState(() {
                              errorText =
                                  'Error de xarxa. Torna-ho a intentar.';
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Validar'),
                ),
              ],
            );
          },
        );
      },
    );
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
              Text(
                'Finalitza l\'enregistrament',
                style: textTheme.headlineMedium,
              ),
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
