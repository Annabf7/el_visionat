import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService authService;

  AuthProvider({required this.authService});

  bool _isLoading = false;
  String? _errorMessage;
  bool _isLicenseVerified = false;
  Map<String, dynamic>? _verifiedUserData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLicenseVerified => _isLicenseVerified;
  Map<String, dynamic>? get verifiedUserData => _verifiedUserData;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  /// Verifies a license ID by calling the auth service.
  /// Returns true on success, false on failure.
  Future<bool> verifyLicense(String licenseId) async {
    _setLoading(true);
    _setError(null);
    try {
      final userData = await authService.lookupLicense(licenseId);
      _verifiedUserData = userData;
      _isLicenseVerified = true;
      _setLoading(false);
      notifyListeners(); // Final notification after all state changes
      return true;
    } on Exception catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Signs in a user with email and password.
  /// Returns true on success, false on failure.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await authService.signInWithEmail(email, password);
      _setLoading(false);
      return true;
    } on Exception catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Resets the provider state to its initial values.
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _isLicenseVerified = false;
    _verifiedUserData = null;
    notifyListeners();
  }
}
