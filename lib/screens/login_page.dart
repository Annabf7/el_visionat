import 'package:el_visionat/screens/create_password_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // Importem el provider actualitzat

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Nota: El reset del provider es fa des d'on es navega cap aquí (ex: side_navigation_menu)
    // o quan es tanca sessió.

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            // Passem el AuthProvider per poder afegir el listener al TabController
            return _LoginPageMobile(authProvider: context.read<AuthProvider>());
          } else {
            return const _LoginPageDesktop();
          }
        },
      ),
    );
  }
}

// --- Mobile Layout (Tabs) ---
class _LoginPageMobile extends StatefulWidget {
  final AuthProvider authProvider;
  const _LoginPageMobile({required this.authProvider});

  @override
  State<_LoginPageMobile> createState() => _LoginPageMobileState();
}

class _LoginPageMobileState extends State<_LoginPageMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    // Si l'usuari canvia de pestanya DES DE la de registre CAP A la de login,
    // fem un reset de l'estat del flux de registre.
    if (!_tabController.indexIsChanging &&
        _tabController.previousIndex == 1 &&
        _tabController.index == 0) {
      // Comprovem si encara existeix el widget abans de cridar mètodes del provider
      if (mounted) {
        widget.authProvider.reset();
        debugPrint("AuthProvider reset due to tab change.");
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenim l'usuari de Firebase des del provider.
    // La directiva `watch` fa que el widget es reconstrueixi si l'estat de l'usuari canvia.
    final firebaseUser = context.watch<User?>();

    // Si l'usuari ha iniciat sessió (no és null), mostrem una vista simple de perfil sense pestanyes.
    // La vista _LoginView ara gestiona internament si mostrar el perfil o el formulari de login.
    if (firebaseUser != null) {
      return Scaffold(
        appBar: AppBar(
          // Canviem el títol per reflectir que és la pàgina de perfil.
          title: const Text("El meu Perfil / Configuració"),
        ),
        body: const Center(child: _LoginView()),
      );
    }

    // Si l'usuari NO ha iniciat sessió, mantenim el disseny de pestanyes
    // per permetre iniciar sessió o registrar-se.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accés / Registre"), // Títol més descriptiu
        toolbarHeight: kToolbarHeight, // Restaurem l'alçada per al títol
        bottom: TabBar(
          controller: _tabController, // Important assignar el controlador
          tabs: const [
            Tab(text: 'INICIAR SESSIÓ'),
            Tab(text: 'REGISTRAR-SE'),
          ],
          labelStyle: Theme.of(context).textTheme.labelLarge,
          unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Important assignar el controlador
        // Avoid wrapping the step views in Center: those children already
        // provide their own scrolling and sizing. Wrapping in Center can
        // interfere with how they react to the keyboard and lead to
        // "Bottom overflowed" errors on small devices.
        children: const [
          _LoginView(), // Aquesta vista mostrarà el formulari de login
          _RegisterView(), // Aquesta vista mostrarà el formulari de registre
        ],
      ),
    );
  }
}

// --- Desktop Layout (Side-by-side) ---
class _LoginPageDesktop extends StatelessWidget {
  const _LoginPageDesktop();

  @override
  Widget build(BuildContext context) {
    // Obtenim l'usuari de Firebase des del provider.
    // La directiva `watch` fa que el widget es reconstrueixi si l'estat de l'usuari canvia.
    final firebaseUser = context.watch<User?>();

    // Si l'usuari ha iniciat sessió (no és null), només mostrem la vista de perfil.
    // La vista _LoginView ara gestiona internament si mostrar el perfil o el formulari de login.
    if (firebaseUser != null) {
      return const Center(child: _LoginView());
    }

    // Si l'usuari NO ha iniciat sessió, mostrem el disseny de dues columnes
    // per permetre iniciar sessió o registrar-se. Avoid extra Center wrappers
    // which can cause layout issues with scrolling/keyboard on narrow viewports.
    return const Row(
      children: [
        Expanded(child: _LoginView()),
        VerticalDivider(width: 1, thickness: 1), // Fem el divisor visible
        Expanded(child: _RegisterView()),
      ],
    );
  }
}

