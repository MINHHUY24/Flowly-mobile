import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/core/app_config.dart';
import 'src/core/app_theme.dart';
import 'src/core/flowly_repository.dart';
import 'src/core/l10n.dart';
import 'src/pages/app_shell.dart';
import 'src/pages/auth_pages.dart';
import 'src/pages/config_error_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final language = prefs.getString('flowly_language') ?? 'vi';
  final themeModeVersion = prefs.getInt('flowly_theme_mode_version') ?? 0;
  final ThemeMode themeMode;
  if (themeModeVersion < 2) {
    themeMode = ThemeMode.system;
    await prefs.setString('flowly_theme_mode', 'system');
    await prefs.setInt('flowly_theme_mode_version', 2);
  } else {
    themeMode = switch (prefs.getString('flowly_theme_mode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  AppConfig? config;
  Object? configError;

  try {
    config = await AppConfig.load();
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
  } catch (error) {
    configError = error;
  }

  runApp(
    FlowlyApp(
      initialLanguage: language,
      initialThemeMode: themeMode,
      config: config,
      configError: configError,
    ),
  );
}

class FlowlyApp extends StatefulWidget {
  const FlowlyApp({
    super.key,
    required this.initialLanguage,
    required this.initialThemeMode,
    required this.config,
    required this.configError,
  });

  final String initialLanguage;
  final ThemeMode initialThemeMode;
  final AppConfig? config;
  final Object? configError;

  @override
  State<FlowlyApp> createState() => _FlowlyAppState();
}

class _FlowlyAppState extends State<FlowlyApp> {
  late String _language;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _changeLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flowly_language', value);
    setState(() => _language = value);
  }

  Future<void> _changeThemeMode(ThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flowly_theme_mode', switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    await prefs.setInt('flowly_theme_mode_version', 2);
    setState(() => _themeMode = value);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_language);

    return FlowlyStringsScope(
      strings: strings,
      language: _language,
      onChangeLanguage: _changeLanguage,
      themeMode: _themeMode,
      onChangeThemeMode: _changeThemeMode,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flowly',
        theme: buildFlowlyTheme(),
        darkTheme: buildFlowlyDarkTheme(),
        themeMode: _themeMode,
        home: widget.config == null
            ? ConfigErrorPage(error: widget.configError)
            : SessionGate(config: widget.config!),
      ),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, required this.config});

  final AppConfig config;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final FlowlyRepository _repository;
  Session? _session;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _repository = FlowlyRepository(config: widget.config);
    _session = Supabase.instance.client.auth.currentSession;
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      final wasLoggedOut = _session == null;
      setState(() {
        _session = event.session;
        if (wasLoggedOut &&
            event.event == AuthChangeEvent.signedIn &&
            event.session != null) {
          _showSuccess = true;
        }
      });

      if (wasLoggedOut &&
          event.event == AuthChangeEvent.signedIn &&
          event.session != null) {
        Future<void>.delayed(const Duration(milliseconds: 1300), () {
          if (mounted) setState(() => _showSuccess = false);
        });
      }
    });
  }

  void _handleAuthenticated() {
    setState(() => _showSuccess = true);
    Future<void>.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _showSuccess = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return AuthFlowPage(onAuthenticated: _handleAuthenticated);
    }

    if (_showSuccess) {
      return const LoginSuccessPage();
    }

    return AppShell(repository: _repository);
  }
}
