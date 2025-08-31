import 'package:finance_frontend/features/auth/presentation/views/second_auth_wrapper.dart';
import 'package:finance_frontend/features/auth/presentation/views/verification_view.dart';
import 'package:flutter/material.dart';

class FirstAuthWrappr extends StatefulWidget {
  final bool toVerify;
  const FirstAuthWrappr({super.key, required this.toVerify});

  @override
  State<FirstAuthWrappr> createState() => _FirstAuthWrapprState();
}

class _FirstAuthWrapprState extends State<FirstAuthWrappr> {
  late bool showVerificationView;

  @override
  initState(){
    showVerificationView = widget.toVerify;
    super.initState();
  }
  

  void toogleView(){
    setState(() {
      showVerificationView = !showVerificationView;
    });
  }
  @override
  Widget build(BuildContext context) {
    if(showVerificationView){
      return VerificationView(toogleView: toogleView,);
    } else {
      return SecondAuthWrapper(toogleView: toogleView);
    }
  }
}