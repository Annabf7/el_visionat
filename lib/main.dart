import 'package:el_visionat/firebase_options.dart';
import 'package:el_visionat/screens/home_page.dart';
import 'package:el_visionat/theme/app_theme.dart';
import 'package:el_visionat/providers/home_provider.dart'; // ÚS CORRECTE
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      // Declara el Provider només aquí!
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        // Aquí afegiríem altres providers com AuthProvider, etc.
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Quan l'app comença aquí, el HomeProvider ja existeix i és accessible per a tots els widgets
    return MaterialApp(
      title: 'El Visionat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomePage(),
    );
  }
}
