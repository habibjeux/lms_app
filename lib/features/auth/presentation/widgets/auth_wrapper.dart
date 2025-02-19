import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isAuthenticated) {
      return DashboardScreen();
    } else {
      return LoginScreen();
    }
  }
}
