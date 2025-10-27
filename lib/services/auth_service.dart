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
    if (kDebugMode) {
      try {
        auth.useAuthEmulator('localhost', 9099);
        firestore.useFirestoreEmulator('localhost', 8080);
        functions.useFunctionsEmulator('localhost', 5001);
        debugPrint('Firebase Emulators configured for debug mode.');
      } catch (e) {
        // This can happen if the emulators are already configured, for example during hot restart.
        debugPrint(
          'Warning: Could not configure Firebase Emulators. They might be already set. Error: $e',
        );
      }
    }
  }

  /// Calls the 'lookupLicense' Cloud Function to verify a license ID.
  ///
  /// Throws a [FirebaseFunctionsException] if the license is not found,
  /// already exists, or another function-related error occurs.
  Future<Map<String, dynamic>> lookupLicense(String licenseId) async {
    try {
      final callable = functions.httpsCallable('lookupLicense');
      final result = await callable.call<Map<String, dynamic>>({
        'licenseId': licenseId,
      });
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Functions Exception on lookupLicense: ${e.code} - ${e.message}',
      );
      // Re-throw the exception with a user-friendly message contained within it.
      throw Exception(e.message ?? "Error al verificar la llicència.");
    } catch (e) {
      debugPrint('Generic Exception in lookupLicense: $e');
      throw Exception(
        "Ha ocorregut un error inesperat durant la verificació de la llicència.",
      );
    }
  }

  /// Signs in a user with their email and password.
  ///
  /// Throws a [FirebaseAuthException] for authentication-related errors.
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth Exception on signIn: ${e.code} - ${e.message}');
      throw Exception(
        e.message ?? "Ha ocorregut un error d'autenticació desconegut.",
      );
    } catch (e) {
      debugPrint('Generic Exception in signInWithEmail: $e');
      throw Exception(
        "Ha ocorregut un error inesperat durant l'inici de sessió.",
      );
    }
  }

  // Future<void> requestEmailVerification(...) will be implemented in the next task.
  // Future<void> completeRegistration(...) will be implemented in the next task.
}
