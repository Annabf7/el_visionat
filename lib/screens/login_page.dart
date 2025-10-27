import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // The AuthProvider state is now reset from the navigation source.

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return const _LoginPageMobile();
          } else {
            return const _LoginPageDesktop();
          }
        },
      ),
    );
  }
}

// --- Mobile Layout (Tabs) ---
class _LoginPageMobile extends StatelessWidget {
  const _LoginPageMobile();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0, // We only want the bottom part of the AppBar
          bottom: TabBar(
            tabs: const [
              Tab(text: 'INICIAR SESSIÓ'),
              Tab(text: 'REGISTRAR-SE'),
            ],
            labelStyle: Theme.of(context).textTheme.labelLarge,
            unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        body: const TabBarView(
          children: [
            _LoginView(),
            _RegisterView(),
          ],
        ),
      ),
    );
  }
}

// --- Desktop Layout (Side-by-side) ---
class _LoginPageDesktop extends StatelessWidget {
  const _LoginPageDesktop();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Center(child: _LoginView()),
        ),
        VerticalDivider(width: 1),
        Expanded(
          child: Center(child: _RegisterView()),
        ),
      ],
    );
  }
}

// --- Reusable Login Form ---
class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
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
    if (_formKey.currentState?.validate() ?? false) {
      final success = await context.read<AuthProvider>().signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (!success && mounted) {
        // Error message is already handled by the provider's listener
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // We only want to show login-related errors here.
    // The registration flow has its own error display area.
    final showError = authProvider.errorMessage != null && !authProvider.isLicenseVerified;

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
              Text('Iniciar Sessió', style: textTheme.displayMedium),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correu Electrònic'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Introdueix un correu vàlid' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contrasenya'),
                obscureText: true,
                validator: (value) => (value == null || value.length < 6) ? 'La contrasenya ha de tenir almenys 6 caràcters' : null,
              ),
              const SizedBox(height: 24),
              if (authProvider.isLoading && !authProvider.isLicenseVerified)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('ENTRAR'),
                ),
              if (showError)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    authProvider.errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
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

// --- Reusable Register Flow Container ---
class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // The PopScope was removed. The logic to reset the state is now
    // handled by a TabController listener in the _LoginPageMobile widget.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: authProvider.isLicenseVerified
          ? _RegisterStep2(key: const ValueKey('RegisterStep2'))
          : _RegisterStep1(key: const ValueKey('RegisterStep1')),
    );
  }
}

// --- Register Step 1: Verify License ---
class _RegisterStep1 extends StatefulWidget {
  const _RegisterStep1({super.key});

  @override
  State<_RegisterStep1> createState() => _RegisterStep1State();
}

class _RegisterStep1State extends State<_RegisterStep1> {
  final _licenseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<AuthProvider>().verifyLicense(_licenseController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
              Text('Registrar-se', style: textTheme.displayMedium),
              const SizedBox(height: 8),
              Text('Pas 1: Verificació de la llicència', style: textTheme.bodyLarge),
              const SizedBox(height: 24),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(labelText: 'Número de Llicència'),
                validator: (value) => (value == null || value.isEmpty) ? 'Introdueix el número de llicència' : null,
              ),
              const SizedBox(height: 24),
              if (authProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('VERIFICAR LLICÈNCIA'),
                ),
              if (authProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    authProvider.errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
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

// --- Register Step 2: Email Verification ---
class _RegisterStep2 extends StatefulWidget {
  const _RegisterStep2({super.key});

  @override
  State<_RegisterStep2> createState() => _RegisterStep2State();
}

class _RegisterStep2State extends State<_RegisterStep2> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // This will be implemented in the next task.
      // context.read<AuthProvider>().requestEmailVerification(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funció "requestEmailVerification" no implementada encara.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userData = authProvider.verifiedUserData;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (userData == null) {
      // This is a fallback. Should not be reached if logic is correct.
      // It will show a loading or an empty container while transitioning.
      return const Center(child: CircularProgressIndicator());
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
              Text('Verificació del correu', style: textTheme.displayMedium),
              const SizedBox(height: 8),
              Text('Pas 2 de 2', style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: 24),
              _buildUserInfoTile('Nom', userData['nom'] ?? '', context),
              _buildUserInfoTile('Cognoms', userData['cognoms'] ?? '', context),
              _buildUserInfoTile('Delegació', userData['delegacio'] ?? '', context),
              const SizedBox(height: 24),
              Text(
                "Introdueix el teu correu electrònic per a crear el compte. T'enviarem un enllaç de verificació.",
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correu Electrònic'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Introdueix un correu vàlid' : null,
              ),
              const SizedBox(height: 24),
              if (authProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('ENVIAR CORREU DE VERIFICACIÓ'),
                ),
              if (authProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    authProvider.errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoTile(String label, String value, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
