import 'package:flutter/material.dart';

class LoginFormProvider with ChangeNotifier {
  bool _isPasswordVisible = false;

  bool get isPasswordVisible => _isPasswordVisible;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void resetState() {
    _isPasswordVisible = false;
    notifyListeners();
  }
}
