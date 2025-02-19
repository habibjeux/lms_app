import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../../splash_screen.dart';
import '../../providers/auth_provider.dart';

class AuthWrapperFirst extends StatelessWidget {
  const AuthWrapperFirst({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (authProvider.isAuthenticated) {
      return DashboardScreen();
    } else {
      return SplashScreen();
    }
  }
}
