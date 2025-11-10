import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'utils.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: switch (authProvider.currentStep) {
        RegistrationStep.initial || RegistrationStep.licenseLookup =>
          const RegisterStep1License(key: ValueKey('RegisterStep1')),
        RegistrationStep.licenseVerified ||
        RegistrationStep.requestingRegistration => const RegisterStep2Email(
          key: ValueKey('RegisterStep2'),
        ),
        RegistrationStep.requestSent => const RegisterStep3RequestSent(
          key: ValueKey('RegisterStep3'),
        ),
        RegistrationStep.error => _buildErrorStep(context, authProvider),
        RegistrationStep.approvedNeedPassword => const Center(
          key: ValueKey('ApprovedLoading'),
          child: CircularProgressIndicator(),
        ),
        RegistrationStep.completingRegistration ||
        RegistrationStep.registrationComplete => const Center(
          key: ValueKey('RegisterLoading'),
          child: CircularProgressIndicator(),
        ),
      },
    );
  }

  Widget _buildErrorStep(BuildContext context, AuthProvider authProvider) {
    if (authProvider.verifiedLicenseData != null) {
      return const RegisterStep2Email(key: ValueKey('RegisterStep2_Error'));
    } else {
      return const RegisterStep1License(key: ValueKey('RegisterStep1_Error'));
    }
  }
}

class RegisterStep1License extends StatefulWidget {
  const RegisterStep1License({super.key});

  @override
  State<RegisterStep1License> createState() => _RegisterStep1LicenseState();
}

class _RegisterStep1LicenseState extends State<RegisterStep1License> {
  final _licenseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<AuthProvider>().verifyLicense(
        _licenseController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final bool isCurrentlyLoading =
        authProvider.isLoading &&
        authProvider.currentStep == RegistrationStep.licenseLookup;
    final bool showError =
        authProvider.errorMessage != null &&
        (authProvider.currentStep == RegistrationStep.error &&
            authProvider.verifiedLicenseData == null);

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
                'Ets nou? Verifica la teva llicència',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'Número de Llicència',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Introdueix el número de llicència'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              if (isCurrentlyLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submit,
                  child: const Text('Verificar Llicència'),
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

class RegisterStep2Email extends StatefulWidget {
  const RegisterStep2Email({super.key});

  @override
  State<RegisterStep2Email> createState() => _RegisterStep2EmailState();
}

class _RegisterStep2EmailState extends State<RegisterStep2Email> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<AuthProvider>().submitRegistrationRequest(
        _emailController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final licenseData = authProvider.verifiedLicenseData;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final bool isCurrentlyLoading =
        authProvider.isLoading &&
        authProvider.currentStep == RegistrationStep.requestingRegistration;
    final bool showError =
        authProvider.errorMessage != null &&
        (authProvider.currentStep == RegistrationStep.error &&
            authProvider.verifiedLicenseData != null);

    if (licenseData == null) {
      return const Center(
        key: ValueKey('Step2Loading'),
        child: CircularProgressIndicator(),
      );
    }

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
              Text('Dades Verificades!', style: textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                'Hola ${licenseData['nom'] ?? ''}! Hem confirmat la teva identitat.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              ReadOnlyData(
                label: 'Nom',
                value:
                    '${licenseData['nom'] ?? ''} ${licenseData['cognoms'] ?? ''}',
              ),
              ReadOnlyData(
                label: 'Categoria',
                value: licenseData['categoriaRrtt'] ?? 'N/A',
              ),
              const SizedBox(height: 24),
              Text(
                "Si us plau, introdueix el teu correu electrònic. El teu compte requerirà una verificació manual abans de poder crear la contrasenya.",
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Introdueix el correu electrònic',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Introdueix un correu vàlid'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              if (isCurrentlyLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submit,
                  child: const Text('Enviar correu de verificació'),
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
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: () {
                    if (mounted) {
                      context.read<AuthProvider>().reset();
                    }
                  },
                  child: const Text('Tornar a introduir llicència'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterStep3RequestSent extends StatelessWidget {
  const RegisterStep3RequestSent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final email = authProvider.pendingEmail ?? 'el teu correu';

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 60,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Sol·licitud Enviada!',
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Gràcies, ${authProvider.verifiedLicenseData?['nom'] ?? 'usuari'}! Hem rebut la teva sol·licitud per registrar el compte amb $email.',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Rebràs un correu electrònic un cop la teva sol·licitud hagi estat revisada i aprovada. Llavors podràs accedir a l\'aplicació per crear la teva contrasenya.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                // Keep the outline default but explicitly set the text color to
                // the theme primary so it's visible on all backgrounds.
                foregroundColor: colorScheme.primary,
              ),
              onPressed: () {
                // Capture navigator then navigate to /login clearing the stack.
                final navigator = Navigator.of(context);
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: Text(
                'Iniciar sessió',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
