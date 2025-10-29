import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// Arguments necessaris per a aquesta pàgina
class CreatePasswordPageArguments {
  final String licenseId;
  final String email;
  const CreatePasswordPageArguments({
    required this.licenseId,
    required this.email,
  });
}

class CreatePasswordPage extends StatelessWidget {
  const CreatePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // [CANVI CLAU] Llegim els arguments des de la ruta per al Navigator
    final argsRaw = ModalRoute.of(context)?.settings.arguments;

    if (argsRaw is! CreatePasswordPageArguments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Faltaven dades per crear la contrasenya.'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final CreatePasswordPageArguments args = argsRaw;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalitza el teu Registre'),
        automaticallyImplyLeading: false, // Traiem la fletxa de tornar
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Centrem el formulari
          return Center(
            child: _CreatePasswordForm(
              licenseId: args.licenseId, // Passem la dada rebuda
              email: args.email, // Passem la dada rebuda
            ),
          );
        },
      ),
    );
  }
}

// --- Formulari per Crear Contrasenya ---
class _CreatePasswordForm extends StatefulWidget {
  final String licenseId;
  final String email;

  const _CreatePasswordForm({required this.licenseId, required this.email});

  @override
  State<_CreatePasswordForm> createState() => _CreatePasswordFormState();
}

class _CreatePasswordFormState extends State<_CreatePasswordForm> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Dins de la classe _CreatePasswordFormState

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();

      try {
        // 1. Completem el registre (això crea i loga l'usuari)
        await authProvider.completeRegistrationProcess(
          _passwordController.text,
        );

        // 2. Si l'operació anterior té èxit, naveguem immediatament a la HomePage
        // No cal comprovar firebaseUser, ja que la crida anterior loga l'usuari
        if (mounted) {
          // [CANVI CLAU] Redirecció final a HomePage i neteja de la pila.
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) =>
                false, // Elimina la pila: AuthWrapper, LoginPage, CreatePasswordPage
          );
        }
      } catch (e) {
        // Qualsevol error serà gestionat pel provider (mostrar error a la UI)
        // No fem res aquí, ja que el provider notifica l'error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final bool isCurrentlyLoading =
        authProvider.isLoading &&
        authProvider.currentStep == RegistrationStep.completingRegistration;
    final bool showError =
        authProvider.errorMessage != null &&
        authProvider.currentStep == RegistrationStep.error;

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
                'Crea una contrasenya segura',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Mostrem l'email rebut per arguments
              Text(
                'El teu compte per a ${widget.email} ha estat aprovat.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nova contrasenya',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Mínim 6 caràcters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirma la contrasenya',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma la contrasenya';
                  }
                  if (value != _passwordController.text) {
                    return 'Les contrasenyes no coincideixen';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(), // Permet enviar amb Enter
              ),
              const SizedBox(height: 32),
              if (isCurrentlyLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submit,
                  child: const Text('Crear Compte i Entrar'),
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
