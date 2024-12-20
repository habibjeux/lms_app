import 'package:flutter/material.dart';
import '../../../core/exceptions/app_exception.dart';
import '../data/auth_repository.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  String? _error;
  User? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      _user = await _authRepository.login(email, password);
      _clearError();
    } on AppException catch (e) {
      _user = null;
      _setError(e.toString());
    } catch (e) {
      _user = null;
      _setError('Une erreur inattendue est survenue');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> logout() {
    _user = null;
    notifyListeners();
    return _authRepository.logout();
  }
}
