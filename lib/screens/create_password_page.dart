import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // Importem el provider

// Arguments necessaris per a aquesta pàgina
// Ara és una classe simple i immutable
@immutable // Bona pràctica marcar-la com immutable
class CreatePasswordPageArguments {
  final String licenseId;
  final String email;

  // Constructor const amb camps final
  const CreatePasswordPageArguments({
    required this.licenseId,
    required this.email,
  });
}

class CreatePasswordPage extends StatelessWidget {
  const CreatePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenim els arguments de forma segura DINS del mètode build
    final Object? argsRaw = ModalRoute.of(context)?.settings.arguments;

    // Validem si els arguments són del tipus esperat
    if (argsRaw is! CreatePasswordPageArguments) {
      // Si no tenim els arguments correctes, gestionem l'error
      // (potser tornant enrere i mostrant un missatge)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: No s\'han pogut carregar les dades per crear la contrasenya.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      });
      // Retornem un widget temporal mentre es gestiona la navegació/error
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si hem arribat aquí, tenim els arguments correctes
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
              licenseId: args.licenseId,
              email: args.email,
            ),
          );
        },
      ),
    );
  }
}

// --- Formulari per Crear Contrasenya ---
// (Aquest widget no hauria de tenir errors)
class _CreatePasswordForm extends StatefulWidget {
  final String licenseId;
  final String email;

  const _CreatePasswordForm({
    required this.licenseId,
    required this.email,
  }); // Eliminem key

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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // Amaga teclat
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();

      // Passem totes les dades necessàries a completeRegistrationProcess
      await authProvider.completeRegistrationProcess(
        // Només cal la contrasenya aquí, ja que el provider hauria de
        // tenir guardats licenseId i email del pas anterior.
        // Si haguéssim perdut l'estat del provider (poc probable si la navegació és correcta),
        // podríem passar widget.licenseId i widget.email també.
        // Però confiem que el provider manté l'estat entre passos correctes.
        _passwordController.text,
      );

      // Després de cridar, comprovem l'estat del provider (en el 'build')
      // per veure si hi ha error. La navegació en cas d'èxit es gestionarà fora.
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
    // Podríem refinar la condició d'error si cal

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