// --- Reusable Login/Profile View (_LoginView) ---
// [MODIFICAT] Aquest widget ara gestiona tant el login com la vista de perfil.
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
    // Amaguem el teclat si està obert
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Si el login detecta que l'usuari està aprovat i necessita crear
      // una contrasenya, naveguem des d'aquí.
      if (result == RegistrationStep.approvedNeedPassword) {
        // Assegurem que el widget encara està muntat abans de navegar
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
      // En altres casos (login exitós o error), no fem res.
      // El login exitós serà gestionat per l'AuthWrapper (que veurà el canvi a User)
      // i l'error es mostrarà a la UI gràcies al `watch` al mètode build.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mirem l'usuari de Firebase per decidir què mostrar.
    final firebaseUser = context.watch<User?>();
    final authProvider = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // **NOU: Si l'usuari està connectat, mostrem la vista de perfil/logout.**
    if (firebaseUser != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'El meu Perfil',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (firebaseUser.photoURL != null &&
                  firebaseUser.photoURL!.isNotEmpty) ...[
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(firebaseUser.photoURL!),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                firebaseUser.displayName ?? 'Usuari',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                firebaseUser.email!,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Tancar Sessió'),
                onPressed: () async {
                  // Cridem al mètode signOut del provider.
                  await authProvider.signOut();
                  // No cal navegar, el wrapper s'encarregarà de redirigir.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // **VISTA ANTIGA: Si l'usuari NO està connectat, mostrem el formulari de login.**
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
                'Ja tens compte?',
                style: textTheme.headlineMedium,
              ), // Ajustem estil
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
                onFieldSubmitted: (_) => _submit(), // Permet enviar amb Enter
              ),
              const SizedBox(height: 8),
              Align(
                // Alineem el botó de "oblidar contrasenya"
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    /* TODO: Implementar recuperació contrasenya */
                  },
                  child: const Text('He oblidat la meva contrasenya'),
                ),
              ),
              const SizedBox(height: 16),
              // Mostrem l'indicador només si estem carregant AQUEST formulari
              if (authProvider.isLoading &&
                  authProvider.currentStep == RegistrationStep.initial)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : _submit, // Desactivem si carrega
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

// --- Register Flow Container (_RegisterView) ---
// (Aquest és el widget que canvia més)
class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    // Observem el provider per reaccionar als canvis de 'currentStep'
    final authProvider = context.watch<AuthProvider>();

    // Usem AnimatedSwitcher per a una transició suau entre passos
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        // Podem fer un Fade o Slide
        return FadeTransition(opacity: animation, child: child);
        // return SlideTransition(
        //   position: Tween<Offset>(
        //     begin: const Offset(1.0, 0.0), // Entra des de la dreta
        //     end: Offset.zero,
        //   ).animate(animation),
        //   child: child,
        // );
      },
      // La Key és important per a AnimatedSwitcher
      // Canviem el widget mostrat segons el pas actual
      child: _registerStepChild(context, authProvider),
    );
  }

  // Helper to map RegistrationStep to the widget to display. Replaces
  // the Dart 3 switch-expression to keep compatibility with older analyzers.
  Widget _registerStepChild(BuildContext context, AuthProvider authProvider) {
    switch (authProvider.currentStep) {
      case RegistrationStep.initial:
      case RegistrationStep.licenseLookup:
        return const _RegisterStep1License(key: ValueKey('RegisterStep1'));

      case RegistrationStep.licenseVerified:
      case RegistrationStep.requestingRegistration:
        return const _RegisterStep2Email(key: ValueKey('RegisterStep2'));

      case RegistrationStep.requestSent:
        return const _RegisterStep3RequestSent(key: ValueKey('RegisterStep3'));

      case RegistrationStep.error:
        return _buildErrorStep(context, authProvider);

      case RegistrationStep.approvedNeedPassword:
        return const Center(
          key: ValueKey('ApprovedLoading'),
          child: CircularProgressIndicator(),
        );

      case RegistrationStep.completingRegistration:
      case RegistrationStep.registrationComplete:
        return const Center(
          key: ValueKey('RegisterLoading'),
          child: CircularProgressIndicator(),
        );
    }
  }

  // Helper per decidir quin widget mostrar quan hi ha error
  Widget _buildErrorStep(BuildContext context, AuthProvider authProvider) {
    // Podríem tenir una lògica més complexa per saber a quin pas tornar,
    // però de moment, si hi ha dades de llicència, mostrem el pas 2, sinó el 1.
    if (authProvider.verifiedLicenseData != null) {
      return const _RegisterStep2Email(key: ValueKey('RegisterStep2_Error'));
    } else {
      return const _RegisterStep1License(key: ValueKey('RegisterStep1_Error'));
    }
  }
}

