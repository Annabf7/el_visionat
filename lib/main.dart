import 'package:el_visionat/firebase_options.dart';
import 'package:el_visionat/features/auth/index.dart';
import 'package:el_visionat/features/home/index.dart';

import 'package:el_visionat/features/visionat/index.dart';
import 'package:el_visionat/features/voting/index.dart';
import 'package:el_visionat/features/teams/index.dart';
import 'package:el_visionat/features/profile/index.dart';
import 'package:el_visionat/features/designations/pages/designations_page.dart';
import 'package:el_visionat/features/reports/index.dart';
import 'package:el_visionat/features/vestidor/index.dart';
import 'package:el_visionat/features/gestiona_t/index.dart';
import 'package:el_visionat/features/notifications/providers/notification_provider.dart';
import 'package:el_visionat/features/search/providers/search_provider.dart';
import 'package:el_visionat/core/index.dart';
import 'package:el_visionat/core/services/team_mapping_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Importat per kDebugMode
import 'package:flutter_localizations/flutter_localizations.dart';
// Navigation provider importat des de core/index.dart

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  // If running in debug mode on web, point Firestore/Functions/Auth/Storage to the local emulators.
  // This is required for Flutter web where environment variables like FIRESTORE_EMULATOR_HOST
  // are not available. Ports are aligned with `firebase.json` (auth:9198, firestore:8088, functions:5001, storage:9199).
  // Use --dart-define=USE_EMULATORS=true to enable emulators in debug mode.
  const useEmulators = bool.fromEnvironment(
    'USE_EMULATORS',
    defaultValue: false, // Canviat a false per treballar en producció per defecte
  );
  if (kDebugMode && kIsWeb && useEmulators) {
    const emulatorHost = '127.0.0.1';
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8088);
    FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).useFunctionsEmulator(emulatorHost, 5001);
    FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9198);
    // Storage emulator al port 9199
    await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
    debugPrint(
      'Web debug: connected to emulators at $emulatorHost (including Storage)',
    );
  } else if (kDebugMode && kIsWeb) {
    debugPrint('Web debug: using PRODUCTION Firebase (emulators disabled)');
  }

  // Warm up Functions emulator in debug mode to avoid cold start delays
  if (kDebugMode) {
    _warmUpFunctions();
  }

  // --- Inicialització de serveis ---
  // If running on web with emulators, ensure the teams collection is seeded
  if (kIsWeb && useEmulators) {
    await seedTeamsIfEmpty(FirebaseFirestore.instance);
  }

  // Inicialitzem el TeamMappingService per resoldre logos d'equips
  await TeamMappingService.instance.initialize();

  // Instanciem el servei de dades d'equips amb Firestore
  final teamDataService = TeamDataService(
    FirebaseFirestore.instance,
  );

  // Inicialitzem les dades de localització per a DateFormat (evita LocaleDataException)
  // Assegura't d'afegir la localització que utilitzis, p.ex. 'ca_ES'.
  await initializeDateFormatting('ca_ES');
  Intl.defaultLocale = 'ca_ES';

  // Configurem timeago per usar català
  timeago.setLocaleMessages('ca', timeago.CaMessages());
  timeago.setDefaultLocale('ca');

  runApp(
    // --- Configuració dels Providers ---
    MultiProvider(
      providers: [
        // Injecció del servei de dades d'equips (disponible globalment)
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
          create: (_) =>
              WeeklyMatchProvider(), // Llegeix de weekly_focus/current
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
        // Notification provider
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
        // Comment provider for highlights
        ChangeNotifierProvider(
          create: (_) => CommentProvider(),
        ),
        // Reports provider
        ChangeNotifierProvider(
          create: (_) => ReportsProvider(),
        ),
        // Vestidor (botiga merchandising) provider
        ChangeNotifierProvider(
          create: (_) => VestidorProvider(),
        ),
        // Search provider per cerca global d'àrbitres
        ChangeNotifierProvider(
          create: (_) => SearchProvider(),
        ),
        // Schedule provider per Gestiona't
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(),
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
      // Localitzacions per tenir el calendari i altres widgets en català
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ca', 'ES'), // Català
        Locale('es', 'ES'), // Espanyol
        Locale('en', 'US'), // Anglès
      ],
      locale: const Locale('ca', 'ES'), // Forcem català per defecte
      // --- Configuració de Rutes ---
      initialRoute: '/', // La ruta inicial, gestionada per AuthWrapper
      routes: {
        '/': (context) => const AuthWrapper(), // El widget que decideix on anar
        '/home': (context) => RequireAuth(child: const HomePage()),
        '/all-matches': (context) => RequireAuth(child: const AllMatchesPage()),
        '/profile': (context) => RequireAuth(child: const ProfilePage()),
        '/reports': (context) => RequireAuth(child: const ReportsPage()),
        '/visionat': (context) => RequireAuth(child: const VisionatMatchPage()),
        '/designations': (context) => RequireAuth(child: const DesignationsPage()),
        '/vestidor': (context) => RequireAuth(child: const VestidorPage()),
        '/gestiona-t': (context) => RequireAuth(child: const GestionaTPage()),
        '/login': (context) => const LoginPage(), // Ruta explícita per a Login
        '/create-password': (context) =>
            const CreatePasswordPage(), // Ruta per crear contrasenya
        // Pots afegir més rutes aquí si callen
      },
      onGenerateRoute: (settings) {
        // Ruta dinàmica per veure perfils públics d'usuaris
        if (settings.name == '/user-profile') {
          final userId = settings.arguments as String?;
          if (userId != null) {
            return MaterialPageRoute(
              builder: (context) => RequireAuth(
                child: UserProfilePage(userId: userId),
              ),
            );
          }
        }
        return null;
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
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    // Show a short loading gate while the AuthProvider receives the initial
    // auth state from Firebase. This prevents a flash of the profile/login
    // UI while the SDK initializes.
    if (!auth.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Inicialitzar NotificationProvider quan l'usuari està autenticat
    if (auth.isAuthenticated && auth.currentUserUid != null) {
      debugPrint('[AuthWrapper] build - Autenticat! UID: ${auth.currentUserUid}');
      notificationProvider.initialize(auth.currentUserUid!);
    }

    // If auth is initialized, decide between Login and Home. RequireAuth will
    // protect Home routes; AuthWrapper only chooses which initial page to show.
    if (!auth.isAuthenticated) return const LoginPage();
    return const HomePage();
  }
}
