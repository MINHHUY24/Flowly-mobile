import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule.dart';
import '../models/task.dart';
import 'api_client.dart';
import 'app_config.dart';
import 'flowly_dates.dart';

class FlowlyRepository {
  FlowlyRepository({required AppConfig config})
    : _api = ApiClient(config: config);

  final ApiClient _api;

  Future<List<FlowlyTask>> getTasks() async {
    final result = await _api.get('/api/tasks');
    final tasks = result['tasks'] as List<dynamic>? ?? [];
    return tasks
        .whereType<Map<String, dynamic>>()
        .map(FlowlyTask.fromJson)
        .toList();
  }

  Future<FlowlyTask> createTask(TaskDraft draft) async {
    final result = await _api.post('/api/tasks', draft.toJson());
    return FlowlyTask.fromJson(result['task'] as Map<String, dynamic>);
  }

  Future<FlowlyTask> updateTask(String id, Map<String, dynamic> payload) async {
    final result = await _api.put('/api/tasks/$id', payload);
    return FlowlyTask.fromJson(result['task'] as Map<String, dynamic>);
  }

  Future<FlowlyTask> updateTaskStatus(String id, String status) async {
    final result = await _api.patch('/api/tasks/$id/status', {
      'status': status,
    });
    return FlowlyTask.fromJson(result['task'] as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    await _api.delete('/api/tasks/$id');
  }

  Future<List<FlowlySchedule>> getSchedules() async {
    final result = await _api.get('/api/schedules');
    final schedules = result['schedules'] as List<dynamic>? ?? [];
    return schedules
        .whereType<Map<String, dynamic>>()
        .map(FlowlySchedule.fromJson)
        .toList();
  }

  Future<FlowlySchedule> createSchedule(ScheduleDraft draft) async {
    final result = await _api.post('/api/schedules', draft.toJson());
    return FlowlySchedule.fromJson(result['schedule'] as Map<String, dynamic>);
  }

  Future<FlowlySchedule> updateSchedule(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final result = await _api.put('/api/schedules/$id', payload);
    return FlowlySchedule.fromJson(result['schedule'] as Map<String, dynamic>);
  }

  Future<void> deleteSchedule(String id) async {
    await _api.delete('/api/schedules/$id');
  }

  Future<Map<String, dynamic>> parseAi(String message, String page) async {
    final result = await _api.post('/api/ai/parse', {
      'message': message,
      'page': page,
      'path': '/$page',
    });
    return result['result'] as Map<String, dynamic>? ?? {};
  }

  Future<List<Object>> createFromAi(String message, String page) async {
    final result = await parseAi(message, page);
    final items = result['items'] as List<dynamic>? ?? [];
    final type = result['type'] as String? ?? page;
    final created = <Object>[];

    if (type == 'schedule') {
      for (final item in items.whereType<Map<String, dynamic>>()) {
        final title = (item['title'] as String? ?? '').trim();
        if (title.isEmpty) continue;
        final start = item['start_time'] as String? ?? '09:00:00';
        final startHour = hourFromSqlTime(start, 9);
        final endHour = hourFromSqlTime(
          item['end_time'] as String?,
          startHour + 1,
        );
        created.add(
          await createSchedule(
            ScheduleDraft(
              title: title,
              description: item['description'] as String? ?? '',
              scheduleDate:
                  parseDateKey(item['schedule_date'] as String?) ??
                  parseDateKey(item['task_date'] as String?) ??
                  DateTime.now(),
              startHour: startHour,
              endHour: endHour <= startHour ? startHour + 1 : endHour,
              color: item['color'] as String? ?? 'blue',
              status: 'pending',
            ),
          ),
        );
      }
      return created;
    }

    for (final item in items.whereType<Map<String, dynamic>>()) {
      final title = (item['title'] as String? ?? '').trim();
      if (title.isEmpty) continue;
      created.add(
        await createTask(
          TaskDraft(
            title: title,
            description: item['description'] as String? ?? '',
            taskType: item['task_type'] as String? ?? 'today',
            taskDate:
                parseDateKey(item['task_date'] as String?) ?? DateTime.now(),
            status: page == 'tasks' ? 'new' : 'pending',
            priority: item['priority'] as String? ?? 'normal',
            tagColor: item['tag_color'] as String? ?? 'orange',
          ),
        ),
      );
    }

    return created;
  }

  User? get currentUser => Supabase.instance.client.auth.currentUser;
}
