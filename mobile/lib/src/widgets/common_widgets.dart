import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class FlowlyIconButton extends StatelessWidget {
  const FlowlyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.selected = false,
    this.size = 46,
    this.iconSize = 24,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool selected;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size >= 60 ? 22 : 16);

    return Tooltip(
      message: tooltip ?? '',
      child: FlowlyGlass(
        borderRadius: radius,
        tint: selected
            ? FlowlyColors.primarySoft.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.72),
        borderColor: Colors.white.withValues(alpha: 0.88),
        blur: 22,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: iconSize,
                color: selected ? FlowlyColors.primary : FlowlyColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FlowlyGlass(
      width: double.infinity,
      tint: Colors.white.withValues(alpha: 0.78),
      borderColor: Colors.white.withValues(alpha: 0.90),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class FlowlyGlass extends StatelessWidget {
  const FlowlyGlass({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.tint,
    this.borderColor,
    this.blur = 22,
    this.shadows,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? tint;
  final Color? borderColor;
  final double blur;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final dark = isFlowlyDark(context);
    final effectiveTint = _glassTintColor(tint, darkMode: dark);
    final effectiveBorderColor = _glassBorderColor(borderColor, darkMode: dark);
    final effectiveShadows = _glassShadows(shadows, darkMode: dark);
    final gradientColors = dark
        ? [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
            FlowlyColors.primary.withValues(alpha: 0.05),
          ]
        : [
            Colors.white.withValues(alpha: 0.46),
            Colors.white.withValues(alpha: 0.13),
            FlowlyColors.primary.withValues(alpha: 0.045),
          ];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: effectiveTint,
              borderRadius: radius,
              border: Border.all(color: effectiveBorderColor, width: 1),
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(padding: padding ?? EdgeInsets.zero, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _glassTintColor(Color? color, {required bool darkMode}) {
  final source = color ?? Colors.white.withValues(alpha: 0.76);
  if (!darkMode) return source;
  if (_isBrightColor(source)) return FlowlyColors.darkNeutralCard;
  return source;
}

Color _glassBorderColor(Color? color, {required bool darkMode}) {
  final fallback = Colors.white.withValues(alpha: 0.86);
  final source = color ?? fallback;
  if (!darkMode) return source;
  if (_isBrightColor(source)) {
    return FlowlyColors.darkNeutralBorder.withValues(alpha: 0.78);
  }
  return source.withValues(alpha: source.a.clamp(0.0, 0.46));
}

List<BoxShadow> _glassShadows(
  List<BoxShadow>? shadows, {
  required bool darkMode,
}) {
  if (!darkMode) {
    return shadows ?? _lightGlassShadows;
  }
  if (shadows != null && shadows.isEmpty) return shadows;
  if (shadows != null) return shadows.map(_darkenShadow).toList();
  return _darkGlassShadows;
}

BoxShadow _darkenShadow(BoxShadow shadow) {
  if (_isBrightColor(shadow.color)) {
    return shadow.copyWith(
      color: FlowlyColors.primary.withValues(alpha: 0.06),
      blurRadius: shadow.blurRadius * 0.7,
    );
  }

  final alpha = shadow.color.a.clamp(0.0, 0.22);
  return shadow.copyWith(color: shadow.color.withValues(alpha: alpha));
}

bool _isBrightColor(Color color) {
  return color.r > 0.72 && color.g > 0.72 && color.b > 0.72;
}

final _lightGlassShadows = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.055),
    blurRadius: 24,
    offset: const Offset(0, 12),
  ),
  BoxShadow(
    color: FlowlyColors.primary.withValues(alpha: 0.05),
    blurRadius: 26,
    offset: const Offset(0, 10),
  ),
  BoxShadow(
    color: Colors.white.withValues(alpha: 0.38),
    blurRadius: 12,
    offset: const Offset(-5, -5),
  ),
];

final _darkGlassShadows = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.24),
    blurRadius: 24,
    offset: const Offset(0, 12),
  ),
  BoxShadow(
    color: FlowlyColors.primary.withValues(alpha: 0.08),
    blurRadius: 28,
    offset: const Offset(0, 10),
  ),
];

class FlowlySnack {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
