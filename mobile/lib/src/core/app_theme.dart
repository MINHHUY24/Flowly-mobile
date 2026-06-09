import 'package:flutter/material.dart';

class FlowlyColors {
  static const background = Color(0xFFEFF2FC);
  static const surface = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF111111);
  static const darkSurface = Color(0xFF111C2F);
  static const darkText = Color(0xFFF4F7FF);
  static const darkMuted = Color(0xFFA9B7CE);
  static const darkBorder = Color(0xFF2A3A56);
  static const darkNeutralCard = Color(0xFFE9EEF7);
  static const darkNeutralBorder = Color(0xFFCED8E8);
  static const primary = Color(0xFF0D57DF);
  static const primarySoft = Color(0xFFE7EEFF);
  static const accent = Color(0xFF5F87F5);
  static const text = Color(0xFF151723);
  static const muted = Color(0xFF3F506A);
  static const border = Color(0xFFD2DAEA);
  static const pink = Color(0xFFFF7C8A);
  static const cyan = Color(0xFF45B2E5);
  static const orange = Color(0xFFFF8A00);
  static const green = Color(0xFF10A454);
  static const purple = Color(0xFF8B5CF6);
  static const yellow = Color(0xFFF4B400);
  static const slate = Color(0xFF475569);
}

bool isFlowlyDark(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

Color flowlyPageTextColor(BuildContext context) {
  return isFlowlyDark(context) ? FlowlyColors.darkText : FlowlyColors.text;
}

Color flowlyPageMutedColor(BuildContext context) {
  return isFlowlyDark(context) ? FlowlyColors.darkMuted : FlowlyColors.muted;
}

const flowlyDefaultTaskTagColors = ['orange', 'red', 'green'];

const flowlyTaskTagPickerColors = [
  ...flowlyDefaultTaskTagColors,
  'blue',
  'purple',
  'cyan',
  'yellow',
  'gray',
  '#EF4444',
  '#EC4899',
  '#A855F7',
  '#6366F1',
  '#06B6D4',
  '#14B8A6',
  '#84CC16',
  '#EAB308',
  '#F97316',
  '#78716C',
];

const flowlyDefaultScheduleColors = ['blue', 'pink', 'orange'];

const flowlySchedulePickerColors = [
  ...flowlyDefaultScheduleColors,
  'gray',
  'green',
  'purple',
  'cyan',
  'yellow',
  '#EF4444',
  '#EC4899',
  '#A855F7',
  '#6366F1',
  '#06B6D4',
  '#14B8A6',
  '#84CC16',
  '#EAB308',
  '#F97316',
  '#78716C',
];

Color flowlyTaskTagColor(String color) {
  final hexColor = _colorFromHex(color);
  if (hexColor != null) return hexColor;

  return switch (color) {
    'red' => FlowlyColors.pink,
    'green' => FlowlyColors.green,
    'blue' => FlowlyColors.primary,
    'purple' => FlowlyColors.purple,
    'cyan' => FlowlyColors.cyan,
    'yellow' => FlowlyColors.yellow,
    'gray' => FlowlyColors.slate,
    _ => FlowlyColors.orange,
  };
}

Color flowlyScheduleColor(String color) {
  final hexColor = _colorFromHex(color);
  if (hexColor != null) return hexColor;

  return switch (color) {
    'pink' => FlowlyColors.pink,
    'orange' => FlowlyColors.orange,
    'gray' => FlowlyColors.muted,
    'green' => FlowlyColors.green,
    'purple' => FlowlyColors.purple,
    'cyan' => FlowlyColors.cyan,
    'yellow' => FlowlyColors.yellow,
    _ => FlowlyColors.primary,
  };
}

Color? _colorFromHex(String value) {
  final normalized = value.trim();
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(normalized);
  if (match == null) return null;

  return Color(int.parse('FF${match.group(1)}', radix: 16));
}

ThemeData buildFlowlyTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FlowlyColors.primary,
      primary: FlowlyColors.primary,
      surface: FlowlyColors.surface,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F7FF),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: FlowlyColors.text,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.05,
      ),
      headlineMedium: TextStyle(
        color: FlowlyColors.text,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: FlowlyColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: FlowlyColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: FlowlyColors.text,
        fontSize: 16,
        height: 1.35,
      ),
      bodyMedium: TextStyle(
        color: FlowlyColors.muted,
        fontSize: 14,
        height: 1.35,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.78),
      prefixIconColor: FlowlyColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FlowlyColors.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FlowlyColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

ThemeData buildFlowlyDarkTheme() {
  final lightTheme = buildFlowlyTheme();

  return lightTheme.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FlowlyColors.darkBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FlowlyColors.primary,
      primary: FlowlyColors.primary,
      surface: const Color(0xFF111A2C),
      brightness: Brightness.dark,
    ),
  );
}
