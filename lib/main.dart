import 'package:el_visionat/firebase_options.dart';
import 'package:el_visionat/providers/auth_provider.dart';
import 'package:el_visionat/screens/create_password_page.dart';
import 'package:el_visionat/screens/home_page.dart';
import 'package:el_visionat/screens/login_page.dart';
import 'package:el_visionat/services/auth_service.dart';
import 'package:el_visionat/theme/app_theme.dart';
import 'package:el_visionat/providers/home_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart'; // Aquesta ja inclou kDebugMode
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // --- Configuració Inicial ---
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Instanciem FirebaseFunctions de manera condicional
  final FirebaseFunctions functions;
  if (kDebugMode) {
    // En mode debug, no especifiquem regió per a l'emulador.
    // L'emulador ignora la regió, però especificar-la pot causar problemes de URL en web.
    functions = FirebaseFunctions.instance;
  } else {
    // En producció, especifiquem la regió correcta.
    functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  }

  // Instanciem AuthService amb la instància de Functions correcta
  final authService = AuthService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    functions: functions,
  );

  runApp(
    // --- Configuració dels Providers ---
    MultiProvider(
      providers: [
        // Proveïdor per a l'estat d'autenticació de Firebase (User?)
        StreamProvider<User?>.value(
          value: authService
              .authStateChanges, // Escolta canvis d'usuari (login/logout)
          initialData: null, // Comença sense usuari
          catchError: (_, err) {
            // Gestió bàsica d'errors de l'stream
            debugPrint("Error in authStateChanges stream: $err");
            return null; // En cas d'error, tracta com si no hi hagués usuari
          },
        ),
        // Proveïdors de l'aplicació (ChangeNotifierProvider)
        ChangeNotifierProvider(
          create: (_) => HomeProvider(),
        ), // Provider per a la HomePage
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
          ), // El nostre provider d'autenticació/registre
        ),
      ],
      child: const MyApp(), // L'aplicació principal
    ),
  );
}

// --- Widget Principal de l'Aplicació (MaterialApp) ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Visionat',
      debugShowCheckedModeBanner: false, // Traiem el banner de debug
      theme: AppTheme.theme, // Apliquem el tema personalitzat
      // --- Configuració de Rutes ---
      initialRoute: '/', // La ruta inicial, gestionada per AuthWrapper
      routes: {
        '/': (context) => const AuthWrapper(), // El widget que decideix on anar
        '/home': (context) => const HomePage(), // Ruta explícita per a Home
        '/login': (context) => const LoginPage(), // Ruta explícita per a Login
        '/create-password': (context) =>
            const CreatePasswordPage(), // Ruta per crear contrasenya
        // Pots afegir més rutes aquí si calen
      },
    );
  }
}

// --- Auth Wrapper: Decideix la Pantalla Inicial ---
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isNavigating = false; // Flag per evitar navegacions múltiples

  @override
  Widget build(BuildContext context) {
    // Escolta l'estat d'autenticació de Firebase via StreamProvider
    final firebaseUser = context.watch<User?>();
    // Escolta l'estat del nostre AuthProvider
    final authProvider = context.watch<AuthProvider>();

    // Determina la ruta actual per evitar navegacions innecessàries
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    // --- Lògica Principal de Redirecció ---

    // 1. Si hi ha usuari a Firebase (està logat)
    if (firebaseUser != null) {
      _handleNavigation('/home', currentRouteName);
      // Mentrestant, mostrem HomePage o un loading si venim d'una altra ruta
      return currentRouteName == '/home'
          ? const HomePage()
          : const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // 2. Si NO hi ha usuari a Firebase (deslogat o en procés)
    else {
      // 2a. Comprovem si el provider indica que cal crear contrasenya
      if (authProvider.currentStep == RegistrationStep.approvedNeedPassword) {
        // Necessitem les dades per als arguments
        final licenseId = authProvider.pendingLicenseId;
        final email = authProvider.pendingEmail;

        // Comprovem que tenim les dades necessàries
        if (licenseId != null && email != null) {
          _handleNavigation(
            '/create-password',
            currentRouteName,
            arguments: CreatePasswordPageArguments(
              licenseId: licenseId,
              email: email,
            ),
          );
          // Mentrestant, mostrem loading
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          // Si no tenim les dades, alguna cosa ha anat malament, tornem a login
          debugPrint(
            "Error: ApprovedNeedPassword state without pending data. Resetting.",
          );
          // Usem addPostFrameCallback per canviar l'estat després del build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthProvider>().reset(); // Reseteja per seguretat
          });
          _handleNavigation('/login', currentRouteName);
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      }
      // 2b. Si no estem en cap pas especial, anem a la LoginPage
      else {
        _handleNavigation('/login', currentRouteName);
        // Mentrestant, mostrem LoginPage o loading si venim d'una altra ruta
        return currentRouteName == '/login'
            ? const LoginPage()
            : const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
    }
  }

  // Funció helper per gestionar la navegació de forma segura
  void _handleNavigation(
    String targetRoute,
    String? currentRoute, {
    Object? arguments,
  }) {
    // Només naveguem si no estem ja navegant I no som ja a la ruta destí
    if (!_isNavigating && currentRoute != targetRoute) {
      _isNavigating = true; // Marquem que estem navegant
      // Usem addPostFrameCallback per assegurar que la navegació es fa després del build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Comprovem si el widget encara està muntat abans de navegar
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            targetRoute,
            (route) => false, // Elimina totes les rutes anteriors
            arguments: arguments,
          );
        }
        // Reset del flag després d'un petit retard per si hi ha builds ràpids
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            // Comprova de nou per seguretat
            _isNavigating = false;
          }
        });
      });
    }
  }
}
