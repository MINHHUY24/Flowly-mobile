import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/l10n.dart';
import '../widgets/flowly_logo.dart';

class ConfigErrorPage extends StatelessWidget {
  const ConfigErrorPage({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FlowlyColors.surface,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FlowlyLogo(height: 54),
                      const SizedBox(height: 28),
                      Text(
                        strings.configTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error?.toString() ??
                            'Không tải được cấu hình Supabase.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 18),
                      const SelectableText(
                        'Chạy backend: npm run dev:server\n'
                        'Hoặc chạy app với:\n'
                        'cd mobile\n'
                        'flutter run --dart-define-from-file=.env\n\n'
                        'Nếu chạy trên máy thật:\n'
                        'flutter run --dart-define-from-file=.env --dart-define=FLOWLY_API_BASE_URL=http://<IP_MAY_MAC>:3000',
                      ),
                    ],
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
