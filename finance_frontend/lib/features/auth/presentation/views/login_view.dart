import 'package:finance_frontend/features/auth/presentation/components/auth_field.dart';
import 'package:finance_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginView extends StatefulWidget {
  final void Function() toogleLogin;
  const LoginView({super.key, required this.toogleLogin});


  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- App Teaser ---
                Text(
                  'FinTrackr',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Personal Finance, Simplified.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                ),
                const SizedBox(height: 48),

                // --- Login Form ---
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AuthField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      AuthField(
                        controller: _passwordController,
                        hintText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Login Button ---
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('LOGIN'),
                ),
                const SizedBox(height: 24),

                // --- Helper Actions: Register & Verification ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => widget.toogleLogin(),
                      child: Text('REGISTER', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // --- "OR" Separator ---
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('OR', style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Google Login Button ---
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthCubit>().loginWithGoogle();
                  },
                  icon: Image.asset('assets/google_logo.png', height: 20.0),
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
