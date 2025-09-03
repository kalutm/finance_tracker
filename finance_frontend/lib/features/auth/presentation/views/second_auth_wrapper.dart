import 'package:finance_frontend/features/auth/presentation/views/login_view.dart';
import 'package:finance_frontend/features/auth/presentation/views/register_view.dart';
import 'package:flutter/material.dart';

class SecondAuthWrapper extends StatefulWidget {
  const SecondAuthWrapper({super.key});

  @override
  State<SecondAuthWrapper> createState() => _SecondAuthWrapperState();
}

class _SecondAuthWrapperState extends State<SecondAuthWrapper> {

  bool showLogin = true;

  void toogleView(){
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLogin) {
      return LoginView(toogleLogin: toogleView);
    } else{
      return RegisterView(toogleLogin: toogleView);
    }
  }
}