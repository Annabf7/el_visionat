import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importem per als codis d'error

/// Defineix els diferents passos del procés de registre manual.
enum RegistrationStep {
  initial, // Estat inicial, abans de verificar la llicència
  licenseLookup, // Verificant la llicència
  licenseVerified, // Llicència verificada, mostrant dades, esperant email
  requestingRegistration, // Enviant la sol·licitud d'aprovació
  requestSent, // Sol·licitud enviada, esperant aprovació manual
  approvedNeedPassword, // [NOU] Detectat aprovat durant login, redirigir a crear contrasenya
  completingRegistration, // Enviant contrasenya per finalitzar
  registrationComplete, // Registre completat amb èxit
  error, // Hi ha hagut un error en algun pas
}

class AuthProvider with ChangeNotifier {
  final AuthService authService;

  AuthProvider({required this.authService});

  // --- Estats Generals ---
  bool _isLoading = false;
  String? _errorMessage;
  RegistrationStep _currentStep = RegistrationStep.initial;

  // --- Estats Específics del Registre ---
  Map<String, dynamic>? _verifiedLicenseData;
  String? _pendingLicenseId;
  String? _pendingEmail;

  // --- Getters Públics ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RegistrationStep get currentStep => _currentStep;
  Map<String, dynamic>? get verifiedLicenseData => _verifiedLicenseData;
  String? get pendingLicenseId => _pendingLicenseId;
  String? get pendingEmail => _pendingEmail;

  // --- Mètodes Privats per Gestionar Estat ---
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
    }
  }

  void _setError(
    String? message, {
    bool notify = true,
    RegistrationStep? errorStep,
  }) {
    _errorMessage = message;
    // Si no especifiquem un pas d'error, per defecte anem a 'error'.
    // Si ho especifiquem (ex: durant login), mantenim el pas actual o anem a 'initial'.
    _currentStep = errorStep ?? RegistrationStep.error;
    _isLoading = false;
    if (notify) notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }

  // --- Mètodes Públics per a les Accions ---

  /// PAS 1: Verifica la llicència ID.
  Future<void> verifyLicense(String licenseId) async {
    _setLoading(true);
    _clearError();
    _currentStep = RegistrationStep.licenseLookup;
    notifyListeners();

    try {
      final data = await authService.lookupLicense(licenseId);
      _verifiedLicenseData = data;
      _pendingLicenseId = licenseId;
      _currentStep = RegistrationStep.licenseVerified;
      _setLoading(false);
      notifyListeners();
    } on Exception catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''), notify: true);
    }
  }

  /// PAS 2: Envia la sol·licitud de registre amb l'email.
  Future<void> submitRegistrationRequest(String email) async {
    if (_currentStep != RegistrationStep.licenseVerified ||
        _pendingLicenseId == null) {
      _setError("Estat invàlid per enviar la sol·licitud.", notify: true);
      return;
    }
    _setLoading(true);
    _clearError();
    _currentStep = RegistrationStep.requestingRegistration;
    notifyListeners();

    try {
      await authService.requestRegistration(
        llissenciaId: _pendingLicenseId!,
        email: email,
      );
      _pendingEmail = email;
      _currentStep = RegistrationStep.requestSent;
      _setLoading(false);
      notifyListeners();
    } on Exception catch (e) {
      if (!e.toString().contains('already-exists')) {
        _currentStep = RegistrationStep.licenseVerified;
      }
      _setError(e.toString().replaceFirst('Exception: ', ''), notify: true);
    }
  }

  /// PAS 3: Completa el registre amb la contrasenya (després d'aprovació manual).
  Future<void> completeRegistrationProcess(String password) async {
    // Ara agafem licenseId i email de les variables pending guardades
    if (_pendingLicenseId == null || _pendingEmail == null) {
      _setError(
        "Falten dades (llicència/email) per completar.",
        notify: true,
        errorStep: RegistrationStep.initial,
      );
      return;
    }

    _setLoading(true);
    _clearError();
    _currentStep = RegistrationStep.completingRegistration;
    notifyListeners();

    try {
      await authService.completeRegistration(
        llissenciaId: _pendingLicenseId!,
        email: _pendingEmail!,
        password: password,
      );
      _currentStep =
          RegistrationStep.registrationComplete; // L'usuari ara està logat
      _setLoading(false);
      // No fem reset aquí, deixem que authStateChanges gestioni la navegació
      notifyListeners();
    } on Exception catch (e) {
      // Si hi ha error aquí, probablement l'usuari haurà de tornar a començar o contactar suport.
      _setError(
        e.toString().replaceFirst('Exception: ', ''),
        notify: true,
        errorStep: RegistrationStep.error,
      ); // Error final
    }
  }

  /// Inicia sessió amb email i contrasenya.
  /// Si falla, comprova si hi ha una sol·licitud aprovada per redirigir a crear contrasenya.
  Future<RegistrationStep> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    _currentStep = RegistrationStep.initial; // Estat per a login normal
    notifyListeners();

    try {
      // 1. Intentem iniciar sessió normalment
      await authService.signInWithEmail(email, password);
      _setLoading(false);
      notifyListeners(); // Notifica isLoading = false
      // Si el login és correcte, l'estat de l'usuari canviarà a Firebase
      // i l'AuthWrapper redirigirà a /home. Retornem l'estat actual.
      return _currentStep;
    } on FirebaseAuthException catch (e) {
      // Si el login falla, comprovem si és perquè l'usuari està aprovat però no registrat
      final relevantErrorCodes = [
        'user-not-found',
        'wrong-password',
        'invalid-credential',
      ];
      if (email.isNotEmpty && relevantErrorCodes.contains(e.code)) {
        try {
          final result = await authService.checkApprovedStatus(email);
          if (result['isApproved'] == true && result['licenseId'] != null) {
            _pendingEmail = email;
            _pendingLicenseId = result['licenseId'];
            _currentStep = RegistrationStep.approvedNeedPassword;
            _setLoading(false);
            notifyListeners();
            return _currentStep; // Retornem el pas clau per a la navegació
          }
        } catch (checkError) {
          // Si la comprovació falla, continuem per mostrar l'error de login original
          debugPrint("Error checking registration status: $checkError");
        }
      }

      // Si hem arribat aquí, és un error de login estàndard.
      _setError(
        e.message ?? "L'usuari o la contrasenya són incorrectes.",
        notify: false,
        errorStep: RegistrationStep.initial,
      );
      _setLoading(false);
      notifyListeners();
      return _currentStep; // Retornem 'initial' o 'error'

    } on Exception catch (e) {
      // Captura genèrica per a altres errors
      _setError(
        e.toString().replaceFirst('Exception: ', ''),
        notify: false,
        errorStep: RegistrationStep.initial,
      );
      _setLoading(false);
      notifyListeners();
      return _currentStep;
    }
  }

  /// Tanca la sessió de l'usuari actual.
  Future<void> signOut() async {
    await authService.signOut();
    reset();
  }

  /// Restaura l'estat inicial del provider.
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _currentStep = RegistrationStep.initial;
    _verifiedLicenseData = null;
    _pendingLicenseId = null;
    _pendingEmail = null;
    notifyListeners();
  }
}
