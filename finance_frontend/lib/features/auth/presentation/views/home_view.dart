import 'package:finance_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          PopupMenuButton(itemBuilder: (context) {
            return [
              PopupMenuItem(
                onTap: () => context.read<AuthCubit>().logOut(),
                child: Icon(Icons.exit_to_app),
                ),
                PopupMenuItem(
                onTap: () => context.read<AuthCubit>().deleteCurrentUser(),
                child: Icon(Icons.delete_forever),
                ),
            ];
          },)
          
        ],
      ),
      body: Text("Authenticated"),
    );
  }
}