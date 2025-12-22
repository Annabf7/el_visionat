import 'create_password_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/auth_provider.dart'; // Importem el provider actualitzat
import '../widgets/register_steps.dart'; // Import RegisterStepGender
import '../../../core/theme/app_theme.dart';

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
    // NOTE: No mostrem el diàleg del token automàticament perquè l'aprovació
    // és manual i pot trigar uns minuts. L'usuari veurà el diàleg només quan
    // intenti fer login i el sistema detecti que està aprovat.
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
    // Use AuthProvider to determine authentication state (centralized logic).
    // NOTE: We must NOT render a profile UI inline here. Profile must only be
    // shown via the dedicated `/profile` route. If a user is authenticated and
    // lands on this page, redirect them to /home instead of rendering Profile.
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated) {
      // If somehow we are on the login page while authenticated, navigate to home
      // and avoid rendering any profile widget here (prevents flash).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If the user is not authenticated, show the tabbed login/register UI.
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
        children: const [
          Center(
            child: _LoginView(),
          ), // Aquesta vista mostrarà el formulari de login
          Center(
            child: _RegisterView(),
          ), // Aquesta vista mostrarà el formulari de registre
        ],
      ),
    );
  }
}

// --- Desktop Layout (Side-by-side) ---
class _LoginPageDesktop extends StatefulWidget {
  const _LoginPageDesktop();

  @override
  State<_LoginPageDesktop> createState() => _LoginPageDesktopState();
}

class _LoginPageDesktopState extends State<_LoginPageDesktop> {
  // NOTE: No mostrem el diàleg del token automàticament perquè l'aprovació
  // és manual i pot trigar uns minuts. L'usuari veurà el diàleg només quan
  // intenti fer login i el sistema detecti que està aprovat.

