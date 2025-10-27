import 'package:el_visionat/firebase_options.dart';
import 'package:el_visionat/providers/auth_provider.dart';
import 'package:el_visionat/screens/home_page.dart';
import 'package:el_visionat/services/auth_service.dart';
import 'package:el_visionat/theme/app_theme.dart';
import 'package:el_visionat/providers/home_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        // Registrem el AuthProvider per a que estigui disponible a tota l'app
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: AuthService(
              auth: FirebaseAuth.instance,
              firestore: FirebaseFirestore.instance,
              functions: FirebaseFunctions.instance,
            ),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Visionat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // Mantenim HomePage com la pàgina d'inici
      home: const HomePage(),
    );
  }
}