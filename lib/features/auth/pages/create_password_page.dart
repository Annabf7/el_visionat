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
      backgroundColor: const Color(0xFF4D5061),
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

  // UI / validation state
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _strength = 0; // 0 none, 1 weak, 2 medium, 3 strong

  // Design colors (kept local to ensure page matches AppTheme palette)
  static const Color porpraFosc = Color(0xFF2F313C);
  static const Color grisPistacho = Color(0xFFCDD1C4);
  static const Color mostassa = Color(0xFFE8C547);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final pwd = _passwordController.text;
    int score = 0;
    if (pwd.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score++;
    if (RegExp(r'[a-z]').hasMatch(pwd)) score++;
    if (RegExp(r'\d').hasMatch(pwd)) score++;
    if (RegExp(r'[@\$!%*?&]').hasMatch(pwd)) score++;

    int newStrength;
    if (score >= 5) {
      newStrength = 3;
    } else if (score >= 3) {
      newStrength = 2;
    } else if (score > 0) {
      newStrength = 1;
    } else {
      newStrength = 0;
    }

    if (newStrength != _strength) {
      setState(() => _strength = newStrength);
    } else {
      // still update to trigger UI for empty -> non-empty
      if (_strength == 0 && pwd.isNotEmpty) setState(() {});
    }
  }

  bool get _isFormValid {
    final pwd = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (pwd.trim() != pwd || pwd.isEmpty) return false;
    // prefer a direct check of components
    if (pwd.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(pwd)) return false;
    if (!RegExp(r'[a-z]').hasMatch(pwd)) return false;
    if (!RegExp(r'\d').hasMatch(pwd)) return false;
    if (!RegExp(r'[@\$!%*?&]').hasMatch(pwd)) return false;
    if (confirm != pwd) return false;
    return true;
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
              // Password field with toggle and strength
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Nova contrasenya',
                  labelStyle: TextStyle(color: grisPistacho),
                  filled: true,
                  fillColor: porpraFosc.withAlpha(15),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: grisPistacho,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  final v = value ?? '';
                  if (v.trim() != v || v.isEmpty) {
                    return 'Ha de tenir com a mínim 8 caràcters.';
                  }
                  if (v.length < 8) {
                    return 'Ha de tenir com a mínim 8 caràcters.';
                  }
                  if (!RegExp(r"(?=.*[A-Z])").hasMatch(v) ||
                      !RegExp(r"(?=.*[0-9])").hasMatch(v) ||
                      !RegExp(r"(?=.*[@\$!%*?&])").hasMatch(v)) {
                    return 'Inclou una majúscula, un número i un símbol especial.';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),

              const SizedBox(height: 8),

              // Strength indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 8,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double pct = 0;
                        Color col = Colors.transparent;
                        if (_strength == 1) {
                          pct = 0.33;
                          col = const Color(0xFFE57373);
                        } else if (_strength == 2) {
                          pct = 0.66;
                          col = const Color(0xFFFFD54F);
                        } else if (_strength == 3) {
                          pct = 1.0;
                          col = const Color(0xFF81C784);
                        }
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: constraints.maxWidth * pct,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: col,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _strength == 0
                          ? ''
                          : (_strength == 1
                                ? 'Dèbil'
                                : (_strength == 2 ? 'Mitjana' : 'Forta')),
                      style: TextStyle(color: grisPistacho, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirma la contrasenya',
                  labelStyle: TextStyle(color: grisPistacho),
                  filled: true,
                  fillColor: porpraFosc.withAlpha(15),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_confirmPasswordController.text.isNotEmpty &&
                          _confirmPasswordController.text ==
                              _passwordController.text)
                        const Padding(
                          padding: EdgeInsets.only(right: 6.0),
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFF81C784),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: grisPistacho,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ],
                  ),
                ),
                obscureText: _obscureConfirm,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma la contrasenya';
                  }
                  if (value != _passwordController.text) {
                    return 'Les contrasenyes han de coincidir.';
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
                  onPressed: (authProvider.isLoading || !_isFormValid)
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? mostassa
                        : mostassa.withAlpha(115),
                    foregroundColor: porpraFosc,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
