import 'dart:async';

import 'package:flutter/material.dart';

class VerificationView extends StatefulWidget {
  final void Function() toogleView;
  const VerificationView({super.key, required this.toogleView});

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  late Timer _timer;
  int _secondsRemaining = 60;
  bool _isResending = false;


  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Starts the countdown timer for the resend button.
  void _startTimer() {
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isResendButtonEnabled = _secondsRemaining == 0 && !_isResending;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Teaser/Logo
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 80.0,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Finance Tracker',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 48),

              // Main Message
              Text(
                'Verify Your Email Address',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'A verification link has been sent to your email. Please click the link to confirm your account.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Resend Button
              if (_isResending)
                const CircularProgressIndicator()
              else
                TextButton(
                  onPressed: isResendButtonEnabled ? null : null,
                  child: Text(
                    isResendButtonEnabled
                        ? 'Resend Verification Link'
                        : 'Resend in $_secondsRemaining s',
                    style: TextStyle(
                      color: isResendButtonEnabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withAlpha(102),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Log Out Button
              TextButton(
                onPressed: () => widget.toogleView(),
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}