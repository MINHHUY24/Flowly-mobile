import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../core/app_theme.dart';
import '../core/l10n.dart';
import '../widgets/flowly_logo.dart';
import '../widgets/common_widgets.dart';

enum AuthMode { login, register, forgot }

class AuthFlowPage extends StatefulWidget {
  const AuthFlowPage({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  AuthMode _mode = AuthMode.login;

  @override
  Widget build(BuildContext context) {
    final page = switch (_mode) {
      AuthMode.login => LoginPage(
        onRegister: () => setState(() => _mode = AuthMode.register),
        onForgotPassword: () => setState(() => _mode = AuthMode.forgot),
        onAuthenticated: widget.onAuthenticated,
      ),
      AuthMode.register => RegisterPage(
        onLogin: () => setState(() => _mode = AuthMode.login),
        onAuthenticated: widget.onAuthenticated,
      ),
      AuthMode.forgot => ForgotPasswordPage(
        onLogin: () => setState(() => _mode = AuthMode.login),
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(_mode), child: page),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onAuthenticated,
  });

  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;
  final VoidCallback onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      widget.onAuthenticated();
    } on AuthException catch (error) {
      if (mounted) FlowlySnack.show(context, error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) async {
    try {
      final response = await Supabase.instance.client.auth.getOAuthSignInUrl(
        provider: provider,
        redirectTo: 'flowly://login-callback',
      );
      final launched = await _launchOAuthUrl(Uri.parse(response.url));

      if (!launched && mounted) {
        FlowlySnack.show(
          context,
          'Không mở được trình duyệt đăng nhập. Vui lòng thử lại.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) FlowlySnack.show(context, error.message);
    } on Object catch (error) {
      if (mounted) FlowlySnack.show(context, 'OAuth error: $error');
    }
  }

  Future<bool> _launchOAuthUrl(Uri uri) async {
    const launchModes = [
      launcher.LaunchMode.externalApplication,
      launcher.LaunchMode.platformDefault,
      launcher.LaunchMode.inAppBrowserView,
    ];

    for (final mode in launchModes) {
      try {
        final launched = await launcher.launchUrl(uri, mode: mode);

        if (launched) return true;
      } on PlatformException {
        continue;
      } on Object {
        continue;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    return AuthFrame(
      title: strings.login,
      subtitle: strings.isEnglish ? 'Welcome back' : 'Chào mừng trở lại',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowlyTextField(
            controller: _emailController,
            icon: Icons.account_circle_outlined,
            hint: strings.email,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: isTablet ? 34 : 22),
          FlowlyTextField(
            controller: _passwordController,
            icon: Icons.key,
            hint: strings.password,
            obscureText: true,
            onSubmitted: (_) => _login(),
          ),
          SizedBox(height: isTablet ? 18 : 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: FlowlyColors.muted,
                  textStyle: TextStyle(
                    fontSize: isTablet ? 22 : 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: widget.onRegister,
                child: Text(strings.register),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: FlowlyColors.muted,
                  textStyle: TextStyle(
                    fontSize: isTablet ? 22 : 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: widget.onForgotPassword,
                child: Text(strings.forgotPassword),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 44 : 22),
          AuthPrimaryButton(
            label: strings.login,
            loading: _loading,
            onPressed: _loading ? null : _login,
          ),
          SizedBox(height: isTablet ? 42 : 26),
          AuthDivider(label: strings.isEnglish ? 'OR' : 'HOẶC'),
          SizedBox(height: isTablet ? 38 : 20),
          SocialButton(
            label: strings.loginWithGoogle,
            color: Colors.white.withValues(alpha: 0.92),
            textColor: FlowlyColors.muted,
            icon: const GoogleLogoMark(),
            onPressed: () => _oauth(OAuthProvider.google),
          ),
          SizedBox(height: isTablet ? 32 : 16),
          SocialButton(
            label: strings.loginWithFacebook,
            color: Colors.white.withValues(alpha: 0.92),
            textColor: FlowlyColors.muted,
            icon: const FacebookLogoMark(),
            onPressed: () => _oauth(OAuthProvider.facebook),
          ),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onLogin,
    required this.onAuthenticated,
  });

  final VoidCallback onLogin;
  final VoidCallback onAuthenticated;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final strings = FlowlyStringsScope.of(context).strings;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) return;
    if (password.length < 6) {
      FlowlySnack.show(context, 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }
    if (password != confirm) {
      FlowlySnack.show(context, 'Mật khẩu nhập lại không khớp');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': email.split('@').first},
      );
      if (response.session != null) {
        widget.onAuthenticated();
      } else {
        if (!mounted) return;
        FlowlySnack.show(
          context,
          strings.isEnglish
              ? 'Registered. Please check your email or log in.'
              : 'Đăng ký thành công. Vui lòng kiểm tra email hoặc đăng nhập.',
        );
        widget.onLogin();
      }
    } on AuthException catch (error) {
      if (mounted) FlowlySnack.show(context, error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    return AuthFrame(
      title: strings.register,
      subtitle: strings.isEnglish
          ? 'Create your Flowly account'
          : 'Tạo tài khoản Flowly',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowlyTextField(
            controller: _emailController,
            icon: Icons.account_circle_outlined,
            hint: strings.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 22),
          FlowlyTextField(
            controller: _passwordController,
            icon: Icons.key,
            hint: strings.password,
            obscureText: true,
          ),
          const SizedBox(height: 22),
          FlowlyTextField(
            controller: _confirmController,
            icon: Icons.key,
            hint: strings.confirmPassword,
            obscureText: true,
            onSubmitted: (_) => _register(),
          ),
          SizedBox(height: isTablet ? 44 : 28),
          AuthPrimaryButton(
            label: strings.register,
            loading: _loading,
            onPressed: _loading ? null : _register,
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                strings.alreadyHaveAccount,
                style: TextStyle(
                  color: FlowlyColors.muted,
                  fontSize: isTablet ? 20 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(onPressed: widget.onLogin, child: Text(strings.login)),
            ],
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        FlowlySnack.show(
          context,
          'Đã gửi liên kết đặt lại mật khẩu. Vui lòng kiểm tra email.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) FlowlySnack.show(context, error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;

    return AuthFrame(
      title: strings.forgotPassword,
      subtitle: strings.isEnglish
          ? 'Enter your email to reset your password'
          : 'Nhập email để đặt lại mật khẩu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowlyTextField(
            controller: _emailController,
            icon: Icons.mail_outline,
            hint: strings.email,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            label: strings.sendRequest,
            loading: _loading,
            onPressed: _loading ? null : _send,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: widget.onLogin,
            child: Text(strings.backToLogin),
          ),
        ],
      ),
    );
  }
}

class LoginSuccessPage extends StatefulWidget {
  const LoginSuccessPage({super.key});

  @override
  State<LoginSuccessPage> createState() => _LoginSuccessPageState();
}

class _LoginSuccessPageState extends State<LoginSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..forward();
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.70, curve: Curves.easeOutCubic),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.70, curve: Curves.easeOutCubic),
          ),
        );
    _checkScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 1, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;

    return _AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: FlowlyGlass(
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(32),
                      tint: Colors.white.withValues(alpha: 0.84),
                      borderColor: Colors.white.withValues(alpha: 0.92),
                      blur: 30,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 72,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FlowlyLogo(height: 58),
                          const SizedBox(height: 34),
                          ScaleTransition(
                            scale: _checkScale,
                            child: FlowlyGlass(
                              width: 126,
                              height: 126,
                              borderRadius: BorderRadius.circular(63),
                              tint: const Color(
                                0xFFAEEF8D,
                              ).withValues(alpha: 0.82),
                              borderColor: Colors.white.withValues(alpha: 0.92),
                              blur: 18,
                              shadows: [
                                BoxShadow(
                                  color: FlowlyColors.green.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF039447),
                                size: 86,
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          Text(
                            strings.loginSuccess,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: FlowlyColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              height: 5,
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, _) {
                                  return LinearProgressIndicator(
                                    value: _controller.value,
                                    minHeight: 5,
                                    backgroundColor: FlowlyColors.primarySoft
                                        .withValues(alpha: 0.72),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          FlowlyColors.primary,
                                        ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 700;
    final useTabletLayout = size.width >= 840;
    final cardMaxWidth = useTabletLayout ? 980.0 : 430.0;
    final cardMinHeight = 0.0;
    final contentWidth = isTablet ? 560.0 : 360.0;
    final radius = BorderRadius.circular(useTabletLayout ? 36 : 32);

    return _AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 72 : 22,
                vertical: isTablet ? 34 : 22,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: cardMaxWidth,
                  minHeight: cardMinHeight,
                ),
                child: FlowlyGlass(
                  width: double.infinity,
                  borderRadius: radius,
                  tint: Colors.white.withValues(alpha: 0.93),
                  borderColor: FlowlyColors.border.withValues(alpha: 0.72),
                  blur: 30,
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: FlowlyColors.primary.withValues(alpha: 0.08),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.52),
                      blurRadius: 14,
                      offset: const Offset(-5, -5),
                    ),
                  ],
                  padding: EdgeInsets.symmetric(
                    horizontal: useTabletLayout ? 34 : 28,
                    vertical: useTabletLayout ? 34 : 34,
                  ),
                  child: useTabletLayout
                      ? Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: _AuthTitleBlock(
                                title: title,
                                subtitle: subtitle,
                                logoHeight: 86,
                                titleSize: 36,
                                subtitleSize: 18,
                              ),
                            ),
                            const SizedBox(width: 30),
                            Container(
                              width: 1,
                              height: 430,
                              color: FlowlyColors.border.withValues(
                                alpha: 0.42,
                              ),
                            ),
                            const SizedBox(width: 34),
                            Expanded(
                              flex: 6,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: contentWidth,
                                ),
                                child: child,
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: contentWidth),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AuthTitleBlock(
                                  title: title,
                                  subtitle: subtitle,
                                  logoHeight: isTablet ? 76 : 58,
                                  titleSize: isTablet ? 34 : 26,
                                  subtitleSize: isTablet ? 20 : 14,
                                ),
                                SizedBox(height: isTablet ? 42 : 28),
                                child,
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTitleBlock extends StatelessWidget {
  const _AuthTitleBlock({
    required this.title,
    required this.logoHeight,
    required this.titleSize,
    required this.subtitleSize,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final double logoHeight;
  final double titleSize;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowlyLogo(height: logoHeight),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: FlowlyColors.primary,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FlowlyColors.muted.withValues(alpha: 0.82),
              fontSize: subtitleSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = isFlowlyDark(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [
                  FlowlyColors.darkBackground,
                  FlowlyColors.darkBackground,
                  FlowlyColors.darkBackground,
                ]
              : const [Color(0xFFF8FBFF), Color(0xFFEAF0FF), Color(0xFFF8FCFF)],
        ),
      ),
      child: child,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    return SizedBox(
      height: isTablet ? 72 : 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: FlowlyColors.primary.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: FlowlyColors.primary,
            disabledBackgroundColor: FlowlyColors.primary.withValues(
              alpha: 0.62,
            ),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            ),
            textStyle: TextStyle(
              fontSize: isTablet ? 24 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          onPressed: onPressed,
          child: loading
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: FlowlyColors.border.withValues(alpha: 0.72),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: FlowlyColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: FlowlyColors.border.withValues(alpha: 0.72),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class FlowlyTextField extends StatelessWidget {
  const FlowlyTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 700;
    final radius = BorderRadius.circular(isTablet ? 24 : 20);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: FlowlyColors.primary.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: !obscureText,
        textInputAction: onSubmitted == null
            ? TextInputAction.next
            : TextInputAction.done,
        onSubmitted: onSubmitted,
        style: TextStyle(
          color: FlowlyColors.text,
          fontSize: isTablet ? 24 : 16,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.96),
          hintStyle: TextStyle(
            color: FlowlyColors.muted.withValues(alpha: 0.72),
            fontSize: isTablet ? 24 : 16,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(
            icon,
            color: FlowlyColors.muted,
            size: isTablet ? 30 : 23,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: isTablet ? 72 : 54,
            minHeight: isTablet ? 70 : 56,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 22 : 18,
            vertical: isTablet ? 24 : 17,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: FlowlyColors.border.withValues(alpha: 0.58),
              width: 1.1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(
              color: FlowlyColors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: FlowlyColors.pink, width: 1.3),
          ),
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 700;
    final targetWidth = isTablet ? 560.0 : 280.0;
    final height = isTablet ? 70.0 : 52.0;
    final horizontalPadding = isTablet ? 28.0 : 18.0;
    final iconWidth = isTablet ? 44.0 : 28.0;
    final iconGap = isTablet ? 24.0 : 14.0;
    final radius = BorderRadius.circular(isTablet ? 22 : 18);
    final fontSize = isTablet ? 22.0 : 15.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth < targetWidth
            ? constraints.maxWidth
            : targetWidth;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: FlowlyGlass(
              borderRadius: radius,
              tint: color,
              borderColor: FlowlyColors.border.withValues(alpha: 0.62),
              blur: 18,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              child: Material(
                color: Colors.transparent,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onPressed,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: iconWidth,
                          child: Center(child: icon),
                        ),
                        SizedBox(width: iconGap),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GoogleLogoMark extends StatelessWidget {
  const GoogleLogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    return FaIcon(
      FontAwesomeIcons.google,
      color: const Color(0xFF4285F4),
      size: isTablet ? 40 : 22,
    );
  }
}

class FacebookLogoMark extends StatelessWidget {
  const FacebookLogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    return FaIcon(
      FontAwesomeIcons.facebook,
      color: const Color(0xFF1877F2),
      size: isTablet ? 44 : 24,
    );
  }
}
