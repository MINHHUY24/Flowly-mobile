import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/flowly_dates.dart';
import '../core/flowly_repository.dart';
import '../core/l10n.dart';
import '../models/task.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/common_widgets.dart';
import 'home_page.dart';

const _taskStatusOrder = ['new', 'doing', 'paused', 'done', 'cancelled'];

class TasksPage extends StatefulWidget {
  const TasksPage({
    super.key,
    required this.repository,
    required this.reloadSignal,
  });

  final FlowlyRepository repository;
  final int reloadSignal;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  var _tasks = <FlowlyTask>[];
  var _loading = true;
  var _selectedStatus = 'new';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TasksPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadSignal != widget.reloadSignal) _load();
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

  Future<void> _changeStatus(FlowlyTask task, String status) async {
    await widget.repository.updateTaskStatus(task.id, status);
    await _load();
  }

  Future<void> _delete(FlowlyTask task) async {
    await widget.repository.deleteTask(task.id);
    await _load();
  }

  List<FlowlyTask> get _visibleTasks {
    return _tasks.where((task) {
      final normalized = task.status == 'completed'
          ? 'done'
          : task.status == 'canceled'
          ? 'cancelled'
          : task.status;
      return normalized == _selectedStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final dark = isFlowlyDark(context);
    final pageTextColor = flowlyPageTextColor(context);
    final chipBackgroundColor = dark
        ? FlowlyColors.darkNeutralCard
        : Colors.white.withValues(alpha: 0.74);
    final chipBorderColor = dark
        ? FlowlyColors.darkNeutralBorder.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.92);

    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const LoadingState()
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AdaptivePage(
                maxWidth: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          strings.tasks,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: pageTextColor),
                        ),
                        const Spacer(),
                        FlowlyIconButton(
                          icon: Icons.add,
                          tooltip: strings.add,
                          onPressed: () => showTaskFormSheet(
                            context,
                            repository: widget.repository,
                            selectedDate: DateTime.now(),
                            onSaved: _load,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stretchFilters = constraints.maxWidth >= 760;

                        if (stretchFilters) {
                          return Row(
                            children: [
                              for (
                                var index = 0;
                                index < _taskStatusOrder.length;
                                index++
                              ) ...[
                                if (index > 0) const SizedBox(width: 12),
                                Expanded(
                                  child: _TaskStatusFilterButton(
                                    label: strings.statusLabel(
                                      _taskStatusOrder[index],
                                    ),
                                    selected:
                                        _selectedStatus ==
                                        _taskStatusOrder[index],
                                    backgroundColor: chipBackgroundColor,
                                    borderColor: chipBorderColor,
                                    onTap: () => setState(
                                      () => _selectedStatus =
                                          _taskStatusOrder[index],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final status in _taskStatusOrder)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _TaskStatusFilterButton(
                                    label: strings.statusLabel(status),
                                    selected: _selectedStatus == status,
                                    backgroundColor: chipBackgroundColor,
                                    borderColor: chipBorderColor,
                                    onTap: () => setState(
                                      () => _selectedStatus = status,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    if (_visibleTasks.isEmpty)
                      EmptyState(message: strings.noTasks)
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final useGrid = constraints.maxWidth >= 760;
                          final spacing = useGrid ? 18.0 : 0.0;
                          final itemWidth = useGrid
                              ? (constraints.maxWidth - spacing) / 2
                              : constraints.maxWidth;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: 18,
                            children: [
                              for (final task in _visibleTasks)
                                SizedBox(
                                  width: itemWidth,
                                  child: KanbanTaskCard(
                                    task: task,
                                    onEdit: () => showTaskFormSheet(
                                      context,
                                      repository: widget.repository,
                                      selectedDate:
                                          task.taskDate ?? DateTime.now(),
                                      task: task,
                                      onSaved: _load,
                                    ),
                                    onDelete: () => _delete(task),
                                    onChangeStatus: (status) =>
                                        _changeStatus(task, status),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TaskStatusFilterButton extends StatelessWidget {
  const _TaskStatusFilterButton({
    required this.label,
    required this.selected,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 48,
      constraints: const BoxConstraints(minWidth: 110),
      decoration: BoxDecoration(
        color: selected ? FlowlyColors.primary : backgroundColor,
        borderRadius: radius,
        border: Border.all(
          color: selected ? FlowlyColors.primary : borderColor,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: FlowlyColors.primary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : FlowlyColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KanbanTaskCard extends StatelessWidget {
  const KanbanTaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
  });

  final FlowlyTask task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final tagColor = flowlyTaskTagColor(task.tagColor);

    return GestureDetector(
      onLongPress: () => showTaskActionsSheet(
        context,
        task: task,
        onEdit: onEdit,
        onDelete: onDelete,
        onChangeStatus: onChangeStatus,
      ),
      child: FlowlyGlass(
        width: double.infinity,
        borderRadius: BorderRadius.circular(24),
        tint: Colors.white.withValues(alpha: 0.80),
        borderColor: Colors.white.withValues(alpha: 0.92),
        blur: 26,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: tagColor, width: 5)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: tagColor.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Text(
                            task.tagColor.toUpperCase(),
                            style: TextStyle(
                              color: tagColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  FlowlyGlass(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.circular(16),
                    tint: Colors.white.withValues(alpha: 0.74),
                    borderColor: Colors.white.withValues(alpha: 0.92),
                    blur: 18,
                    shadows: const [],
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Tùy chọn',
                      onPressed: () => showTaskActionsSheet(
                        context,
                        task: task,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onChangeStatus: onChangeStatus,
                      ),
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: FlowlyColors.muted,
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  task.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 14),
              const Divider(color: FlowlyColors.border),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: FlowlyColors.primarySoft.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: FlowlyColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: FlowlyColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayDate(
                            task.taskDate ?? task.createdAt ?? DateTime.now(),
                          ),
                          style: const TextStyle(
                            color: FlowlyColors.muted,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  for (var index = 1; index <= 3; index++)
                    Icon(
                      index <= _priorityStars(task.priority)
                          ? Icons.star
                          : Icons.star_border,
                      color: FlowlyColors.orange,
                      size: 20,
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

Future<void> showTaskActionsSheet(
  BuildContext context, {
  required FlowlyTask task,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required ValueChanged<String> onChangeStatus,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _TaskActionsSheet(
      task: task,
      onEdit: onEdit,
      onDelete: onDelete,
      onChangeStatus: onChangeStatus,
    ),
  );
}

class _TaskActionsSheet extends StatelessWidget {
  const _TaskActionsSheet({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
  });

  final FlowlyTask task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onChangeStatus;

  String get _normalizedStatus {
    return switch (task.status) {
      'completed' => 'done',
      'canceled' => 'cancelled',
      _ => task.status,
    };
  }

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
      borderColor: Colors.white.withValues(alpha: 0.94),
      blur: 32,
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
                    borderColor: Colors.white.withValues(alpha: 0.90),
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
              _TaskActionTile(
                icon: Icons.edit_outlined,
                label: strings.edit,
                onTap: () => _closeThen(context, onEdit),
              ),
              const SizedBox(height: 14),
              Text(
                'Trạng thái',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final status in _taskStatusOrder)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskActionTile(
                    icon: _statusIcon(status),
                    label: strings.statusLabel(status),
                    selected: _normalizedStatus == status,
                    onTap: () =>
                        _closeThen(context, () => onChangeStatus(status)),
                  ),
                ),
              const SizedBox(height: 6),
              _TaskActionTile(
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

class _TaskActionTile extends StatelessWidget {
  const _TaskActionTile({
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
    final color = destructive ? Colors.redAccent : FlowlyColors.primary;

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
              : Colors.white.withValues(alpha: 0.92),
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
                      : color,
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

IconData _statusIcon(String status) {
  return switch (status) {
    'new' => Icons.fiber_new_rounded,
    'doing' => Icons.pending_actions_rounded,
    'paused' => Icons.pause_circle_outline_rounded,
    'done' => Icons.check_circle_outline_rounded,
    'cancelled' => Icons.cancel_outlined,
    _ => Icons.circle_outlined,
  };
}

int _priorityStars(String priority) {
  return switch (priority) {
    'high' || 'urgent' => 3,
    'medium' => 2,
    'low' => 1,
    _ => 0,
  };
}
