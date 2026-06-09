import '../core/flowly_dates.dart';

class FlowlyTask {
  const FlowlyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    required this.taskDate,
    required this.status,
    required this.priority,
    required this.tagColor,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String taskType;
  final DateTime? taskDate;
  final String status;
  final String priority;
  final String tagColor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDone => status == 'done' || status == 'completed';
  bool get isCancelled => status == 'cancelled' || status == 'canceled';
  bool get isIncomplete => !isDone && !isCancelled;
  bool get isKanban => const ['new', 'doing', 'paused'].contains(status);
  bool get isUrgent => const ['urgent', 'high'].contains(priority);

  FlowlyTask copyWith({
    String? id,
    String? title,
    String? description,
    String? taskType,
    DateTime? taskDate,
    String? status,
    String? priority,
    String? tagColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlowlyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      taskDate: taskDate ?? this.taskDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tagColor: tagColor ?? this.tagColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FlowlyTask.fromJson(Map<String, dynamic> json) {
    return FlowlyTask(
      id: '${json['id']}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      taskType: json['task_type'] as String? ?? 'today',
      taskDate: parseDateKey(json['task_date'] as String?),
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as String? ?? 'normal',
      tagColor: json['tag_color'] as String? ?? 'orange',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toPayload({
    String? title,
    String? description,
    String? taskType,
    DateTime? taskDate,
    String? status,
    String? priority,
    String? tagColor,
  }) {
    return {
      'title': title ?? this.title,
      'description': description ?? this.description,
      'task_type': taskType ?? this.taskType,
      'task_date': dateKey(taskDate ?? this.taskDate ?? DateTime.now()),
      'status': status ?? this.status,
      'priority': priority ?? this.priority,
      'tag_color': tagColor ?? this.tagColor,
    };
  }
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.taskType,
    required this.taskDate,
    required this.status,
    required this.priority,
    required this.tagColor,
  });

  final String title;
  final String description;
  final String taskType;
  final DateTime taskDate;
  final String status;
  final String priority;
  final String tagColor;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'task_type': taskType,
      'task_date': dateKey(taskDate),
      'status': status,
      'priority': priority,
      'tag_color': tagColor,
    };
  }
}
