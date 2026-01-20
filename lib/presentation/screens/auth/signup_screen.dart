import 'package:flutter/material.dart';

import 'signup/signup_flow_screen.dart';

/// SignupScreen now redirects to the multi-step SignupFlowScreen.
/// This wrapper exists for backward compatibility with existing navigation.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignupFlowScreen();
  }
}
