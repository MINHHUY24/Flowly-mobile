import 'package:flutter/material.dart';

class FlowlyLogo extends StatelessWidget {
  const FlowlyLogo({super.key, this.height = 42, this.iconOnly = false});

  final double height;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      iconOnly ? 'assets/images/logo_no_word.png' : 'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
