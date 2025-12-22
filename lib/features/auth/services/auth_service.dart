import 'package:flutter/foundation.dart';
import 'dart:io' show Platform, Socket;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;
  // resolved emulator host used for emulator wiring (10.0.2.2 on Android, 127.0.0.1 otherwise)
  String _emulatorHost = '127.0.0.1';
  // Whether we're using emulators (for skipping connectivity checks in production)
  bool _usingEmulators = false;

  AuthService({
    required this.auth,
    required this.firestore,
    required this.functions,
  }) {
    // [Constitució] Apuntar als emuladors en mode debug (si USE_EMULATORS=true)
    // Use --dart-define=USE_EMULATORS=false to use production Firebase in debug mode
    const useEmulators = bool.fromEnvironment(
      'USE_EMULATORS',
      defaultValue: true,
    );
    if (kDebugMode && useEmulators) {
      _usingEmulators = true;
      try {
        // When running on Android emulator, use 10.0.2.2 to reach host machine.
        // On iOS simulator or desktop, localhost (127.0.0.1) works.
        String host = '127.0.0.1';
        if (!kIsWeb) {
          try {
            if (Platform.isAndroid) {
              host = '10.0.2.2';
            }
          } catch (_) {
            // If Platform check fails for any reason, fall back to localhost
            host = '127.0.0.1';
          }
        }

        // Ports are aligned with `firebase.json` (auth:9198, firestore:8088, functions:5001)
        auth.useAuthEmulator(host, 9198);
        firestore.useFirestoreEmulator(host, 8088);
        functions.useFunctionsEmulator(host, 5001);
        _emulatorHost = host;
        debugPrint(
          'Firebase Emulators configured for debug mode. (host=$host)',
        );
      } catch (e) {
        debugPrint(
          'Warning: Could not configure Firebase Emulators. They might be already set. Error: $e',
        );
      }
    } else if (kDebugMode) {
      debugPrint('Debug mode: using PRODUCTION Firebase (USE_EMULATORS=false)');
    }
  }

  /// If running in a non-production VM (e.g. debug/emulator), clear any
  /// existing FirebaseAuth session to ensure a clean state for local testing.
  /// Uses a simple environment-based heuristic to detect non-production.
  Future<void> clearAuthIfEmulator() async {
    // Avoid using bool.fromEnvironment at runtime (not supported on web/DDC).
    // Use Flutter compile-time constants instead: consider non-release builds
    // (debug/profile) as emulator/test environments.
    final isEmulator = !kReleaseMode;
    if (!isEmulator) return;
    try {
      await auth.signOut();
      debugPrint('🔄 Sessió FirebaseAuth netejada (emulador)');
    } catch (e) {
      debugPrint('Error signing out during emulator init: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Mètodes del Flux de Registre Manual (3 Passos + Comprovació)
  // -------------------------------------------------------------------------

  /// PAS 1: Verifica la llicència contra el registre.
  Future<Map<String, dynamic>> lookupLicense(String licenseId) async {
    final callable = functions.httpsCallable(
      'lookupLicense',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 60), // Timeout més alt per cold start
      ),
    );
    try {
      // In debug with emulators, do a quick TCP check to the Functions emulator to provide
      // an earlier, clearer diagnostic if the emulator isn't reachable.
      // Skip this check when using production Firebase.
      if (kDebugMode && _usingEmulators) {
        try {
          final reachable = await _isHostReachable(_emulatorHost, 5001);
          debugPrint(
            'Functions emulator reachable: $reachable ($_emulatorHost:5001)',
          );
          if (!reachable) {
            throw Exception(
              'Functions emulator not reachable at $_emulatorHost:5001',
            );
          }
        } catch (e) {
          debugPrint('Connectivity check to Functions emulator failed: $e');
          // continue — callable.call will still attempt and surface the error
        }
      }
      final result = await callable.call<Map<String, dynamic>>({
        'llissenciaId': licenseId,
      });
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Functions Exception on lookupLicense: ${e.code} - ${e.message}',
      );
      throw Exception(e.message ?? "Error en verificar la llicència.");
    } catch (e) {
      debugPrint('Generic Exception in lookupLicense: $e');
      throw Exception("Error inesperat durant la verificació de la llicència.");
    }
  }

  /// PAS 2: Envia la sol·licitud de registre per a aprovació manual.
  Future<Map<String, dynamic>> requestRegistration({
    required String llissenciaId,
    required String email,
    required String gender,
  }) async {
    // The email reservation is now handled entirely by the Cloud Function
    // `requestRegistration` which uses Admin SDK and can write to `emails/*`.
    // This avoids permission issues since security rules block client writes.
    final callable = functions.httpsCallable(
      'requestRegistration',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 60), // Timeout més alt per cold start
      ),
    );
    final emailLower = email.trim().toLowerCase();

    try {
      // Call the backend function to check email uniqueness and submit the
      // registration request. The function handles email reservation.
      final result = await callable.call<Map<String, dynamic>>({
        'llissenciaId': llissenciaId,
        'email': emailLower,
        'gender': gender,
      });
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Functions Exception on requestRegistration: ${e.code} - ${e.message}',
      );
      // Check for email already in use error from the function
      if (e.code == 'already-exists' ||
          (e.message?.contains('email') ?? false)) {
        throw Exception('emailAlreadyInUse');
      }
      throw Exception(
        e.message ?? "Error en enviar la sol·licitud de registre.",
      );
    } on Exception catch (e) {
      debugPrint('Generic Exception in requestRegistration: $e');
      throw Exception("Error inesperat en enviar la sol·licitud de registre.");
    }
  }

  /// PAS 3: Completa el registre creant l'usuari (després d'aprovació manual).
  Future<Map<String, dynamic>> completeRegistration({
    required String llissenciaId,
    required String email,
    required String password,
  }) async {
    final callable = functions.httpsCallable('completeRegistration');
    try {
      final result = await callable.call<Map<String, dynamic>>({
        'llissenciaId': llissenciaId,
        'email': email,
        'password': password,
      });
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Functions Exception on completeRegistration: ${e.code} - ${e.message}',
      );
      // Proporcionem missatges més específics segons el tipus d'error
      switch (e.code) {
        case 'deadline-exceeded':
          throw Exception(
            "La sol·licitud ha trigat massa temps. Torna-ho a provar.",
          );
        case 'unavailable':
          throw Exception(
            "El servei no està disponible temporalment. Torna-ho a provar.",
          );
        case 'internal':
          throw Exception(
            "Error intern del servidor. Contacta amb suport si persisteix.",
          );
        default:
          throw Exception(e.message ?? "Error en completar el registre.");
      }
    } catch (e) {
      debugPrint('Generic Exception in completeRegistration: $e');
      throw Exception(
        "Error inesperat en completar el registre. Verifica la connexió a internet.",
      );
    }
  }

  /// [NOU] COMPROVACIÓ AUXILIAR: Verifica si un email té una sol·licitud aprovada.
  /// Crida a la Cloud Function 'checkRegistrationStatus'.
  ///
  /// Retorna un Map { isApproved: bool, licenseId: string? }.
  /// Llença [Exception] si hi ha un error en la crida a la funció.
  Future<Map<String, dynamic>> checkApprovedStatus(String email) async {
    final callable = functions.httpsCallable('checkRegistrationStatus');
    try {
      final result = await callable.call<Map<String, dynamic>>({
        'email': email,
      });
      // El backend retorna { isApproved: bool, licenseId: string? }
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Functions Exception on checkRegistrationStatus: ${e.code} - ${e.message}',
      );
      // No llencem l'error del backend directament, ja que "not found" no és un error aquí.
      // Retornem un estat indicant no aprovat si hi ha error. Podríem ser més específics.
      // throw Exception("Error comprovant l'estat del registre: ${e.message}");
      // Alternativa: retornar un estat que indiqui l'error
      return {'isApproved': false, 'licenseId': null, 'error': e.message};
    } catch (e) {
      debugPrint('Generic Exception in checkApprovedStatus: $e');
      // throw Exception("Error inesperat comprovant l'estat del registre.");
      return {
        'isApproved': false,
        'licenseId': null,
        'error': 'Error inesperat',
      };
    }
  }

  // -------------------------------------------------------------------------
  // Mètodes d'Autenticació Existents
  // -------------------------------------------------------------------------

  /// Inicia sessió amb email i contrasenya (per a usuaris existents).
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth Exception on signIn: ${e.code} - ${e.message}');
      // Important: Rellença FirebaseAuthException perquè AuthProvider pugui llegir el 'code'
      rethrow; // <--- CORREGIT AMB rethrow
      // throw Exception(e.message ?? "Error en iniciar sessió."); // <-- Canviat per rellençar l'original
    } catch (e) {
      debugPrint('Generic Exception in signInWithEmail: $e');
      throw Exception("Error inesperat durant l'inici de sessió.");
    }
  }

  /// Tanca la sessió de l'usuari actual.
  Future<void> signOut() async {
    try {
      await auth.signOut();
      debugPrint('User signed out successfully.');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Stream per escoltar els canvis d'estat d'autenticació (usuari connectat/desconnectat).
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Envia un correu de restabliment de contrasenya a través de la Cloud Function sendPasswordResetEmail.
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint(
      '🔵 [sendPasswordResetEmail] START - Attempting to send password reset email',
    );
    debugPrint('🔵 [sendPasswordResetEmail] Email: $email');
    debugPrint(
      '🔵 [sendPasswordResetEmail] Functions instance: ${functions.toString()}',
    );

    final callable = functions.httpsCallable('sendPasswordResetEmail');
    debugPrint('🔵 [sendPasswordResetEmail] Callable created successfully');

    try {
      debugPrint('🔵 [sendPasswordResetEmail] Calling Cloud Function...');
      final result = await callable.call<Map<String, dynamic>>({
        'email': email.trim().toLowerCase(),
      });
      debugPrint(
        '🟢 [sendPasswordResetEmail] SUCCESS - Function returned: ${result.data}',
      );
      return;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '🔴 [sendPasswordResetEmail] FirebaseFunctionsException caught!',
      );
      debugPrint('🔴 [sendPasswordResetEmail] Code: ${e.code}');
      debugPrint('🔴 [sendPasswordResetEmail] Message: ${e.message}');
      debugPrint('🔴 [sendPasswordResetEmail] Details: ${e.details}');
      debugPrint('🔴 [sendPasswordResetEmail] Stack trace: ${e.stackTrace}');
      throw Exception(
        e.message ??
            "No s'ha pogut enviar el correu de restabliment de contrasenya.",
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 [sendPasswordResetEmail] Generic Exception caught!');
      debugPrint('🔴 [sendPasswordResetEmail] Exception: $e');
      debugPrint('🔴 [sendPasswordResetEmail] Stack trace: $stackTrace');
      throw Exception(
        "Error inesperat en enviar el correu de restabliment de contrasenya.",
      );
    }
  }
}

// -----------------------------------------------------------------------------
// Helpers (placed outside the class to keep AuthService focused)
// -----------------------------------------------------------------------------
/// Small helper to check TCP connectivity to host:port (used only for diagnostics)
Future<bool> _isHostReachable(String host, int port) async {
  try {
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 2),
    );
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}
