import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/flowly_dates.dart';
import '../core/flowly_repository.dart';
import '../core/l10n.dart';
import '../models/task.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/common_widgets.dart';

Color _sheetBorderColor([double alpha = 0.34]) {
  return FlowlyColors.border.withValues(alpha: alpha);
}

List<BoxShadow> _sheetShadows() {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
}

List<BoxShadow> _sheetCardShadows() {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

OutlineInputBorder _sheetInputBorder([double alpha = 0.34]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide(color: _sheetBorderColor(alpha)),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.reloadSignal,
  });

  final FlowlyRepository repository;
  final int reloadSignal;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _taskExitDuration = Duration(milliseconds: 260);

  var _tasks = <FlowlyTask>[];
  var _loading = true;
  var _selectedDate = DateTime.now();
  var _calendarDate = DateTime.now();
  var _keyword = '';
  final _pendingDoneIds = <String>{};
  final _hidingTaskIds = <String>{};
  final _doneTimers = <String, Timer>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadSignal != widget.reloadSignal) _load();
  }

  @override
  void dispose() {
    for (final timer in _doneTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tasks = await widget.repository.getTasks();
      if (mounted) setState(() => _tasks = tasks);
    } catch (error) {
      if (mounted) FlowlySnack.show(context, '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _togglePendingDone(FlowlyTask task) {
    if (_pendingDoneIds.contains(task.id)) {
      _cancelPendingDone(task);
      return;
    }

    setState(() => _pendingDoneIds.add(task.id));
    _doneTimers[task.id] = Timer(
      const Duration(seconds: 6),
      () => _completeTask(task),
    );
  }

  void _cancelPendingDone(FlowlyTask task) {
    _doneTimers.remove(task.id)?.cancel();
    if (!_pendingDoneIds.remove(task.id)) return;
    if (mounted) setState(() {});
  }

  void _upsertTask(FlowlyTask task) {
    if (!mounted) return;
    setState(() {
      final next = [..._tasks];
      final index = next.indexWhere((item) => item.id == task.id);
      if (index == -1) {
        next.insert(0, task);
      } else {
        next[index] = task;
      }
      _tasks = next;
      _hidingTaskIds.remove(task.id);
    });
  }

  Future<void> _completeTask(FlowlyTask task) async {
    _doneTimers.remove(task.id);
    if (!mounted || !_pendingDoneIds.contains(task.id)) return;

    setState(() {
      _pendingDoneIds.remove(task.id);
      _hidingTaskIds.add(task.id);
    });

    try {
      final updated = await widget.repository.updateTaskStatus(task.id, 'done');
      await Future<void>.delayed(_taskExitDuration);
      if (!mounted) return;
      setState(() {
        final index = _tasks.indexWhere((item) => item.id == task.id);
        if (index != -1) {
          final next = [..._tasks];
          next[index] = updated;
          _tasks = next;
        }
        _hidingTaskIds.remove(task.id);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _hidingTaskIds.remove(task.id));
      FlowlySnack.show(context, '$error');
    }
  }

  Future<void> _delete(FlowlyTask task) async {
    _cancelPendingDone(task);
    if (_hidingTaskIds.contains(task.id)) return;
    setState(() => _hidingTaskIds.add(task.id));

    try {
      await Future.wait<void>([
        widget.repository.deleteTask(task.id),
        Future<void>.delayed(_taskExitDuration),
      ]);
      if (!mounted) return;
      setState(() {
        _tasks = _tasks.where((item) => item.id != task.id).toList();
        _hidingTaskIds.remove(task.id);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _hidingTaskIds.remove(task.id));
      FlowlySnack.show(context, '$error');
    }
  }

  Future<void> _togglePriority(FlowlyTask task) async {
    _cancelPendingDone(task);
    final priority = task.isUrgent ? 'normal' : 'high';
    final optimisticTask = task.copyWith(priority: priority);
    _upsertTask(optimisticTask);

    try {
      final updated = await widget.repository.updateTask(
        task.id,
        task.toPayload(priority: priority),
      );
      _upsertTask(updated);
    } catch (error) {
      _upsertTask(task);
      if (mounted) FlowlySnack.show(context, '$error');
    }
  }

  List<FlowlyTask> get _dailyTasks {
    final selectedKey = dateKey(_selectedDate);
    final keyword = _keyword.trim().toLowerCase();
    return _tasks.where((task) {
      final taskDate = task.taskDate ?? task.createdAt ?? DateTime.now();
      final matchesDate = dateKey(taskDate) == selectedKey;
      final matchesKeyword =
          keyword.isEmpty || task.title.toLowerCase().contains(keyword);
      return task.isIncomplete && matchesDate && matchesKeyword;
    }).toList();
  }

  DateTime _taskDate(FlowlyTask task) {
    return dateOnly(task.taskDate ?? task.createdAt ?? DateTime.now());
  }

  String _taskDateKey(FlowlyTask task) {
    return dateKey(_taskDate(task));
  }

  List<FlowlyTask> get _todayTasks {
    final todayKey = dateKey(DateTime.now());
    return _tasks.where((task) {
      return task.isIncomplete && _taskDateKey(task) == todayKey;
    }).toList();
  }

  List<FlowlyTask> get _plannedTasks {
    final todayKey = dateKey(DateTime.now());
    return _tasks.where((task) {
      return task.isIncomplete && _taskDateKey(task).compareTo(todayKey) > 0;
    }).toList();
  }

  List<FlowlyTask> get _urgentTasks {
    return _tasks.where((task) => task.isIncomplete && task.isUrgent).toList();
  }

  void _selectTaskDate(FlowlyTask task) {
    final taskDate = _taskDate(task);
    setState(() {
      _selectedDate = taskDate;
      _calendarDate = DateTime(taskDate.year, taskDate.month);
    });
  }

  Future<void> _showSummaryDialog({
    required String title,
    required IconData icon,
    required Color color,
    required List<FlowlyTask> tasks,
  }) {
    final sortedTasks = [...tasks]
      ..sort((a, b) {
        final dateCompare = _taskDate(a).compareTo(_taskDate(b));
        if (dateCompare != 0) return dateCompare;
        return a.title.compareTo(b.title);
      });

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (dialogContext) => _SummaryTaskDialog(
        title: title,
        icon: icon,
        color: color,
        tasks: sortedTasks,
        taskDate: _taskDate,
        onSelect: (task) {
          Navigator.of(dialogContext).pop();
          if (mounted) _selectTaskDate(task);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final dark = isFlowlyDark(context);
    final searchTextColor = FlowlyColors.text;
    final searchHintColor = dark
        ? FlowlyColors.muted.withValues(alpha: 0.54)
        : FlowlyColors.muted.withValues(alpha: 0.66);
    final searchIconColor = dark
        ? FlowlyColors.muted.withValues(alpha: 0.58)
        : FlowlyColors.muted;
    final searchFillColor = dark
        ? FlowlyColors.darkNeutralCard
        : Colors.white.withValues(alpha: 0.80);
    final searchBorderColor = dark
        ? FlowlyColors.darkNeutralBorder.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.90);
    final todayTasks = _todayTasks;
    final plannedTasks = _plannedTasks;
    final urgentTasks = _urgentTasks;
    final dailyTasks = _dailyTasks;

    Widget buildSummaryCards() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SummaryCard(
              icon: Icons.today_outlined,
              label: strings.today,
              count: todayTasks.length,
              color: FlowlyColors.cyan,
              onTap: todayTasks.isEmpty
                  ? null
                  : () => _showSummaryDialog(
                      title: strings.today,
                      icon: Icons.today_outlined,
                      color: FlowlyColors.cyan,
                      tasks: todayTasks,
                    ),
            ),
            const SizedBox(width: 18),
            SummaryCard(
              icon: Icons.calendar_month_outlined,
              label: strings.planned,
              count: plannedTasks.length,
              color: FlowlyColors.pink,
              onTap: plannedTasks.isEmpty
                  ? null
                  : () => _showSummaryDialog(
                      title: strings.planned,
                      icon: Icons.calendar_month_outlined,
                      color: FlowlyColors.pink,
                      tasks: plannedTasks,
                    ),
            ),
            const SizedBox(width: 18),
            SummaryCard(
              icon: Icons.priority_high_rounded,
              label: strings.urgent,
              count: urgentTasks.length,
              color: FlowlyColors.orange,
              onTap: urgentTasks.isEmpty
                  ? null
                  : () => _showSummaryDialog(
                      title: strings.urgent,
                      icon: Icons.priority_high_rounded,
                      color: FlowlyColors.orange,
                      tasks: urgentTasks,
                    ),
            ),
          ],
        ),
      );
    }

    Widget buildCalendarCard() {
      return CalendarCard(
        calendarDate: _calendarDate,
        selectedDate: _selectedDate,
        tasks: _tasks,
        onPrevious: () => setState(() {
          _calendarDate = DateTime(_calendarDate.year, _calendarDate.month - 1);
        }),
        onNext: () => setState(() {
          _calendarDate = DateTime(_calendarDate.year, _calendarDate.month + 1);
        }),
        onSelect: (date) => setState(() {
          _selectedDate = date;
          _calendarDate = DateTime(date.year, date.month);
        }),
      );
    }

    Widget buildSearchRow() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 64,
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                cursorColor: FlowlyColors.primary,
                style: TextStyle(
                  color: searchTextColor,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: (value) => setState(() => _keyword = value),
                decoration: InputDecoration(
                  hintText: strings.search,
                  hintStyle: TextStyle(
                    color: searchHintColor,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: searchFillColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 64,
                    minHeight: 64,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: searchBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: searchBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: FlowlyColors.primary),
                  ),
                  suffixIcon: Icon(Icons.search, color: searchIconColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          FlowlyIconButton(
            icon: Icons.add,
            size: 64,
            iconSize: 30,
            tooltip: strings.add,
            onPressed: () => showTaskFormSheet(
              context,
              repository: widget.repository,
              selectedDate: _selectedDate,
              showAdvancedFields: false,
              onTaskSaved: _upsertTask,
            ),
          ),
        ],
      );
    }

    List<Widget> buildDailyTaskTiles() {
      if (dailyTasks.isEmpty) {
        return [EmptyState(message: strings.noTasks)];
      }

      return dailyTasks.map((task) {
        final hiding = _hidingTaskIds.contains(task.id);
        return AnimatedPadding(
          duration: _taskExitDuration,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: hiding ? 0 : 14),
          child: HomeTaskTile(
            task: task,
            pendingDone: _pendingDoneIds.contains(task.id),
            hiding: hiding,
            onDoneToggle: () => _togglePendingDone(task),
            onEdit: () {
              _cancelPendingDone(task);
              showTaskFormSheet(
                context,
                repository: widget.repository,
                selectedDate: task.taskDate ?? DateTime.now(),
                task: task,
                onTaskSaved: _upsertTask,
              );
            },
            onTogglePriority: () => _togglePriority(task),
            onDelete: () => _delete(task),
          ),
        );
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const LoadingState()
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AdaptivePage(
                maxWidth: 1100,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final useTabletLayout = constraints.maxWidth >= 860;

                    if (useTabletLayout) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSummaryCards(),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: buildCalendarCard()),
                              const SizedBox(width: 26),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    buildSearchRow(),
                                    const SizedBox(height: 22),
                                    ...buildDailyTaskTiles(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildSummaryCards(),
                        const SizedBox(height: 22),
                        buildCalendarCard(),
                        const SizedBox(height: 26),
                        buildSearchRow(),
                        const SizedBox(height: 22),
                        ...buildDailyTaskTiles(),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = flowlyPageTextColor(context);
    final mutedColor = flowlyPageMutedColor(context);

    return FlowlyGlass(
      width: 170,
      height: 92,
      borderRadius: BorderRadius.circular(22),
      tint: color.withValues(alpha: 0.20),
      borderColor: color.withValues(alpha: 0.28),
      blur: 28,
      shadows: const [],
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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

class _SummaryTaskDialog extends StatelessWidget {
  const _SummaryTaskDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
    required this.taskDate,
    required this.onSelect,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<FlowlyTask> tasks;
  final DateTime Function(FlowlyTask task) taskDate;
  final ValueChanged<FlowlyTask> onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final itemLabel = strings.isEnglish ? 'items' : 'lời nhắc';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: FlowlyGlass(
        width: double.infinity,
        borderRadius: BorderRadius.circular(30),
        tint: Colors.white.withValues(alpha: 0.90),
        borderColor: _sheetBorderColor(0.30),
        blur: 34,
        shadows: _sheetShadows(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${tasks.length} $itemLabel',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  FlowlyGlass(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.circular(21),
                    tint: Colors.white.withValues(alpha: 0.76),
                    borderColor: _sheetBorderColor(0.28),
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
              const SizedBox(height: 16),
              if (tasks.isEmpty)
                EmptyState(message: strings.noTasks)
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _SummaryTaskRow(
                        task: task,
                        date: taskDate(task),
                        color: color,
                        onTap: () => onSelect(task),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTaskRow extends StatelessWidget {
  const _SummaryTaskRow({
    required this.task,
    required this.date,
    required this.color,
    required this.onTap,
  });

  final FlowlyTask task;
  final DateTime date;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final tagColor = flowlyTaskTagColor(task.tagColor);

    return FlowlyGlass(
      width: double.infinity,
      borderRadius: BorderRadius.circular(20),
      tint: Colors.white.withValues(alpha: 0.76),
      borderColor: _sheetBorderColor(0.32),
      blur: 22,
      shadows: const [],
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                _SummaryDateBadge(date: date, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tagColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${displayDate(date)} - ${strings.statusLabel(task.status)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: FlowlyColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryDateBadge extends StatelessWidget {
  const _SummaryDateBadge({required this.date, required this.color});

  final DateTime date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date.day.toString().padLeft(2, '0'),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${strings.isEnglish ? 'M' : 'T'}${date.month}',
            style: TextStyle(
              color: color.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarCard extends StatelessWidget {
  const CalendarCard({
    super.key,
    required this.calendarDate,
    required this.selectedDate,
    required this.tasks,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  final DateTime calendarDate;
  final DateTime selectedDate;
  final List<FlowlyTask> tasks;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final cells = monthCells(calendarDate);
    final calendarRows = (cells.length / 7).ceil() + 1;
    final isTablet = MediaQuery.sizeOf(context).width >= 700;
    final cellHeight = isTablet ? 58.0 : 46.0;
    final gridHeight = calendarRows * cellHeight;
    final weekdayLabels = strings.isEnglish
        ? strings.weekdayShort
        : const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final selectedKey = dateKey(selectedDate);
    final todayKey = dateKey(DateTime.now());
    final taskDates = tasks
        .where((task) => task.isIncomplete)
        .map((task) => task.taskDate == null ? '' : dateKey(task.taskDate!))
        .toSet();

    return FlowlyGlass(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      borderRadius: BorderRadius.circular(28),
      tint: Colors.white.withValues(alpha: 0.80),
      borderColor: Colors.white.withValues(alpha: 0.92),
      blur: 28,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${strings.monthNames[calendarDate.month - 1]}, ${calendarDate.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: gridHeight,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weekdayLabels.length + cells.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: cellHeight,
              ),
              itemBuilder: (context, index) {
                if (index < weekdayLabels.length) {
                  return Center(
                    child: Text(
                      weekdayLabels[index],
                      style: TextStyle(
                        color: index == 6
                            ? const Color(0xFFD92D20)
                            : FlowlyColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                final date = cells[index - weekdayLabels.length];
                final key = dateKey(date);
                final isSelected = key == selectedKey;
                final isToday = key == todayKey;
                final muted = date.month != calendarDate.month;
                final hasTask = taskDates.contains(key);
                final isHoliday = isHolidayOrSunday(date);

                return GestureDetector(
                  onTap: () => onSelect(date),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FlowlyColors.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : muted && isHoliday
                                ? const Color(0xFFE4A2A2)
                                : muted
                                ? const Color(0xFFC1C7D7)
                                : isHoliday
                                ? const Color(0xFFD92D20)
                                : FlowlyColors.text,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                        if (hasTask && !isSelected)
                          const Positioned(
                            bottom: 5,
                            child: CircleAvatar(
                              radius: 2.5,
                              backgroundColor: FlowlyColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTaskTile extends StatelessWidget {
  const HomeTaskTile({
    super.key,
    required this.task,
    required this.pendingDone,
    required this.hiding,
    required this.onDoneToggle,
    required this.onEdit,
    required this.onTogglePriority,
    required this.onDelete,
  });

  final FlowlyTask task;
  final bool pendingDone;
  final bool hiding;
  final VoidCallback onDoneToggle;
  final VoidCallback onEdit;
  final VoidCallback onTogglePriority;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Align(
          heightFactor: hiding ? 0.0 : 1.0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            opacity: hiding ? 0 : 1,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              scale: hiding ? 0.985 : 1,
              child: IgnorePointer(
                ignoring: hiding,
                child: _HomeTaskTileBody(
                  task: task,
                  pendingDone: pendingDone,
                  onDoneToggle: onDoneToggle,
                  onEdit: onEdit,
                  onTogglePriority: onTogglePriority,
                  onDelete: onDelete,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTaskTileBody extends StatelessWidget {
  const _HomeTaskTileBody({
    required this.task,
    required this.pendingDone,
    required this.onDoneToggle,
    required this.onEdit,
    required this.onTogglePriority,
    required this.onDelete,
  });

  final FlowlyTask task;
  final bool pendingDone;
  final VoidCallback onDoneToggle;
  final VoidCallback onEdit;
  final VoidCallback onTogglePriority;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onLongPress: () => showHomeTaskActionsSheet(
          context,
          task: task,
          onEdit: onEdit,
          onTogglePriority: onTogglePriority,
          onDelete: onDelete,
        ),
        child: FlowlyGlass(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          borderRadius: BorderRadius.circular(20),
          tint: pendingDone
              ? FlowlyColors.primarySoft.withValues(alpha: 0.88)
              : Colors.white.withValues(alpha: 0.96),
          borderColor: pendingDone
              ? FlowlyColors.primary.withValues(alpha: 0.22)
              : const Color(0xFFE8EEF8),
          blur: 24,
          shadows: [
            BoxShadow(
              color: const Color(0xFF8FA0BA).withValues(alpha: 0.10),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.64),
              blurRadius: 10,
              offset: const Offset(-3, -3),
            ),
          ],
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  opacity: task.isUrgent ? 1 : 0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    scale: task.isUrgent ? 1 : 0.72,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: FlowlyColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: pendingDone ? 0.62 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (task.description.isNotEmpty)
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onDoneToggle,
                tooltip: pendingDone ? 'Hủy hoàn thành' : 'Hoàn thành',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    pendingDone
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    key: ValueKey(pendingDone),
                    size: 34,
                    color: pendingDone
                        ? FlowlyColors.primary
                        : FlowlyColors.muted,
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

Future<void> showHomeTaskActionsSheet(
  BuildContext context, {
  required FlowlyTask task,
  required VoidCallback onEdit,
  required VoidCallback onTogglePriority,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _HomeTaskActionsSheet(
      task: task,
      onEdit: onEdit,
      onTogglePriority: onTogglePriority,
      onDelete: onDelete,
    ),
  );
}

class _HomeTaskActionsSheet extends StatelessWidget {
  const _HomeTaskActionsSheet({
    required this.task,
    required this.onEdit,
    required this.onTogglePriority,
    required this.onDelete,
  });

  final FlowlyTask task;
  final VoidCallback onEdit;
  final VoidCallback onTogglePriority;
  final VoidCallback onDelete;

  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;

    return FlowlyGlass(
      width: double.infinity,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      tint: Colors.white.withValues(alpha: 0.90),
      borderColor: _sheetBorderColor(0.28),
      blur: 32,
      shadows: _sheetShadows(),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FlowlyGlass(
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(22),
                    tint: Colors.white.withValues(alpha: 0.76),
                    borderColor: _sheetBorderColor(0.28),
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
              const SizedBox(height: 16),
              _HomeTaskActionTile(
                icon: task.isUrgent
                    ? Icons.star_border_rounded
                    : Icons.star_rounded,
                label: task.isUrgent
                    ? strings.removePriority
                    : strings.markPriority,
                selected: task.isUrgent,
                onTap: () => _closeThen(context, onTogglePriority),
              ),
              const SizedBox(height: 8),
              _HomeTaskActionTile(
                icon: Icons.edit_outlined,
                label: strings.edit,
                onTap: () => _closeThen(context, onEdit),
              ),
              const SizedBox(height: 8),
              _HomeTaskActionTile(
                icon: Icons.delete_outline_rounded,
                label: strings.delete,
                destructive: true,
                onTap: () => _closeThen(context, onDelete),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTaskActionTile extends StatelessWidget {
  const _HomeTaskActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      height: 54,
      decoration: BoxDecoration(
        color: selected
            ? FlowlyColors.primary
            : destructive
            ? Colors.redAccent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? FlowlyColors.primary
              : destructive
              ? Colors.redAccent.withValues(alpha: 0.18)
              : _sheetBorderColor(0.32),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : destructive
                      ? Colors.redAccent
                      : FlowlyColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : destructive
                          ? Colors.redAccent
                          : FlowlyColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showTaskFormSheet(
  BuildContext context, {
  required FlowlyRepository repository,
  required DateTime selectedDate,
  VoidCallback? onSaved,
  ValueChanged<FlowlyTask>? onTaskSaved,
  FlowlyTask? task,
  bool showAdvancedFields = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TaskFormSheet(
      repository: repository,
      selectedDate: selectedDate,
      task: task,
      onSaved: onSaved,
      onTaskSaved: onTaskSaved,
      showAdvancedFields: showAdvancedFields,
    ),
  );
}

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({
    super.key,
    required this.repository,
    required this.selectedDate,
    this.onSaved,
    this.onTaskSaved,
    this.task,
    this.showAdvancedFields = true,
  });

  final FlowlyRepository repository;
  final DateTime selectedDate;
  final VoidCallback? onSaved;
  final ValueChanged<FlowlyTask>? onTaskSaved;
  final FlowlyTask? task;
  final bool showAdvancedFields;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _date;
  late String _status;
  late String _priority;
  late String _tagColor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _date = task?.taskDate ?? widget.selectedDate;
    _status = task?.status ?? 'new';
    _priority = task?.priority ?? 'normal';
    _tagColor = task?.tagColor ?? 'orange';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final draft = TaskDraft(
        title: title,
        description: _descriptionController.text.trim(),
        taskType: dateKey(_date).compareTo(dateKey(DateTime.now())) > 0
            ? 'future'
            : 'today',
        taskDate: _date,
        status: widget.showAdvancedFields ? _status : 'pending',
        priority: _priority,
        tagColor: _tagColor,
      );
      final payload = draft.toJson();

      final FlowlyTask savedTask;
      if (widget.task == null) {
        savedTask = await widget.repository.createTask(draft);
      } else {
        savedTask = await widget.repository.updateTask(
          widget.task!.id,
          payload,
        );
      }
      widget.onTaskSaved?.call(savedTask);
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) FlowlySnack.show(context, '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDatePickerSheet(initialDate: _date),
    );

    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTagColor() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskTagColorPickerSheet(selectedColor: _tagColor),
    );

    if (picked != null) setState(() => _tagColor = picked);
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: FlowlyGlass(
        width: double.infinity,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        tint: Colors.white.withValues(alpha: 0.84),
        borderColor: _sheetBorderColor(0.28),
        blur: 30,
        shadows: _sheetShadows(),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Form(
              key: _formKey,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.task == null ? strings.add : strings.save,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FlowlyGlass(
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(22),
                        tint: Colors.white.withValues(alpha: 0.76),
                        borderColor: _sheetBorderColor(0.28),
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
                  const SizedBox(height: 18),
                  FlowlyGlass(
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(26),
                    tint: Colors.white.withValues(alpha: 0.72),
                    borderColor: _sheetBorderColor(0.32),
                    blur: 24,
                    shadows: _sheetCardShadows(),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return strings.taskNameRequired;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: strings.taskName,
                            prefixIcon: const Icon(Icons.assignment_outlined),
                            border: _sheetInputBorder(),
                            enabledBorder: _sheetInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: strings.description,
                            prefixIcon: const Icon(Icons.notes_outlined),
                            border: _sheetInputBorder(),
                            enabledBorder: _sheetInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FlowlyGlass(
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(26),
                    tint: Colors.white.withValues(alpha: 0.72),
                    borderColor: _sheetBorderColor(0.32),
                    blur: 24,
                    shadows: _sheetCardShadows(),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _pickDate,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: FlowlyColors.muted,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${strings.date}: ${displayDate(_date)}',
                                      style: const TextStyle(
                                        color: FlowlyColors.text,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: FlowlyColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (widget.showAdvancedFields) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final status in const [
                                'new',
                                'doing',
                                'paused',
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _TaskChoiceButton(
                                      label: strings.statusLabel(status),
                                      selected: _status == status,
                                      onTap: () =>
                                          setState(() => _status = status),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.showAdvancedFields) ...[
                    const SizedBox(height: 14),
                    FlowlyGlass(
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(26),
                      tint: Colors.white.withValues(alpha: 0.72),
                      borderColor: _sheetBorderColor(0.32),
                      blur: 24,
                      shadows: _sheetCardShadows(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  strings.priority,
                                  style: const TextStyle(
                                    color: FlowlyColors.muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              for (var index = 1; index <= 3; index++)
                                IconButton(
                                  onPressed: () => setState(() {
                                    final current = _priorityStars(_priority);
                                    _priority = current == index
                                        ? 'normal'
                                        : _priorityFromStars(index);
                                  }),
                                  icon: Icon(
                                    index <= _priorityStars(_priority)
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: index <= _priorityStars(_priority)
                                        ? FlowlyColors.orange
                                        : const Color(0xFFC6CCD8),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  strings.tag,
                                  style: const TextStyle(
                                    color: FlowlyColors.muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final color
                                      in flowlyDefaultTaskTagColors) ...[
                                    _TagColorButton(
                                      color: flowlyTaskTagColor(color),
                                      selected: _tagColor == color,
                                      onTap: () =>
                                          setState(() => _tagColor = color),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  _CustomTagColorButton(
                                    color: flowlyTaskTagColor(_tagColor),
                                    selected: !flowlyDefaultTaskTagColors
                                        .contains(_tagColor),
                                    onTap: _pickTagColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.task == null ? strings.add : strings.save,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskDatePickerSheet extends StatefulWidget {
  const _TaskDatePickerSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_TaskDatePickerSheet> createState() => _TaskDatePickerSheetState();
}

class _TaskDatePickerSheetState extends State<_TaskDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _calendarDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = dateOnly(widget.initialDate);
    _calendarDate = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final cells = monthCells(_calendarDate);
    final selectedKey = dateKey(_selectedDate);
    final todayKey = dateKey(DateTime.now());
    final weekdayLabels = strings.isEnglish
        ? strings.weekdayShort
        : const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final rows = (cells.length / 7).ceil() + 1;

    return FlowlyGlass(
      width: double.infinity,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      tint: Colors.white.withValues(alpha: 0.90),
      borderColor: _sheetBorderColor(0.28),
      blur: 32,
      shadows: _sheetShadows(),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.isEnglish ? 'Choose date' : 'Chọn ngày',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FlowlyGlass(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.circular(21),
                    tint: Colors.white.withValues(alpha: 0.76),
                    borderColor: _sheetBorderColor(0.28),
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
              const SizedBox(height: 12),
              FlowlyGlass(
                width: double.infinity,
                borderRadius: BorderRadius.circular(28),
                tint: Colors.white.withValues(alpha: 0.76),
                borderColor: _sheetBorderColor(0.32),
                blur: 26,
                shadows: _sheetCardShadows(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${strings.monthNames[_calendarDate.month - 1]}, ${_calendarDate.year}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _calendarDate = DateTime(
                              _calendarDate.year,
                              _calendarDate.month - 1,
                            );
                          }),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _calendarDate = DateTime(
                              _calendarDate.year,
                              _calendarDate.month + 1,
                            );
                          }),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: rows * 44,
                      child: GridView.count(
                        crossAxisCount: 7,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.15,
                        children: [
                          for (
                            var index = 0;
                            index < weekdayLabels.length;
                            index++
                          )
                            Center(
                              child: Text(
                                weekdayLabels[index],
                                style: TextStyle(
                                  color: index == 6
                                      ? const Color(0xFFD92D20)
                                      : FlowlyColors.muted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          for (final date in cells)
                            _TaskDateCell(
                              date: date,
                              currentMonth: _calendarDate.month,
                              selected: dateKey(date) == selectedKey,
                              today: dateKey(date) == todayKey,
                              onTap: () => setState(
                                () => _selectedDate = dateOnly(date),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TaskDateActionButton(
                      label: strings.today,
                      onPressed: () {
                        final today = dateOnly(DateTime.now());
                        setState(() {
                          _selectedDate = today;
                          _calendarDate = DateTime(today.year, today.month);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TaskDateActionButton(
                      label: strings.save,
                      primary: true,
                      onPressed: () => Navigator.pop(context, _selectedDate),
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

class _TaskDateActionButton extends StatelessWidget {
  const _TaskDateActionButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);

    return FlowlyGlass(
      height: 58,
      borderRadius: radius,
      tint: primary
          ? FlowlyColors.primary.withValues(alpha: 0.76)
          : Colors.white.withValues(alpha: 0.74),
      borderColor: primary
          ? FlowlyColors.primary.withValues(alpha: 0.24)
          : _sheetBorderColor(0.32),
      blur: 22,
      shadows: primary
          ? [
              BoxShadow(
                color: FlowlyColors.primary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : const [],
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primary ? Colors.white : FlowlyColors.primary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskDateCell extends StatelessWidget {
  const _TaskDateCell({
    required this.date,
    required this.currentMonth,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final DateTime date;
  final int currentMonth;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = date.month != currentMonth;
    final holiday = isHolidayOrSunday(date);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? FlowlyColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: today && !selected
              ? Border.all(color: FlowlyColors.primary.withValues(alpha: 0.55))
              : null,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : muted && holiday
                  ? const Color(0xFFE4A2A2)
                  : muted
                  ? const Color(0xFFC1C7D7)
                  : holiday
                  ? const Color(0xFFD92D20)
                  : FlowlyColors.text,
              fontWeight: selected || today ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

int _priorityStars(String priority) {
  return switch (priority) {
    'high' || 'urgent' => 3,
    'medium' => 2,
    'low' => 1,
    _ => 0,
  };
}

String _priorityFromStars(int stars) {
  return switch (stars) {
    1 => 'low',
    2 => 'medium',
    3 => 'high',
    _ => 'normal',
  };
}

class _TaskChoiceButton extends StatelessWidget {
  const _TaskChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      height: 50,
      decoration: BoxDecoration(
        color: selected
            ? FlowlyColors.primary
            : Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? FlowlyColors.primary : _sheetBorderColor(0.32),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : FlowlyColors.text,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagColorButton extends StatelessWidget {
  const _TagColorButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTagColorButton extends StatelessWidget {
  const _CustomTagColorButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? color : Colors.white.withValues(alpha: 0.84),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : FlowlyColors.border,
                width: 3,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: selected ? Colors.white : FlowlyColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskTagColorPickerSheet extends StatelessWidget {
  const _TaskTagColorPickerSheet({required this.selectedColor});

  final String selectedColor;

  @override
  Widget build(BuildContext context) {
    return FlowlyGlass(
      width: double.infinity,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      tint: Colors.white.withValues(alpha: 0.90),
      borderColor: _sheetBorderColor(0.28),
      blur: 32,
      shadows: _sheetShadows(),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chọn màu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FlowlyGlass(
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(22),
                    tint: Colors.white.withValues(alpha: 0.76),
                    borderColor: _sheetBorderColor(0.28),
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
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in flowlyTaskTagPickerColors)
                    _TagColorButton(
                      color: flowlyTaskTagColor(color),
                      selected: selectedColor == color,
                      onTap: () => Navigator.pop(context, color),
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
