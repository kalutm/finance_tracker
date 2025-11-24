import 'dart:io';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:finance_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:finance_frontend/features/auth/presentation/cubits/auth_state.dart';
import 'package:finance_frontend/features/auth/presentation/views/first_auth_wrappr.dart';
import 'package:finance_frontend/features/auth/presentation/views/home_view.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_bloc.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final systemOverlayStyle =
        theme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            )
            : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: BlocConsumer<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => AccountsBloc(ref.read(accountServiceProvider)),
                ),
                BlocProvider(
                  create: (context) => TransactionsBloc(ref.read(transactionServiceProvider)),
                ),
                BlocProvider(
                  create:
                      (context) => TransactionFormBloc(ref.read(transactionServiceProvider)),
                ),
                BlocProvider(
                  create: (context) => CategoriesBloc(ref.read(categoryServiceProvider)),
                ),
              ],
              child: const Home(),
            );
          } else if (state is AuthNeedsVerification) {
            return FirstAuthWrappr(toVerify: true, email: state.email);
          } else if (state is Unauthenticated) {
            return FirstAuthWrappr(toVerify: false);
          } else {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  padding: EdgeInsets.all(20),
                ),
              ),
            );
          }
        },
        listener: (context, state) {
          if (state is AuthError) {
            if (state.exception is CouldnotLoadUser) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Couldnot Load User please log in agian"),
                ),
              );
            } else if (state.exception is CouldnotGetUser) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Couldnot get User Cridentials please try again later",
                  ),
                ),
              );
            } else if (state.exception is CouldnotLogIn) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Login Failed: ${state.exception.toString()}",
                  ),
                ),
              );
            } else if (state.exception is CouldnotRegister) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Register Failed: ${state.exception.toString()}",
                  ),
                ),
              );
            } else if (state.exception is CouldnotLogInWithGoogle) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Couldnot login with google please try again later",
                  ),
                ),
              );
            } else if (state.exception
                is CouldnotSendEmailVerificatonLink) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Couldnot send Email verification: ${state.exception.toString()}",
                  ),
                ),
              );
            } else if (state.exception is NoUserToDelete) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "No user to delete or some unexpected problem try reinstalling then deleting again",
                  ),
                ),
              );
            } else if (state.exception is CouldnotDeleteUser) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Couldnot delete user please try again later",
                  ),
                ),
              );
            } else if (state.exception is SocketException) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "No Internet connection!, please try connecting to the internet",
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.exception.toString())),
              );
            }
          }
        },
      ),
    );
  }
}
