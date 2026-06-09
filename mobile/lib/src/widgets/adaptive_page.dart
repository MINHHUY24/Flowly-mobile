import 'package:flutter/material.dart';

class AdaptivePage extends StatelessWidget {
  const AdaptivePage({
    super.key,
    required this.child,
    this.maxWidth = 980,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 700 ? 28.0 : 22.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ?? EdgeInsets.fromLTRB(horizontal, 18, horizontal, 94),
          child: child,
        ),
      ),
    );
  }
}
