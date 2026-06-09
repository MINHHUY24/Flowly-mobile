import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/flowly_dates.dart';
import '../core/flowly_repository.dart';
import '../core/l10n.dart';
import '../models/schedule.dart';
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

class SchedulePage extends StatefulWidget {
  const SchedulePage({
    super.key,
    required this.repository,
    required this.reloadSignal,
  });

  final FlowlyRepository repository;
  final int reloadSignal;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  var _schedules = <FlowlySchedule>[];
  var _selectedDate = DateTime.now();
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SchedulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadSignal != widget.reloadSignal) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final schedules = await widget.repository.getSchedules();
      if (mounted) setState(() => _schedules = schedules);
    } catch (error) {
      if (mounted) FlowlySnack.show(context, '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<FlowlySchedule> get _selectedSchedules {
    final key = dateKey(_selectedDate);
    final items = _schedules
        .where((item) => item.isIncomplete && dateKey(item.scheduleDate) == key)
        .toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final weekStart = startOfWeek(_selectedDate);
    final weekDates = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final isCurrentWeek =
        dateKey(weekStart) == dateKey(startOfWeek(DateTime.now()));

    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const LoadingState()
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AdaptivePage(
                maxWidth: 900,
                child: Column(
                  children: [
                    Row(
                      children: [
                        FlowlyIconButton(
                          icon: Icons.chevron_left,
                          tooltip: 'Previous',
                          onPressed: () => setState(() {
                            _selectedDate = _selectedDate.subtract(
                              const Duration(days: 7),
                            );
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ScheduleTodayButton(
                            label: isCurrentWeek
                                ? strings.today
                                : '${_selectedDate.month}/${_selectedDate.year}',
                            onTap: () =>
                                setState(() => _selectedDate = DateTime.now()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FlowlyIconButton(
                          icon: Icons.chevron_right,
                          tooltip: 'Next',
                          onPressed: () => setState(() {
                            _selectedDate = _selectedDate.add(
                              const Duration(days: 7),
                            );
                          }),
                        ),
                        const SizedBox(width: 12),
                        FlowlyIconButton(
                          icon: Icons.add,
                          tooltip: strings.add,
                          onPressed: () => showScheduleFormSheet(
                            context,
                            repository: widget.repository,
                            selectedDate: _selectedDate,
                            onSaved: _load,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    WeekStrip(
                      dates: weekDates,
                      selectedDate: _selectedDate,
                      onSelect: (date) => setState(() => _selectedDate = date),
                    ),
                    const SizedBox(height: 22),
                    FlowlyGlass(
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(26),
                      tint: Colors.white.withValues(alpha: 0.78),
                      borderColor: Colors.white.withValues(alpha: 0.92),
                      blur: 28,
                      child: _selectedSchedules.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: EmptyState(message: strings.noSchedules),
                            )
                          : Column(
                              children: [
                                for (var hour = 1; hour <= 23; hour++)
                                  HourRow(
                                    hour: hour,
                                    schedules: _selectedSchedules
                                        .where(
                                          (item) =>
                                              hourFromSqlTime(
                                                item.startTime,
                                                9,
                                              ) ==
                                              hour,
                                        )
                                        .toList(),
                                    onTap: (schedule) => showScheduleFormSheet(
                                      context,
                                      repository: widget.repository,
                                      selectedDate: _selectedDate,
                                      schedule: schedule,
                                      onSaved: _load,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onSelect,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = FlowlyStringsScope.of(context).strings;
    final todayKey = dateKey(DateTime.now());
    final dark = isFlowlyDark(context);
    final inactiveCardColor = dark
        ? FlowlyColors.darkNeutralCard
        : Colors.white.withValues(alpha: 0.76);
    final inactiveBorderColor = dark
        ? FlowlyColors.darkNeutralBorder.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.90);

    Widget buildDay(int index) {
      final selected = dateKey(dates[index]) == dateKey(selectedDate);
      final today = dateKey(dates[index]) == todayKey;

      return GestureDetector(
        onTap: () => onSelect(dates[index]),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 66,
          height: 88,
          decoration: BoxDecoration(
            color: selected
                ? FlowlyColors.primary
                : today
                ? FlowlyColors.primarySoft.withValues(alpha: 0.92)
                : inactiveCardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? FlowlyColors.primary
                  : today
                  ? FlowlyColors.primary.withValues(alpha: 0.22)
                  : inactiveBorderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                strings.weekdayShort[index],
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : today
                      ? FlowlyColors.primary
                      : FlowlyColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${dates[index].day}',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : today
                      ? FlowlyColors.primary
                      : FlowlyColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < dates.length; index++) ...[
                if (index > 0) const SizedBox(width: 14),
                buildDay(index),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < dates.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    right: index == dates.length - 1 ? 0 : 8,
                  ),
                  child: buildDay(index),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleTodayButton extends StatelessWidget {
  const _ScheduleTodayButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowlyGlass(
      height: 46,
      borderRadius: BorderRadius.circular(18),
      tint: FlowlyColors.primarySoft.withValues(alpha: 0.82),
      borderColor: FlowlyColors.primary.withValues(alpha: 0.14),
      blur: 22,
      shadows: [
        BoxShadow(
          color: FlowlyColors.primary.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: FlowlyColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FlowlyColors.primary,
                    fontWeight: FontWeight.w900,
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

class HourRow extends StatelessWidget {
  const HourRow({
    super.key,
    required this.hour,
    required this.schedules,
    required this.onTap,
  });

  final int hour;
  final List<FlowlySchedule> schedules;
  final ValueChanged<FlowlySchedule> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: FlowlyColors.border.withValues(alpha: 0.75),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Text(
                '$hour\n${hour < 12 ? 'AM' : 'PM'}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FlowlyColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  if (schedules.isEmpty)
                    const SizedBox(height: 1)
                  else
                    for (final schedule in schedules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => onTap(schedule),
                          child: ScheduleCard(schedule: schedule),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key, required this.schedule});

  final FlowlySchedule schedule;

  @override
  Widget build(BuildContext context) {
    final color = flowlyScheduleColor(schedule.color);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${timeForDisplay(schedule.startTime)} - ${timeForDisplay(schedule.endTime)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (schedule.description.isNotEmpty)
              Text(
                schedule.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showScheduleFormSheet(
  BuildContext context, {
  required FlowlyRepository repository,
  required DateTime selectedDate,
  required VoidCallback onSaved,
  FlowlySchedule? schedule,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ScheduleFormSheet(
      repository: repository,
      selectedDate: selectedDate,
      onSaved: onSaved,
      schedule: schedule,
    ),
  );
}

class ScheduleFormSheet extends StatefulWidget {
  const ScheduleFormSheet({
    super.key,
    required this.repository,
    required this.selectedDate,
    required this.onSaved,
    this.schedule,
  });

  final FlowlyRepository repository;
  final DateTime selectedDate;
  final VoidCallback onSaved;
  final FlowlySchedule? schedule;

  @override
  State<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<ScheduleFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _date;
  late int _startHour;
  late int _endHour;
  var _repeat = 'none';
  var _repeatCount = 4;
  var _color = 'blue';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    _titleController = TextEditingController(text: schedule?.title ?? '');
    _descriptionController = TextEditingController(
      text: schedule?.description ?? '',
    );
    _date = schedule?.scheduleDate ?? widget.selectedDate;
    _startHour = hourFromSqlTime(schedule?.startTime, 9);
    _endHour = hourFromSqlTime(schedule?.endTime, 10);
    _color = schedule?.color ?? 'blue';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _endHour <= _startHour) return;
    setState(() => _saving = true);
    try {
      final baseDraft = ScheduleDraft(
        title: title,
        description: _descriptionController.text.trim(),
        scheduleDate: _date,
        startHour: _startHour,
        endHour: _endHour,
        color: _color,
        status: 'pending',
      );

      if (widget.schedule != null) {
        await widget.repository.updateSchedule(
          widget.schedule!.id,
          baseDraft.toJson(),
        );
      } else {
        final dates = _repeatDates(_date, _repeat, _repeatCount);
        for (final date in dates) {
          await widget.repository.createSchedule(
            ScheduleDraft(
              title: baseDraft.title,
              description: baseDraft.description,
              scheduleDate: date,
              startHour: baseDraft.startHour,
              endHour: baseDraft.endHour,
              color: _color,
              status: 'pending',
            ),
          );
        }
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) FlowlySnack.show(context, '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final schedule = widget.schedule;
    if (schedule == null) return;
    await widget.repository.deleteSchedule(schedule.id);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleDatePickerSheet(initialDate: _date),
    );

    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickHour({required bool isStart}) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleHourPickerSheet(
        initialHour: isStart ? _startHour : _endHour,
        minHour: isStart ? 0 : _startHour + 1,
        maxHour: isStart ? 23 : 24,
        title: isStart
            ? FlowlyStringsScope.of(context).strings.startHour
            : FlowlyStringsScope.of(context).strings.endHour,
      ),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startHour = picked;
        if (_endHour <= _startHour) _endHour = (_startHour + 1).clamp(1, 24);
      } else {
        _endHour = picked;
      }
    });
  }

  Future<void> _pickColor() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleColorPickerSheet(selectedColor: _color),
    );

    if (picked != null) setState(() => _color = picked);
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
                        strings.schedule,
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
                  tint: Colors.white.withValues(alpha: 0.58),
                  borderColor: _sheetBorderColor(0.30),
                  blur: 24,
                  shadows: _sheetCardShadows(),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: strings.taskName,
                          prefixIcon: const Icon(Icons.assignment_outlined),
                          border: _sheetInputBorder(),
                          enabledBorder: _sheetInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
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
                  tint: Colors.white.withValues(alpha: 0.64),
                  borderColor: _sheetBorderColor(0.32),
                  blur: 24,
                  shadows: _sheetCardShadows(),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  child: Column(
                    children: [
                      _ScheduleDateButton(
                        label: strings.date,
                        value: displayDate(_date),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ScheduleValueButton(
                              label: strings.startHour,
                              value: '$_startHour:00',
                              onTap: () => _pickHour(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ScheduleValueButton(
                              label: strings.endHour,
                              value: '$_endHour:00',
                              onTap: () => _pickHour(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      if (widget.schedule == null) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            strings.repeat,
                            style: const TextStyle(
                              color: FlowlyColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ScheduleChoiceButton(
                              label: strings.noRepeat,
                              selected: _repeat == 'none',
                              onTap: () => setState(() => _repeat = 'none'),
                            ),
                            _ScheduleChoiceButton(
                              label: strings.weekly,
                              selected: _repeat == 'weekly',
                              onTap: () => setState(() => _repeat = 'weekly'),
                            ),
                            _ScheduleChoiceButton(
                              label: strings.monthly,
                              selected: _repeat == 'monthly',
                              onTap: () => setState(() => _repeat = 'monthly'),
                            ),
                            _ScheduleChoiceButton(
                              label: strings.yearly,
                              selected: _repeat == 'yearly',
                              onTap: () => setState(() => _repeat = 'yearly'),
                            ),
                          ],
                        ),
                        if (_repeat != 'none') ...[
                          const SizedBox(height: 12),
                          _RepeatCountStepper(
                            count: _repeatCount,
                            onChanged: (value) =>
                                setState(() => _repeatCount = value),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FlowlyGlass(
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(24),
                  tint: Colors.white.withValues(alpha: 0.72),
                  borderColor: _sheetBorderColor(0.32),
                  blur: 22,
                  shadows: _sheetCardShadows(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.isEnglish ? 'Color' : 'Màu',
                          style: const TextStyle(
                            color: FlowlyColors.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final color in flowlyDefaultScheduleColors) ...[
                            _ScheduleColorButton(
                              label: color,
                              color: flowlyScheduleColor(color),
                              selected: _color == color,
                              onTap: () => setState(() => _color = color),
                            ),
                            const SizedBox(width: 10),
                          ],
                          _ScheduleCustomColorButton(
                            color: flowlyScheduleColor(_color),
                            selected: !flowlyDefaultScheduleColors.contains(
                              _color,
                            ),
                            onTap: _pickColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.schedule != null)
                  Row(
                    children: [
                      Expanded(
                        child: _ScheduleActionButton(
                          label: strings.delete,
                          icon: Icons.delete_outline_rounded,
                          destructive: true,
                          onTap: _delete,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ScheduleActionButton(
                          label: strings.save,
                          primary: true,
                          onTap: _saving ? null : _save,
                        ),
                      ),
                    ],
                  )
                else
                  _ScheduleActionButton(
                    label: strings.add,
                    primary: true,
                    onTap: _saving ? null : _save,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleDateButton extends StatelessWidget {
  const _ScheduleDateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowlyGlass(
      height: 58,
      borderRadius: BorderRadius.circular(20),
      tint: Colors.white.withValues(alpha: 0.78),
      borderColor: _sheetBorderColor(0.32),
      blur: 20,
      shadows: const [],
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: FlowlyColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        color: FlowlyColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(text: '$label: '),
                        TextSpan(
                          text: value,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
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
    );
  }
}

class _ScheduleValueButton extends StatelessWidget {
  const _ScheduleValueButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowlyGlass(
      height: 72,
      borderRadius: BorderRadius.circular(20),
      tint: Colors.white.withValues(alpha: 0.78),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FlowlyColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FlowlyColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.expand_more_rounded,
                      color: FlowlyColors.muted,
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

class _ScheduleChoiceButton extends StatelessWidget {
  const _ScheduleChoiceButton({
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
      height: 42,
      decoration: BoxDecoration(
        color: selected
            ? FlowlyColors.primary
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? FlowlyColors.primary : _sheetBorderColor(0.32),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : FlowlyColors.text,
                  fontSize: 13,
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

class _RepeatCountStepper extends StatelessWidget {
  const _RepeatCountStepper({required this.count, required this.onChanged});

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return FlowlyGlass(
      height: 50,
      borderRadius: BorderRadius.circular(18),
      tint: Colors.white.withValues(alpha: 0.78),
      borderColor: _sheetBorderColor(0.32),
      blur: 18,
      shadows: const [],
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Số lần',
              style: TextStyle(
                color: FlowlyColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged((count - 1).clamp(2, 12)),
            icon: const Icon(Icons.remove_rounded),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: FlowlyColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          IconButton(
            onPressed: () => onChanged((count + 1).clamp(2, 12)),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _ScheduleColorButton extends StatelessWidget {
  const _ScheduleColorButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
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
      ),
    );
  }
}

class _ScheduleCustomColorButton extends StatelessWidget {
  const _ScheduleCustomColorButton({
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

class _ScheduleColorPickerSheet extends StatelessWidget {
  const _ScheduleColorPickerSheet({required this.selectedColor});

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
                  for (final color in flowlySchedulePickerColors)
                    _ScheduleColorButton(
                      label: color,
                      color: flowlyScheduleColor(color),
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

class _ScheduleHourPickerSheet extends StatelessWidget {
  const _ScheduleHourPickerSheet({
    required this.initialHour,
    required this.minHour,
    required this.maxHour,
    required this.title,
  });

  final int initialHour;
  final int minHour;
  final int maxHour;
  final String title;

  @override
  Widget build(BuildContext context) {
    final selectedHour = initialHour.clamp(minHour, maxHour);
    final hourCount = maxHour - minHour + 1;
    final initialOffset = ((selectedHour - minHour) * 64.0)
        .clamp(0.0, (hourCount - 1) * 64.0)
        .toDouble();

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
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              SizedBox(
                height: 320,
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final hour = minHour + index;
                    final selected = hour == selectedHour;
                    return _ScheduleHourTile(
                      hour: hour,
                      selected: selected,
                      onTap: () => Navigator.pop(context, hour),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemCount: hourCount,
                  controller: ScrollController(
                    initialScrollOffset: initialOffset,
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

class _ScheduleHourTile extends StatelessWidget {
  const _ScheduleHourTile({
    required this.hour,
    required this.selected,
    required this.onTap,
  });

  final int hour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(
        color: selected
            ? FlowlyColors.primary
            : Colors.white.withValues(alpha: 0.74),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Text(
              '$hour:00',
              style: TextStyle(
                color: selected ? Colors.white : FlowlyColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleDatePickerSheet extends StatefulWidget {
  const _ScheduleDatePickerSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_ScheduleDatePickerSheet> createState() =>
      _ScheduleDatePickerSheetState();
}

class _ScheduleDatePickerSheetState extends State<_ScheduleDatePickerSheet> {
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
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
                            _ScheduleDateCell(
                              date: date,
                              currentMonth: _calendarDate.month,
                              selected: dateKey(date) == selectedKey,
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
              _ScheduleActionButton(
                label: strings.save,
                primary: true,
                onTap: () => Navigator.pop(context, _selectedDate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleDateCell extends StatelessWidget {
  const _ScheduleDateCell({
    required this.date,
    required this.currentMonth,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final int currentMonth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = date.month != currentMonth;
    final holiday = isHolidayOrSunday(date);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? FlowlyColors.primary : Colors.transparent,
          shape: BoxShape.circle,
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
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleActionButton extends StatelessWidget {
  const _ScheduleActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : FlowlyColors.primary;

    return FlowlyGlass(
      height: 58,
      borderRadius: BorderRadius.circular(24),
      tint: primary
          ? FlowlyColors.primary.withValues(alpha: 0.78)
          : Colors.white.withValues(alpha: 0.76),
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
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: primary ? Colors.white : color),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: primary ? Colors.white : color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<DateTime> _repeatDates(DateTime start, String repeat, int count) {
  final safeCount = repeat == 'none' ? 1 : count.clamp(1, 52);
  return [
    for (var index = 0; index < safeCount; index++)
      switch (repeat) {
        'weekly' => start.add(Duration(days: index * 7)),
        'monthly' => DateTime(start.year, start.month + index, start.day),
        'yearly' => DateTime(start.year + index, start.month, start.day),
        _ => start,
      },
  ];
}
