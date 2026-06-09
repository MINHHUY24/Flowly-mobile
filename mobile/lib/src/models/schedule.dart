import '../core/flowly_dates.dart';

class FlowlySchedule {
  const FlowlySchedule({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final DateTime scheduleDate;
  final String startTime;
  final String endTime;
  final String color;
  final String status;

  bool get isDone => status == 'done' || status == 'completed';
  bool get isCancelled => status == 'cancelled' || status == 'canceled';
  bool get isIncomplete => !isDone && !isCancelled;

  factory FlowlySchedule.fromJson(Map<String, dynamic> json) {
    return FlowlySchedule(
      id: '${json['id']}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scheduleDate:
          parseDateKey(json['schedule_date'] as String?) ?? DateTime.now(),
      startTime: json['start_time'] as String? ?? '09:00:00',
      endTime: json['end_time'] as String? ?? '10:00:00',
      color: json['color'] as String? ?? 'blue',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class ScheduleDraft {
  const ScheduleDraft({
    required this.title,
    required this.description,
    required this.scheduleDate,
    required this.startHour,
    required this.endHour,
    required this.color,
    required this.status,
  });

  final String title;
  final String description;
  final DateTime scheduleDate;
  final int startHour;
  final int endHour;
  final String color;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'schedule_date': dateKey(scheduleDate),
      'start_time': sqlTimeFromHour(startHour),
      'end_time': sqlTimeFromHour(endHour),
      'color': color,
      'status': status,
    };
  }
}
