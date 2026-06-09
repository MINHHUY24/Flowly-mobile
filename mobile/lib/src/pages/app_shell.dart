import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/flowly_repository.dart';
import '../core/l10n.dart';
import '../widgets/flowly_logo.dart';
import '../widgets/common_widgets.dart';
import 'home_page.dart';
import 'schedule_page.dart';
import 'tasks_page.dart';

Color _modalBorderColor([double alpha = 0.34]) {
  return FlowlyColors.border.withValues(alpha: alpha);
}

List<BoxShadow> _modalSheetShadows() {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
}

List<BoxShadow> _modalCardShadows() {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

OutlineInputBorder _modalInputBorder([double alpha = 0.34]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide(color: _modalBorderColor(alpha)),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.repository});

  final FlowlyRepository repository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _previousIndex = 0;
  int _reloadSignal = 0;

  String get _pageName {
    return switch (_index) {
      1 => 'schedule',
      2 => 'tasks',
      _ => 'home',
    };
  }

  void _refreshPages() {
    setState(() => _reloadSignal += 1);
  }

  void _selectPage(int index) {
    if (index == _index) return;
    setState(() {
      _previousIndex = _index;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = FlowlyStringsScope.of(context);
    final strings = scope.strings;
    final isDarkMode = isFlowlyDark(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? const [
                  FlowlyColors.darkBackground,
                  FlowlyColors.darkBackground,
                  FlowlyColors.darkBackground,
                ]
              : const [Color(0xFFF8FBFF), Color(0xFFEAF0FF), Color(0xFFF8FCFF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppHeader(repository: widget.repository),
              Expanded(
                child: _LiquidPageSwitcher(
                  index: _index,
                  previousIndex: _previousIndex,
                  children: [
                    HomePage(
                      repository: widget.repository,
                      reloadSignal: _reloadSignal,
                    ),
                    SchedulePage(
                      repository: widget.repository,
                      reloadSignal: _reloadSignal,
                    ),
                    TasksPage(
                      repository: widget.repository,
                      reloadSignal: _reloadSignal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _LiquidBottomBar(
          selectedIndex: _index,
          onSelected: _selectPage,
          onBotPressed: () => showFlowlyChatbot(
            context,
            repository: widget.repository,
            page: _pageName,
            onCreated: _refreshPages,
          ),
          items: [
            _LiquidNavItem(icon: Icons.home_rounded, label: strings.home),
            _LiquidNavItem(
              icon: Icons.calendar_month_rounded,
              label: strings.schedule,
            ),
            _LiquidNavItem(
              icon: Icons.assignment_rounded,
              label: strings.tasks,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidPageSwitcher extends StatelessWidget {
  const _LiquidPageSwitcher({
    required this.index,
    required this.previousIndex,
    required this.children,
  });

  final int index;
  final int previousIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final direction = index >= previousIndex ? 1.0 : -1.0;

    return Stack(
      children: [
        for (var childIndex = 0; childIndex < children.length; childIndex++)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: childIndex != index,
              child: ExcludeSemantics(
                excluding: childIndex != index,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  opacity: childIndex == index ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    offset: childIndex == index
                        ? Offset.zero
                        : Offset(childIndex < index ? -0.04 : 0.04, 0),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      scale: childIndex == index ? 1 : 0.985,
                      alignment: Alignment(direction, -0.35),
                      child: children[childIndex],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LiquidBottomBar extends StatelessWidget {
  const _LiquidBottomBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.onBotPressed,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onBotPressed;
  final List<_LiquidNavItem> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 700;
    final bottomPadding = isTablet
        ? const EdgeInsets.fromLTRB(28, 0, 28, 12)
        : const EdgeInsets.fromLTRB(18, 0, 18, 8);
    final navHeight = isTablet ? 64.0 : 68.0;
    final botSize = isTablet ? 64.0 : 68.0;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 980 : double.infinity,
          ),
          child: Padding(
            padding: bottomPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FlowlyGlass(
                    height: navHeight,
                    borderRadius: BorderRadius.circular(navHeight / 2),
                    tint: Colors.white.withValues(alpha: 0.56),
                    borderColor: Colors.white.withValues(alpha: 0.92),
                    blur: 36,
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.46),
                        blurRadius: 14,
                        offset: const Offset(-5, -5),
                      ),
                    ],
                    padding: const EdgeInsets.all(6),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: _tabAlignment(
                              selectedIndex,
                              items.length,
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 1 / items.length,
                              heightFactor: 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.68),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.92,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: FlowlyColors.primary.withValues(
                                          alpha: 0.10,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Row(
                            children: [
                              for (var index = 0; index < items.length; index++)
                                Expanded(
                                  child: _LiquidTabButton(
                                    item: items[index],
                                    selected: selectedIndex == index,
                                    onPressed: () => onSelected(index),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FlowlyChatbotButton(
                  size: botSize,
                  iconSize: isTablet ? 30 : 32,
                  onPressed: onBotPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Alignment _tabAlignment(int selectedIndex, int itemCount) {
  if (itemCount <= 1) return Alignment.center;
  final x = -1 + (2 * selectedIndex / (itemCount - 1));
  return Alignment(x, 0);
}

class _LiquidNavItem {
  const _LiquidNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _LiquidTabButton extends StatelessWidget {
  const _LiquidTabButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final _LiquidNavItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? FlowlyColors.primary : FlowlyColors.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: color, size: 24),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    height: 1,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.repository});

  final FlowlyRepository repository;

  @override
  Widget build(BuildContext context) {
    final user = repository.currentUser;
    final displayName = _displayName(user);
    final avatarUrl = _avatarUrl(user);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 700;
    final horizontal = isTablet ? 28.0 : 22.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 1120 : double.infinity,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 12),
          child: FlowlyGlass(
            borderRadius: BorderRadius.circular(30),
            tint: Colors.white.withValues(alpha: 0.70),
            borderColor: Colors.white.withValues(alpha: 0.92),
            blur: 24,
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
            child: Row(
              children: [
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FlowlyLogo(
                      height: width < 390 ? 46 : 50,
                      iconOnly: width < 350,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () =>
                      showAccountSheet(context, repository: repository),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: width < 390 ? 90 : 180,
                        ),
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FlowlyColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FlowlyGlass(
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.circular(20),
                        tint: FlowlyColors.primarySoft.withValues(alpha: 0.72),
                        blur: 16,
                        shadows: const [],
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.transparent,
                          backgroundImage: avatarUrl == null
                              ? const AssetImage('assets/images/avatar.png')
                              : NetworkImage(avatarUrl) as ImageProvider,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FlowlyChatbotButton extends StatelessWidget {
  const FlowlyChatbotButton({
    super.key,
    required this.onPressed,
    this.size = 56,
    this.iconSize = 32,
  });

  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 2);

    return Tooltip(
      message: 'Flowly Bot',
      child: FlowlyGlass(
        borderRadius: radius,
        tint: Colors.white.withValues(alpha: 0.58),
        borderColor: Colors.white.withValues(alpha: 0.92),
        blur: 36,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.44),
            blurRadius: 12,
            offset: const Offset(-4, -4),
          ),
        ],
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: Image.asset(
                  'assets/images/chat_bot.png',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _displayName(User? user) {
  final metadata = user?.userMetadata ?? {};
  return metadata['full_name'] as String? ??
      metadata['name'] as String? ??
      user?.email?.split('@').first ??
      'User';
}

String? _avatarUrl(User? user) {
  final metadata = user?.userMetadata ?? {};
  return metadata['avatar_url'] as String? ??
      metadata['picture'] as String? ??
      metadata['photoURL'] as String?;
}

Future<void> showFlowlyChatbot(
  BuildContext context, {
  required FlowlyRepository repository,
  required String page,
  required VoidCallback onCreated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        ChatbotSheet(repository: repository, page: page, onCreated: onCreated),
  );
}

class ChatbotSheet extends StatefulWidget {
  const ChatbotSheet({
    super.key,
    required this.repository,
    required this.page,
    required this.onCreated,
  });

  final FlowlyRepository repository;
  final String page;
  final VoidCallback onCreated;

  @override
  State<ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<ChatbotSheet> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[];
  bool _didAddWelcomeMessage = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didAddWelcomeMessage) return;

    final strings = FlowlyStringsScope.of(context).strings;
    _messages.add(_ChatMessage(text: strings.botWelcome, isUser: false));
    _didAddWelcomeMessage = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(
        _ChatMessage(
          text: FlowlyStringsScope.of(context).strings.botThinking,
          isUser: false,
        ),
      );
      _controller.clear();
      _loading = true;
    });

    try {
      final created = await widget.repository.createFromAi(text, widget.page);
      setState(() {
        _messages[_messages.length - 1] = _ChatMessage(
          text: created.isEmpty
              ? 'Mình chưa nhận ra nội dung cần tạo.'
              : 'Đã thêm ${created.length} mục vào Flowly.',
          isUser: false,
        );
      });
      widget.onCreated();
    } catch (error) {
      setState(() {
        _messages[_messages.length - 1] = _ChatMessage(
          text: 'Có lỗi khi xử lý yêu cầu: $error',
          isUser: false,
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return FlowlyGlass(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            tint: Colors.white.withValues(alpha: 0.86),
            blur: 28,
            borderColor: _modalBorderColor(0.28),
            shadows: _modalSheetShadows(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 14, 10),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/chat_bot.png',
                        width: 42,
                        height: 42,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.flowlyBot,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      FlowlyGlass(
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(22),
                        tint: Colors.white.withValues(alpha: 0.76),
                        borderColor: _modalBorderColor(0.28),
                        blur: 18,
                        shadows: const [],
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: FlowlyColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? FlowlyColors.primary
                                : Colors.white.withValues(alpha: 0.76),
                            borderRadius: BorderRadius.circular(18),
                            border: message.isUser
                                ? null
                                : Border.all(color: _modalBorderColor(0.30)),
                            boxShadow: [
                              BoxShadow(
                                color: FlowlyColors.primary.withValues(
                                  alpha: message.isUser ? 0.12 : 0.06,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.isUser
                                  ? Colors.white
                                  : FlowlyColors.text,
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemCount: _messages.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: strings.botPlaceholder,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.82),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _modalBorderColor(0.34),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: FlowlyColors.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: FlowlyColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: FlowlyColors.primary
                              .withValues(alpha: 0.48),
                          disabledForegroundColor: Colors.white.withValues(
                            alpha: 0.62,
                          ),
                          minimumSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

Future<void> showAccountSheet(
  BuildContext context, {
  required FlowlyRepository repository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AccountSheet(repository: repository),
  );
}

class AccountSheet extends StatefulWidget {
  const AccountSheet({super.key, required this.repository});

  final FlowlyRepository repository;

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthdayController;

  @override
  void initState() {
    super.initState();
    final user = widget.repository.currentUser;
    final metadata = user?.userMetadata ?? {};
    _nameController = TextEditingController(text: _displayName(user));
    _phoneController = TextEditingController(
      text: metadata['phone'] as String? ?? '',
    );
    _birthdayController = TextEditingController(
      text: metadata['birthday'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<bool> _saveProfile({
    required String name,
    required String phone,
    required String birthday,
    required String password,
  }) async {
    final strings = FlowlyStringsScope.of(context).strings;
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    final trimmedBirthday = birthday.trim();
    final trimmedPassword = password.trim();

    if (trimmedName.isEmpty) {
      FlowlySnack.show(
        context,
        strings.isEnglish ? 'Name is required.' : 'Tên không được để trống.',
      );
      return false;
    }

    try {
      final payload = UserAttributes(
        data: {
          'full_name': trimmedName,
          'name': trimmedName,
          'phone': trimmedPhone,
          'birthday': trimmedBirthday,
        },
        password: trimmedPassword.isEmpty ? null : trimmedPassword,
      );
      await Supabase.instance.client.auth.updateUser(payload);
      if (mounted) {
        _nameController.text = trimmedName;
        _phoneController.text = trimmedPhone;
        _birthdayController.text = trimmedBirthday;
        FlowlySnack.show(
          context,
          strings.isEnglish ? 'Profile updated.' : 'Đã cập nhật thông tin.',
        );
      }
      return true;
    } on AuthException catch (error) {
      if (mounted) FlowlySnack.show(context, error.message);
    } catch (error) {
      if (mounted) FlowlySnack.show(context, '$error');
    }
    return false;
  }

  Future<void> _openEditProfileDialog() {
    return _showAccountEditDialog(
      context,
      strings: FlowlyStringsScope.of(context).strings,
      initialName: _nameController.text,
      initialBirthday: _birthdayController.text,
      initialPhone: _phoneController.text,
      onSave: _saveProfile,
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = FlowlyStringsScope.of(context);
    final strings = scope.strings;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final user = widget.repository.currentUser;
    final avatarUrl = _avatarUrl(user);
    final displayName = _nameController.text.trim().isEmpty
        ? _displayName(user)
        : _nameController.text.trim();
    final email = user?.email ?? '';
    final activeThemeMode = scope.themeMode;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: FlowlyGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        tint: Colors.white.withValues(alpha: 0.88),
        blur: 30,
        borderColor: _modalBorderColor(0.28),
        shadows: _modalSheetShadows(),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: FlowlyColors.muted.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(child: FlowlyLogo(height: 54)),
                const SizedBox(height: 20),
                _AccountProfileCard(
                  avatarUrl: avatarUrl,
                  displayName: displayName,
                  email: email,
                  onEdit: _openEditProfileDialog,
                ),
                const SizedBox(height: 18),
                _AccountGroupCard(
                  children: [
                    _AccountMenuRow(
                      icon: Icons.history_rounded,
                      title: strings.history,
                      onTap: () => FlowlySnack.show(context, strings.history),
                    ),
                    const _AccountSectionDivider(),
                    _AccountMenuRow(
                      icon: Icons.language_rounded,
                      title: strings.languageLabel,
                      value: _languageLabel(scope.language),
                      onTap: () async {
                        final language = await showLanguagePickerDialog(
                          context,
                          currentLanguage: scope.language,
                        );
                        if (language == null || language == scope.language) {
                          return;
                        }
                        await scope.onChangeLanguage(language);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _AccountGroupCard(
                  children: [
                    _AppearanceSettingRow(
                      title: strings.appearance,
                      systemLabel: strings.systemMode,
                      lightLabel: strings.lightMode,
                      darkLabel: strings.darkMode,
                      themeMode: activeThemeMode,
                      onChanged: (themeMode) =>
                          scope.onChangeThemeMode(themeMode),
                    ),
                    const _AccountSectionDivider(),
                    _AccountMenuRow(
                      icon: Icons.logout_rounded,
                      title: strings.logout,
                      destructive: true,
                      onTap: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountProfileCard extends StatelessWidget {
  const _AccountProfileCard({
    required this.avatarUrl,
    required this.displayName,
    required this.email,
    required this.onEdit,
  });

  final String? avatarUrl;
  final String displayName;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final radius = BorderRadius.circular(26);

    return FlowlyGlass(
      width: double.infinity,
      borderRadius: radius,
      tint: Colors.white.withValues(alpha: 0.82),
      borderColor: _modalBorderColor(0.32),
      blur: 24,
      shadows: _modalCardShadows(),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: FlowlyColors.primarySoft,
                  backgroundImage: avatarUrl == null
                      ? const AssetImage('assets/images/avatar.png')
                      : NetworkImage(avatarUrl!) as ImageProvider,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FlowlyColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FlowlyColors.primary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: strings.edit,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  color: FlowlyColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showAccountEditDialog(
  BuildContext context, {
  required AppStrings strings,
  required String initialName,
  required String initialBirthday,
  required String initialPhone,
  required _SaveAccountProfile onSave,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    builder: (context) {
      return _AccountEditDialog(
        strings: strings,
        initialName: initialName,
        initialBirthday: initialBirthday,
        initialPhone: initialPhone,
        onSave: onSave,
      );
    },
  );
}

typedef _SaveAccountProfile =
    Future<bool> Function({
      required String name,
      required String phone,
      required String birthday,
      required String password,
    });

class _AccountEditDialog extends StatefulWidget {
  const _AccountEditDialog({
    required this.strings,
    required this.initialName,
    required this.initialBirthday,
    required this.initialPhone,
    required this.onSave,
  });

  final AppStrings strings;
  final String initialName;
  final String initialBirthday;
  final String initialPhone;
  final _SaveAccountProfile onSave;

  @override
  State<_AccountEditDialog> createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends State<_AccountEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _phoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _passwordController = TextEditingController();
    _birthdayController = TextEditingController(text: widget.initialBirthday);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;

    setState(() => _saving = true);
    final saved = await widget.onSave(
      name: _nameController.text,
      phone: _phoneController.text,
      birthday: _birthdayController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (saved) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottom),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: _AccountEditForm(
              strings: widget.strings,
              nameController: _nameController,
              passwordController: _passwordController,
              birthdayController: _birthdayController,
              phoneController: _phoneController,
              saving: _saving,
              onSave: _handleSave,
              onClose: _saving ? null : () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountEditForm extends StatelessWidget {
  const _AccountEditForm({
    required this.strings,
    required this.nameController,
    required this.passwordController,
    required this.birthdayController,
    required this.phoneController,
    required this.saving,
    required this.onSave,
    this.onClose,
  });

  final AppStrings strings;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final TextEditingController birthdayController;
  final TextEditingController phoneController;
  final bool saving;
  final Future<void> Function() onSave;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return FlowlyGlass(
      width: double.infinity,
      borderRadius: BorderRadius.circular(26),
      tint: Colors.white.withValues(alpha: 0.72),
      borderColor: _modalBorderColor(0.32),
      blur: 24,
      shadows: _modalCardShadows(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.editProfile,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onClose != null)
                FlowlyGlass(
                  width: 42,
                  height: 42,
                  borderRadius: BorderRadius.circular(21),
                  tint: Colors.white.withValues(alpha: 0.76),
                  borderColor: _modalBorderColor(0.28),
                  blur: 18,
                  shadows: const [],
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: FlowlyColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _AccountTextField(
            controller: nameController,
            hintText: strings.profileName,
            icon: Icons.account_circle_outlined,
          ),
          const SizedBox(height: 10),
          _AccountTextField(
            controller: passwordController,
            hintText: strings.isEnglish ? 'New password' : 'Mật khẩu mới',
            icon: Icons.key_rounded,
            obscureText: true,
          ),
          const SizedBox(height: 10),
          _AccountTextField(
            controller: birthdayController,
            hintText: strings.birthday,
            icon: Icons.cake_outlined,
          ),
          const SizedBox(height: 10),
          _AccountTextField(
            controller: phoneController,
            hintText: strings.phone,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: saving ? null : () => onSave(),
            child: saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(strings.save),
          ),
        ],
      ),
    );
  }
}

class _AccountTextField extends StatelessWidget {
  const _AccountTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.78),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: _modalBorderColor(0.34)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: FlowlyColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _AccountGroupCard extends StatelessWidget {
  const _AccountGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FlowlyGlass(
      width: double.infinity,
      borderRadius: BorderRadius.circular(26),
      tint: Colors.white.withValues(alpha: 0.78),
      borderColor: _modalBorderColor(0.32),
      blur: 24,
      shadows: _modalCardShadows(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: children),
    );
  }
}

class _AccountSectionDivider extends StatelessWidget {
  const _AccountSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      endIndent: 10,
      color: FlowlyColors.border.withValues(alpha: 0.42),
    );
  }
}

class _AccountMenuRow extends StatelessWidget {
  const _AccountMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value = '',
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : FlowlyColors.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 25),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (value.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FlowlyColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: color, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  final String code;
  final String nativeName;
  final String englishName;
}

const _languageOptions = [
  _LanguageOption(
    code: 'vi',
    nativeName: 'Tiếng Việt',
    englishName: 'Vietnamese',
  ),
  _LanguageOption(code: 'en', nativeName: 'English', englishName: 'English'),
];

String _languageLabel(String code) {
  return _languageOptions
      .firstWhere(
        (option) => option.code == code,
        orElse: () => _languageOptions.first,
      )
      .nativeName;
}

Future<String?> showLanguagePickerDialog(
  BuildContext context, {
  required String currentLanguage,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    builder: (context) =>
        _LanguagePickerDialog(currentLanguage: currentLanguage),
  );
}

class _LanguagePickerDialog extends StatefulWidget {
  const _LanguagePickerDialog({required this.currentLanguage});

  final String currentLanguage;

  @override
  State<_LanguagePickerDialog> createState() => _LanguagePickerDialogState();
}

class _LanguagePickerDialogState extends State<_LanguagePickerDialog> {
  final _searchController = TextEditingController();
  late String _selectedLanguage;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentLanguage;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_LanguageOption> get _filteredLanguages {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _languageOptions;

    return _languageOptions.where((option) {
      return option.nativeName.toLowerCase().contains(query) ||
          option.englishName.toLowerCase().contains(query) ||
          option.code.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final languages = _filteredLanguages;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: FlowlyGlass(
          borderRadius: BorderRadius.circular(30),
          tint: Colors.white.withValues(alpha: 0.90),
          borderColor: _modalBorderColor(0.30),
          blur: 30,
          shadows: _modalSheetShadows(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.languageLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FlowlyGlass(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.circular(21),
                    tint: Colors.white.withValues(alpha: 0.76),
                    borderColor: _modalBorderColor(0.28),
                    blur: 18,
                    shadows: const [],
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: FlowlyColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                cursorColor: FlowlyColors.primary,
                style: const TextStyle(
                  color: FlowlyColors.text,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: strings.search,
                  hintStyle: TextStyle(
                    color: FlowlyColors.muted.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: _modalInputBorder(),
                  enabledBorder: _modalInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final language = languages[index];
                    final selected = language.code == _selectedLanguage;

                    return _LanguageOptionTile(
                      language: language,
                      selected: selected,
                      onTap: () =>
                          setState(() => _selectedLanguage = language.code),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _LanguageDialogButton(
                      label: strings.cancel,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LanguageDialogButton(
                      label: strings.save,
                      primary: true,
                      onTap: () => Navigator.pop(context, _selectedLanguage),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? FlowlyColors.primarySoft.withValues(alpha: 0.86)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? FlowlyColors.primary.withValues(alpha: 0.35)
              : _modalBorderColor(0.34),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                FlowlyGlass(
                  width: 42,
                  height: 42,
                  borderRadius: BorderRadius.circular(21),
                  tint: Colors.white.withValues(alpha: 0.78),
                  borderColor: _modalBorderColor(0.28),
                  blur: 14,
                  shadows: const [],
                  child: Center(
                    child: Text(
                      language.code.toUpperCase(),
                      style: const TextStyle(
                        color: FlowlyColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FlowlyColors.text,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        language.englishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FlowlyColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: selected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: FlowlyColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageDialogButton extends StatelessWidget {
  const _LanguageDialogButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return FlowlyGlass(
      height: 50,
      borderRadius: BorderRadius.circular(17),
      tint: primary
          ? FlowlyColors.primary.withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.74),
      borderColor: primary
          ? FlowlyColors.primary.withValues(alpha: 0.28)
          : _modalBorderColor(0.32),
      blur: 18,
      shadows: const [],
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primary ? Colors.white : FlowlyColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceSettingRow extends StatelessWidget {
  const _AppearanceSettingRow({
    required this.title,
    required this.systemLabel,
    required this.lightLabel,
    required this.darkLabel,
    required this.themeMode,
    required this.onChanged,
  });

  final String title;
  final String systemLabel;
  final String lightLabel;
  final String darkLabel;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const Icon(
              Icons.contrast_rounded,
              color: FlowlyColors.primary,
              size: 25,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: const TextStyle(
                    color: FlowlyColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            _ThemeModeControl(
              systemLabel: systemLabel,
              lightLabel: lightLabel,
              darkLabel: darkLabel,
              themeMode: themeMode,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeControl extends StatelessWidget {
  const _ThemeModeControl({
    required this.systemLabel,
    required this.lightLabel,
    required this.darkLabel,
    required this.themeMode,
    required this.onChanged,
  });

  final String systemLabel;
  final String lightLabel;
  final String darkLabel;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FlowlyColors.primarySoft.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeModeButton(
            label: systemLabel,
            selected: themeMode == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
          _ThemeModeButton(
            label: lightLabel,
            selected: themeMode == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeModeButton(
            label: darkLabel,
            selected: themeMode == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 64,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? FlowlyColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : FlowlyColors.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
