import 'create_password_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/auth_provider.dart'; // Importem el provider actualitzat
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
    widget.authProvider.addListener(_onAuthProviderChange);

    // Comprova si estem esperant un token i mostra el diàleg automàticament
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.authProvider.isWaitingForToken) {
        _showAutoTokenDialog();
      }
    });
  }

  void _onAuthProviderChange() {
    // Si canvia l'estat d'espera del token, mostra el diàleg
    if (mounted && widget.authProvider.isWaitingForToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAutoTokenDialog();
        }
      });
    }
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

  Future<void> _showAutoTokenDialog() async {
    final authProvider = widget.authProvider;
    final licenseId = authProvider.pendingLicenseId;
    final email = authProvider.pendingEmail;

    if (licenseId == null || email == null) {
      // Si no tenim les dades necessàries, netegem l'estat
      authProvider.clearTokenWaitingState();
      return;
    }

    String token = '';
    bool isLoading = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return PopScope(
              canPop: false, // Bloqueja el back
              child: AlertDialog(
                backgroundColor: AppTheme.grisPistacho.withValues(
                  alpha: 0.95,
                ), // Gris pistachi del tema més clar
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Introdueix el codi d\'activació',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'S\'ha enviat un codi d\'activació a $email. Revisa el teu correu i introdueix el codi rebut.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            labelText: 'Codi d\'activació',
                            labelStyle: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            errorText: errorText,
                            errorStyle: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.porpraFosc,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppTheme.grisPistacho.withValues(
                              alpha: 0.60,
                            ),
                          ),
                          onChanged: (v) => setState(() => token = v.trim()),
                          autofocus: true,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            // Netejem l'estat i tanquem el diàleg
                            authProvider.clearTokenWaitingState();
                            Navigator.of(context).pop();
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
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
                                  (data['success'] == true ||
                                      data['ok'] == true);

                              if (success) {
                                // Token vàlid - netejem l'estat i naveguem
                                authProvider.clearTokenWaitingState();
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
                                      : 'Codi invàlid. Torna-ho a provar.';
                                  isLoading = false;
                                });
                              }
                            } catch (e) {
                              setState(() {
                                errorText =
                                    'Error de connexió. Torna-ho a provar.';
                                isLoading = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mostassa, // Mostassa del tema
                      foregroundColor:
                          AppTheme.porpraFosc, // Porpra fosc per contrast
                      disabledBackgroundColor: AppTheme.grisPistacho.withValues(
                        alpha: 0.8,
                      ), // Fons quan desactivat
                      disabledForegroundColor: AppTheme.textBlackLow.withValues(
                        alpha: 0.7,
                      ), // Text visible quan desactivat
                      elevation: 3,
                      shadowColor: AppTheme.porpraFosc.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: AppTheme.porpraFosc, // Vora porpra fosc
                          width: 1.5,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.porpraFosc,
                              ), // Porpra fosc
                            ),
                          )
                        : const Text('Validar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    widget.authProvider.removeListener(_onAuthProviderChange);
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
  @override
  void initState() {
    super.initState();

    // Comprova si estem esperant un token i mostra el diàleg automàticament
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.addListener(_onAuthProviderChange);
      if (mounted && authProvider.isWaitingForToken) {
        _showAutoTokenDialog(authProvider);
      }
    });
  }

  void _onAuthProviderChange() {
    final authProvider = context.read<AuthProvider>();
    if (mounted && authProvider.isWaitingForToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAutoTokenDialog(authProvider);
        }
      });
    }
  }

  @override
  void dispose() {
    final authProvider = context.read<AuthProvider>();
    authProvider.removeListener(_onAuthProviderChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use AuthProvider to determine authentication state (centralized logic).
    final authProvider = context.watch<AuthProvider>();
    final firebaseUser = authProvider.isAuthenticated;
    // Si l'usuari ha iniciat sessió (no és null), només mostrem la vista de perfil.
    // La vista _LoginView ara gestiona internament si mostrar el perfil o el formulari de login.
    if (firebaseUser) {
      return const Center(child: _LoginView());
    }

    // Si l'usuari NO ha iniciat sessió, mostrem el disseny de dues columnes
    // per permetre iniciar sessió o registrar-se.
    return const Row(
      children: [
        Expanded(child: Center(child: _LoginView())),
        VerticalDivider(width: 1, thickness: 1), // Fem el divisor visible
        Expanded(child: Center(child: _RegisterView())),
      ],
    );
  }

  Future<void> _showAutoTokenDialog(AuthProvider authProvider) async {
    final licenseId = authProvider.pendingLicenseId;
    final email = authProvider.pendingEmail;

    if (licenseId == null || email == null) {
      authProvider.clearTokenWaitingState();
      return;
    }

    String token = '';
    bool isLoading = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                backgroundColor: AppTheme.grisPistacho.withValues(
                  alpha: 0.95,
                ), // Gris pistacxo més clar
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Introdueix el codi d\'activació',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'S\'ha enviat un codi d\'activació a $email. Revisa el teu correu i introdueix el codi rebut.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            labelText: 'Codi d\'activació',
                            labelStyle: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            errorText: errorText,
                            errorStyle: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.mostassa,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onChanged: (v) => setState(() => token = v.trim()),
                          autofocus: true,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            authProvider.clearTokenWaitingState();
                            Navigator.of(context).pop();
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
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
                                  (data['success'] == true ||
                                      data['ok'] == true);

                              if (success) {
                                authProvider.clearTokenWaitingState();
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
                                      : 'Codi invàlid. Torna-ho a provar.';
                                  isLoading = false;
                                });
                              }
                            } catch (e) {
                              setState(() {
                                errorText =
                                    'Error de connexió. Torna-ho a provar.';
                                isLoading = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mostassa, // Mostassa del tema
                      foregroundColor:
                          AppTheme.porpraFosc, // Porpra fosc per contrast
                      disabledBackgroundColor: AppTheme.grisPistacho.withValues(
                        alpha: 0.8,
                      ), // Fons quan desactivat
                      disabledForegroundColor: AppTheme.textBlackLow.withValues(
                        alpha: 0.7,
                      ), // Text visible quan desactivat
                      elevation: 3,
                      shadowColor: AppTheme.porpraFosc.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: AppTheme.porpraFosc, // Vora porpra fosc
                          width: 1.5,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.porpraFosc,
                              ), // Porpra fosc
                            ),
                          )
                        : const Text('Validar'),
                  ),
                ],
              ),
            );
          },
        );
      },
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

    // **NOU: Si l'usuari està connectat, mostrem la vista de perfil/logout.**
    if (isAuthenticated) {
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
              if (authProvider.currentUserPhotoUrl != null &&
                  authProvider.currentUserPhotoUrl!.isNotEmpty) ...[
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                    authProvider.currentUserPhotoUrl!,
                  ),
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
                authProvider.currentUserDisplayName ?? 'Usuari',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.currentUserEmail ?? '',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Tancar Sessió'),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  // Cridem al mètode signOut del provider i naveguem explícitament
                  // a la pàgina de login per assegurar un comportament consistent.
                  await authProvider.signOut();
                  if (!context.mounted) return;
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
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
