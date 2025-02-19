import 'package:flutter/material.dart';
import '../../../core/exceptions/app_exception.dart';
import '../data/auth_repository.dart';
import '../models/user.dart';
import '../../../core/services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final StorageService _storage = StorageService();

  bool _isLoading = false;
  String? _error;
  User? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _setLoading(true);
    await _loadUserAndToken();
    _setLoading(false);
  }

  Future<void> _loadUserAndToken() async {
    final token = await _storage.getToken();
    final userData = await _storage.getUser();

    if (token != null && userData != null) {
      _user = User.fromJson(userData);
      _authRepository.initializeToken();
    }
  }

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

  Future<void> logout() async {
    _user = null;
    await _authRepository.logout();
    notifyListeners();
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
}
