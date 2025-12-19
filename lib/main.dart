import 'package:el_visionat/firebase_options.dart';
import 'package:el_visionat/features/auth/index.dart';
import 'package:el_visionat/features/home/index.dart';

import 'package:el_visionat/features/visionat/index.dart';
import 'package:el_visionat/features/voting/index.dart';
import 'package:el_visionat/features/teams/index.dart';
import 'package:el_visionat/features/profile/index.dart';
import 'package:el_visionat/core/index.dart';
import 'package:el_visionat/core/services/team_mapping_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Importat per kDebugMode
// Navigation provider importat des de core/index.dart

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Escalfa les Cloud Functions en mode debug per evitar cold start
Future<void> _warmUpFunctions() async {
  try {
    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
    final callable = functions.httpsCallable('warmFunctions');
    await callable.call();
    debugPrint('✅ Functions emulator warmed up successfully');
  } catch (e) {
    debugPrint('⚠️  Failed to warm up Functions emulator: $e');
    // No és crític, l'aplicació pot continuar
  }
}

void main() async {
  // --- Configuració Inicial ---
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Instanciem FirebaseFunctions sempre amb la regió correcte
  // IMPORTANT: Sempre usar europe-west1 per compatibilitat amb les Cloud Functions desplegades
  final FirebaseFunctions functionsInstance = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );
  debugPrint("🔵 Using FirebaseFunctions instance for region 'europe-west1'.");

  // Instanciem AuthService amb la instància de Functions correcta
  final authService = AuthService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    functions: functionsInstance,
  );

  // If running with emulators / in debug, clear any existing FirebaseAuth
  // session so local testing always starts with a clean auth state.
  await authService.clearAuthIfEmulator();

  // If running in debug mode on web, point Firestore/Functions/Auth to the local emulators.
  // This is required for Flutter web where environment variables like FIRESTORE_EMULATOR_HOST
  // are not available. Ports are aligned with `firebase.json` (auth:9198, firestore:8088, functions:5001).
  // Use --dart-define=USE_EMULATORS=false to skip emulators in debug mode.
  const useEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: true);
  if (kDebugMode && kIsWeb && useEmulators) {
    const emulatorHost = '127.0.0.1';
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8088);
    FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).useFunctionsEmulator(emulatorHost, 5001);
    FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9198);
    debugPrint('Web debug: connected to emulators at $emulatorHost');
  } else if (kDebugMode && kIsWeb) {
    debugPrint('Web debug: using PRODUCTION Firebase (emulators disabled)');
  }

  // Warm up Functions emulator in debug mode to avoid cold start delays
  if (kDebugMode) {
    _warmUpFunctions();
  }

  // --- Inicialització Isar i TeamDataService (persistència local) ---
  // If running on web with emulators, ensure the teams collection is seeded so the UI can
  // fetch the teams directly from Firestore (we bypass Isar on web).
  // Skip in production because it requires authentication.
  if (kIsWeb && useEmulators) {
    await seedTeamsIfEmpty(FirebaseFirestore.instance);
  }

  final isarService = IsarService();
  // Assegurem que la BBDD està oberta abans d'arrencar l'app
  await isarService.openDB();

  // Inicialitzem el TeamMappingService per resoldre logos d'equips
  await TeamMappingService.instance.initialize();

  // Instanciem el servei de dades d'equips passant Isar i Firestore
  final teamDataService = TeamDataService(
    isarService,
    FirebaseFirestore.instance,
  );

  // Inicialitzem les dades de localització per a DateFormat (evita LocaleDataException)
  // Assegura't d'afegir la localització que utilitzis, p.ex. 'ca_ES'.
  await initializeDateFormatting('ca_ES');
  Intl.defaultLocale = 'ca_ES';

  runApp(
    // --- Configuració dels Providers ---
    MultiProvider(
      providers: [
        // Injecció dels serveis de persistència (disponibles globalment)
        Provider<IsarService>.value(value: isarService),
        Provider<TeamDataService>.value(value: teamDataService),
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
        ChangeNotifierProvider(
          create: (context) => TeamProvider(
            teamDataService: context.read<TeamDataService>(),
          ), // Provider per a la gestió d'equips
        ),
        ChangeNotifierProvider(
          create: (_) => WeeklyMatchProvider(), // Llegeix de weekly_focus/current
        ),
        // Navigation provider to keep track of the current route name
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        // Visionat feature providers
        ChangeNotifierProvider(
          create: (_) => VisionatHighlightProvider(HighlightService()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              VisionatCollectiveCommentProvider(CollectiveCommentService()),
        ),
        ChangeNotifierProvider(
          create: (_) => PersonalAnalysisProvider(PersonalAnalysisService()),
        ),
        ChangeNotifierProvider(
          create: (_) => YouTubeProvider(YouTubeService()),
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
    // Create a NavigationObserver that will update the NavigationProvider
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final navObserver = NavigationObserver(navProvider);

    return MaterialApp(
      title: 'El Visionat',
      debugShowCheckedModeBanner: false, // Traiem el banner de debug
      // Utilitzem el tema compartit AppTheme.theme (assumint que existeix)
      theme: AppTheme.theme,
      navigatorObservers: [navObserver],
      // --- Configuració de Rutes ---
      initialRoute: '/', // La ruta inicial, gestionada per AuthWrapper
      routes: {
        '/': (context) => const AuthWrapper(), // El widget que decideix on anar
        '/home': (context) => RequireAuth(child: const HomePage()),
        '/all-matches': (context) => RequireAuth(child: const AllMatchesPage()),
        '/profile': (context) => RequireAuth(child: const ProfilePage()),
        '/accounting': (context) => RequireAuth(child: const AccountingPage()),
        '/teams': (context) => RequireAuth(child: const TeamsPage()),
        '/visionat': (context) => RequireAuth(child: const VisionatMatchPage()),
        '/login': (context) => const LoginPage(), // Ruta explícita per a Login
        '/create-password': (context) =>
            const CreatePasswordPage(), // Ruta per crear contrasenya
        // Pots afegir més rutes aquí si callen
      },
    );
  }
}

// --- Auth Wrapper: Decideix la Pantalla Inicial ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Show a short loading gate while the AuthProvider receives the initial
    // auth state from Firebase. This prevents a flash of the profile/login
    // UI while the SDK initializes.
    if (!auth.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If auth is initialized, decide between Login and Home. RequireAuth will
    // protect Home routes; AuthWrapper only chooses which initial page to show.
    if (!auth.isAuthenticated) return const LoginPage();
    return const HomePage();
  }
}
