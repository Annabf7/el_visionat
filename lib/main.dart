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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Importat per kDebugMode

void main() async {
  // --- Configuració Inicial ---
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Instanciem FirebaseFunctions de manera condicional (Solució a problemes d'emulació web)
  final FirebaseFunctions functionsInstance;
  if (kDebugMode) {
    // En mode debug (emulators), no especifiquem regió
    functionsInstance = FirebaseFunctions.instance;
    debugPrint("Using default FirebaseFunctions instance for emulators.");
  } else {
    // En producció, especifiquem la regió correcta
    functionsInstance = FirebaseFunctions.instanceFor(region: 'europe-west1');
    debugPrint("Using FirebaseFunctions instance for region 'europe-west1'.");
  }

  // Instanciem AuthService amb la instància de Functions correcta
  final authService = AuthService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    functions: functionsInstance,
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
      // Utilitzem el tema compartit AppTheme.theme (assumint que existeix)
      theme: AppTheme.theme,
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
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    // Si l'usuari està logat, mostrem la HomePage.
    // Si no, mostrem la LoginPage. La LoginPage s'encarregarà de la navegació
    // a la creació de contrasenya si és necessari.
    return firebaseUser != null ? const HomePage() : const LoginPage();
  }
}
