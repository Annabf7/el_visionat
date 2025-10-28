import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  AuthService({
    required this.auth,
    required this.firestore,
    required this.functions,
  }) {
    // [Constitució] Apuntar als emuladors en mode debug
    if (kDebugMode) {
      try {
        auth.useAuthEmulator('127.0.0.1', 9099);
        firestore.useFirestoreEmulator('127.0.0.1', 8080);
        functions.useFunctionsEmulator('127.0.0.1', 5001);
        debugPrint('Firebase Emulators configured for debug mode.');
      } catch (e) {
        debugPrint(
          'Warning: Could not configure Firebase Emulators. They might be already set. Error: $e',
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // Mètodes del Flux de Registre Manual (3 Passos + Comprovació)
  // -------------------------------------------------------------------------

  /// PAS 1: Verifica la llicència contra el registre.
  Future<Map<String, dynamic>> lookupLicense(String licenseId) async {
    final callable = functions.httpsCallable('lookupLicense');
    try {
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
  }) async {
    final callable = functions.httpsCallable('requestRegistration');
    try {
      final result = await callable.call<Map<String, dynamic>>({
        'llissenciaId': llissenciaId,
        'email': email,
      });
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Functions Exception on requestRegistration: ${e.code} - ${e.message}',
      );
      throw Exception(
        e.message ?? "Error en enviar la sol·licitud de registre.",
      );
    } catch (e) {
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
      throw Exception(e.message ?? "Error en completar el registre.");
    } catch (e) {
      debugPrint('Generic Exception in completeRegistration: $e');
      throw Exception("Error inesperat en completar el registre.");
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
}
