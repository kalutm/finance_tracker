// accounts/presentation/widgets/account_failure_dialog.dart

import 'package:flutter/material.dart';

class AccountFailureDialog extends StatelessWidget {
  final String message;

  const AccountFailureDialog({
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Text(
            'Operation Failed',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              'An error occurred during the account operation:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your input or network connection and try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(178),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('OK', style: TextStyle(color: theme.colorScheme.primary)),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}