// --- Register Step 1: Verify License (_RegisterStep1License) ---
// (Abans _RegisterStep1)
class _RegisterStep1License extends StatefulWidget {
  const _RegisterStep1License({super.key});

  @override
  State<_RegisterStep1License> createState() => _RegisterStep1LicenseState();
}

class _RegisterStep1LicenseState extends State<_RegisterStep1License> {
  final _licenseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // Amaga teclat
    if (_formKey.currentState?.validate() ?? false) {
      // Cridem al mètode del provider. La navegació/canvi d'estat
      // es gestiona automàticament gràcies al watch a _RegisterView.
      await context.read<AuthProvider>().verifyLicense(
        _licenseController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escoltem canvis per mostrar loading/error
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
              // Text('Pas 1 de 3', style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary)),
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
                  // Desactivem si ja està carregant
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

// --- Register Step 2: Request Registration (_RegisterStep2Email) ---
// (Nou widget basat en l'antic _RegisterStep2 i verifyEmail.jpg)
class _RegisterStep2Email extends StatefulWidget {
  const _RegisterStep2Email({super.key});

  @override
  State<_RegisterStep2Email> createState() => _RegisterStep2EmailState();
}

class _RegisterStep2EmailState extends State<_RegisterStep2Email> {
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
      // Cridem al mètode del provider per enviar la sol·licitud
      await context.read<AuthProvider>().submitRegistrationRequest(
        _emailController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    // Agafem les dades verificades del provider
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

    // Fallback per si les dades no estan disponibles (no hauria de passar)
    if (licenseData == null) {
      return const Center(
        key: ValueKey('Step2Loading'),
        child: CircularProgressIndicator(),
      );
    }

    // Construïm la UI basada en verifyEmail.jpg
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
              // Text('Pas 2 de 3', style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: 16),
              Text(
                'Hola ${licenseData['nom'] ?? ''}! Hem confirmat la teva identitat.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              // Mostrem les dades obtingudes
              _buildReadOnlyData(
                'Nom',
                '${licenseData['nom'] ?? ''} ${licenseData['cognoms'] ?? ''}',
              ),
              _buildReadOnlyData(
                'Categoria',
                licenseData['categoriaRrtt'] ?? 'N/A',
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
              // Botó per tornar enrere (opcional, reseteja l'estat)
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

  // Helper per mostrar les dades llegides (similar al _buildUserInfoTile anterior)
  Widget _buildReadOnlyData(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// --- Register Step 3: Request Sent Confirmation (_RegisterStep3RequestSent) ---
// (Nou widget basat en verifyEmail_exit.jpg)
class _RegisterStep3RequestSent extends StatelessWidget {
  const _RegisterStep3RequestSent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final email =
        authProvider.pendingEmail ??
        'el teu correu'; // Email guardat al provider

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
            // Botó per "tancar" o tornar a l'inici del login
            OutlinedButton(
              onPressed: () {
                // Reseteja l'estat i torna al pas 1 (o a la vista de login)
                // Ja no cal 'if (mounted)' aquí perquè estem en un StatelessWidget
                context.read<AuthProvider>().reset();
                // Opcional: Podríem forçar el canvi de Tab si som a mòbil
                // (Això requeriria passar el TabController o buscar-lo d'una altra manera)
                // final tabController = DefaultTabController.of(context);
                // tabController?.animateTo(0);
              },
              child: const Text('Tornar a l\'inici'),
            ),
          ],
        ),
      ),
    );
  }
}
