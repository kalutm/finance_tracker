import 'package:finance_frontend/features/auth/presentation/views/login_view.dart';
import 'package:finance_frontend/features/auth/presentation/views/register_view.dart';
import 'package:flutter/material.dart';

class SecondAuthWrapper extends StatefulWidget {
  final void Function() toogleView;
  const SecondAuthWrapper({super.key, required this.toogleView});

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
      return LoginView(toogleLogin: toogleView, toogleView: widget.toogleView,);
    } else{
      return RegisterView(toogleLogin: toogleView);
    }
  }
}