  @override
  Widget build(BuildContext context) {
    // Use AuthProvider to determine authentication state (centralized logic).
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    // If the user is authenticated and somehow ended up on this page,
    // redirect them to home and show only a loading indicator.
    if (isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If the user is NOT authenticated, show the two-column layout
    // allowing them to login or register.
    return const Row(
      children: [
        Expanded(child: Center(child: _LoginView())),
        VerticalDivider(width: 1, thickness: 1),
        Expanded(child: Center(child: _RegisterView())),
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

      // If the provider has a pending email from the registration flow,
      // treat the second field as the activation token rather than a
      // password. This allows users coming from "Sol·licitud Enviada" to
      // paste the token directly on the login screen.
      final bool isPendingRegistration =
          authProvider.pendingEmail != null &&
          authProvider.currentStep == RegistrationStep.requestSent;

      if (isPendingRegistration) {
        // Validate token via callable function.
        final email = authProvider.pendingEmail!;
        final token = _passwordController.text.trim();

        // Capture navigator before awaiting
        final rootNavigator = Navigator.of(context, rootNavigator: true);

        // Capture ScaffoldMessenger before the async gap so we don't use
        // BuildContext after awaiting (avoids analyzer warnings).
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          final functions = FirebaseFunctions.instanceFor(
            region: 'europe-west1',
          );
          final callable = functions.httpsCallable('validateActivationToken');
          final res = await callable.call(<String, dynamic>{
            'email': email,
            'token': token,
          });
          final data = res.data as Map<dynamic, dynamic>?;
          final success =
              data != null && (data['success'] == true || data['ok'] == true);
          if (success) {
            if (!mounted) return;
            rootNavigator.pushReplacementNamed(
              '/create-password',
              arguments: CreatePasswordPageArguments(
                licenseId: authProvider.pendingLicenseId!,
                email: email,
              ),
            );
          } else {
            final msg = data != null && data['message'] != null
                ? data['message'].toString()
                : 'Codi invàlid';
            scaffoldMessenger.showSnackBar(SnackBar(content: Text(msg)));
          }
        } on FirebaseFunctionsException catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(e.message ?? 'Error del servidor')),
          );
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Error de xarxa. Torna-ho a intentar.'),
            ),
          );
        }
      } else {
        final result = await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Si el login detecta que l'usuari està aprovat i necessita crear
        // una contrasenya, naveguem des d'aquí mitjançant el diàleg de token
        // (cas on l'usuari no venia del flux de registre recent).
        if (result == RegistrationStep.approvedNeedPassword) {
          if (mounted) {
            final licenseId = authProvider.pendingLicenseId;
            final email = authProvider.pendingEmail;
            if (licenseId != null && email != null) {
              await _showTokenValidationDialog(licenseId, email);
            }
          }
        }

        if (authProvider.isAuthenticated) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        }
      }
      // En altres casos (login exitós o error), no fem res.
      // El login exitós serà gestionat per l'AuthWrapper (que veurà el canvi a User)
      // i l'error es mostrarà a la UI gràcies al `watch` al mètode build.
    }
  }

  // Resend activation token for a pending email. Shows a SnackBar with the result.
  Future<void> _resendActivationTokenFor(String email) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('resendActivationToken');
      final res = await callable.call(<String, dynamic>{'email': email});
      final data = res.data as Map<dynamic, dynamic>?;
      final msg = data != null && data['message'] != null
          ? data['message'].toString()
          : 'Nou codi enviat.';
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(msg)));
    } on FirebaseFunctionsException catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error del servidor')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Error de xarxa. Torna-ho a intentar.')),
      );
    }
  }

  // Shows a dialog to reset password via email
  Future<bool> _showForgotPasswordDialog() async {
    final dialogEmailController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Recuperar contrasenya'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Introdueix el teu correu electrònic i t\'enviarem un enllaç per restablir la contrasenya.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dialogEmailController,
                      decoration: InputDecoration(
                        labelText: 'Correu electrònic',
                        errorText: errorText,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Introdueix un correu';
                        }
                        if (!value.contains('@')) {
                          return 'Correu no vàlid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Cancel·lar'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!(dialogFormKey.currentState?.validate() ??
                              false)) {
                            return;
                          }
                          setState(() {
                            isLoading = true;
                            errorText = null;
                          });

                          // Capture navigator before async gap
                          final navigator = Navigator.of(dialogContext);

                          try {
                            final authProvider = context.read<AuthProvider>();
                            await authProvider.sendPasswordReset(
                              dialogEmailController.text.trim(),
                            );

                            // Safe to use captured navigator
                            navigator.pop(true);
                          } catch (e) {
                            setState(() {
                              errorText =
                                  'Error: ${e.toString().replaceFirst('Exception: ', '')}';
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
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
  }

  // Shows a modal dialog to request the activation token and validate it
  // with the backend. Navigates to create-password only on success.
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
                    keyboardType: TextInputType.text,
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
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Resend token for this email
                          await _resendActivationTokenFor(email);
                        },
                  child: const Text('Torna a enviar codi'),
                ),
                ElevatedButton(
                  onPressed: (isLoading || token.isEmpty)
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                            errorText = null;
                          });

                          // Capture navigator instances before awaiting
                          final dialogNavigator = Navigator.of(context);
                          final rootNavigator = Navigator.of(
                            context,
                            rootNavigator: true,
                          );

                          try {
                            final functions = FirebaseFunctions.instanceFor(
                              region: 'europe-west1',
                            );
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
    // Use AuthProvider to determine authentication state and user info.
    final authProvider = context.watch<AuthProvider>();
    final bool isAuthenticated = authProvider.isAuthenticated;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // If the user is authenticated and somehow ended up on this page,
    // redirect them to home and show only a loading indicator (no profile UI).
    if (isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      });
      return const Center(child: CircularProgressIndicator());
    }

    // If the user is NOT authenticated, show the login form.
    final bool showError =
        authProvider.errorMessage != null &&
        authProvider.currentStep == RegistrationStep.initial;

    final bool showTokenField =
        authProvider.pendingEmail != null &&
        authProvider.currentStep == RegistrationStep.requestSent;

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
                decoration: InputDecoration(
                  labelText: showTokenField
                      ? 'Codi d\'activació'
                      : 'Contrasenya',
                ),
                keyboardType: showTokenField
                    ? TextInputType.text
                    : TextInputType.text,
                obscureText: !showTokenField,
                validator: (value) {
                  final v = value ?? '';
                  if (showTokenField) {
                    return v.isEmpty ? 'Introdueix el codi d\'activació' : null;
                  }
                  return (v.length < 6) ? 'Mínim 6 caràcters' : null;
                },
                onFieldSubmitted: (_) => _submit(), // Permet enviar amb Enter
              ),
              const SizedBox(height: 2),
              if (showTokenField && authProvider.pendingEmail != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Call resend and show SnackBar
                      _resendActivationTokenFor(authProvider.pendingEmail!);
                    },
                    child: const Text('Torna a enviar codi'),
                  ),
                ),
              const SizedBox(height: 8),
              if (!showTokenField)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 500;
                    return Padding(
                      padding: EdgeInsets.only(
                        top: isMobile ? 4 : 1,
                        right: isMobile ? 0 : 2,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color.fromARGB(
                              255,
                              161,
                              160,
                              160,
                            ),
                          ),
                          onPressed: () async {
                            debugPrint('🔵 Forgot password button pressed');

                            // Capture ScaffoldMessenger before async gap (professional pattern)
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );

                            try {
                              final result = await _showForgotPasswordDialog();

                              debugPrint('🔵 Dialog result: $result');

                              if (result && mounted) {
                                debugPrint('🔵 Showing success SnackBar');
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'S\'ha enviat un correu per restablir la contrasenya.',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            } catch (error) {
                              debugPrint('🔴 Error: $error');
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${error.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('He oblidat la meva contrasenya'),
                        ),
                      ),
                    );
                  },
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
      case RegistrationStep.genderSelection:
        return const RegisterStepGender(key: ValueKey('RegisterStep1_5'));

      case RegistrationStep.genderSelected:
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
                decoration: InputDecoration(
                  labelText: 'Número de Llicència',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Introdueix el correu electrònic',
                  labelStyle: TextStyle(color: AppTheme.grisPistacho),
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
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.grisPistacho,
                  ),
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

    return SingleChildScrollView(
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
              'Gràcies, ${authProvider.verifiedLicenseData?['nom'] ?? 'usuari'}!',
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.mostassa.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 32, color: AppTheme.mostassa),
                  const SizedBox(height: 12),
                  Text(
                    'Estem comprovant el teu correu electrònic',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.mostassa,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La verificació pot trigar uns minuts. Si el correu $email és correcte i coincideix amb el directori de la FCBQ, rebràs un codi per finalitzar el registre.',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Un cop aprovada la sol·licitud, rebràs un correu amb el codi d\'activació per crear la teva contrasenya.',
              style: textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Botó per anar a la pantalla d'inici de sessió
            OutlinedButton(
              onPressed: () {
                // Navega a /login sense esborrar l'estat, així l'email pendet
                // es manté i el formulari pot mostrar el camp Token.
                final navigator = Navigator.of(context);
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: Text(
                'Iniciar sessió',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
