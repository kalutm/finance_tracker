import 'package:finance_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final bool isDelete;
  const ConfirmationDialog({super.key, required this.title, required this.content, required this.isDelete});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
          title: Text(title),
          content: Text(
            content
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                isDelete ? context.read<AuthCubit>().deleteCurrentUser() : context.read<AuthCubit>().logOut();
              },
              child: Text(isDelete ? "Delete" : "Logout"),
            ),
          ],
        );
      }
}