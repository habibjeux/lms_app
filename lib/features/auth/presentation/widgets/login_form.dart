import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/login_form_provider.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
  });

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: emailController,
            label: 'Email',
            hint: 'Entrez votre email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Consumer<LoginFormProvider>(
            builder: (context, formProvider, _) {
              return CustomTextField(
                controller: passwordController,
                label: 'Mot de passe',
                hint: 'Entrez votre mot de passe',
                prefixIcon: Icons.lock_outline,
                obscureText: !formProvider.isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    formProvider.isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    formProvider.togglePasswordVisibility();
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return PrimaryButton(
                onPressed: auth.isLoading ? null : () => _handleLogin(context),
                child: auth.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Se connecter'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleLogin(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthProvider>().login(
            emailController.text,
            passwordController.text,
          );
    }
  }
}
