import 'package:flutter/material.dart';

class FlowlyStringsScope extends InheritedWidget {
  const FlowlyStringsScope({
    super.key,
    required this.strings,
    required this.language,
    required this.onChangeLanguage,
    required this.themeMode,
    required this.onChangeThemeMode,
    required super.child,
  });

  final AppStrings strings;
  final String language;
  final Future<void> Function(String language) onChangeLanguage;
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode themeMode) onChangeThemeMode;

  static FlowlyStringsScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FlowlyStringsScope>();
    assert(scope != null, 'FlowlyStringsScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(FlowlyStringsScope oldWidget) {
    return language != oldWidget.language || themeMode != oldWidget.themeMode;
  }
}

class AppStrings {
  AppStrings(this.language);

  final String language;

  bool get isEnglish => language == 'en';

  String get login => isEnglish ? 'Log in' : 'Đăng nhập';
  String get register => isEnglish ? 'Register' : 'Đăng ký';
  String get password => isEnglish ? 'Password' : 'Nhập mật khẩu';
  String get confirmPassword =>
      isEnglish ? 'Confirm password' : 'Nhập lại mật khẩu';
  String get forgotPassword =>
      isEnglish ? 'Forgot password?' : 'Quên mật khẩu?';
  String get loginWithGoogle =>
      isEnglish ? 'Continue with Google' : 'Đăng nhập với Google';
  String get loginWithFacebook =>
      isEnglish ? 'Continue with Facebook' : 'Đăng nhập với Facebook';
  String get alreadyHaveAccount =>
      isEnglish ? 'Already have an account?' : 'Đã có tài khoản?';
  String get email => 'Email';
  String get sendRequest => isEnglish ? 'Send request' : 'Gửi yêu cầu';
  String get backToLogin => isEnglish ? 'Back to login' : 'Quay lại đăng nhập';
  String get loginSuccess =>
      isEnglish ? 'Login successful' : 'Đăng nhập thành công';
  String get today => isEnglish ? 'Today' : 'Hôm nay';
  String get planned => isEnglish ? 'Planned' : 'Lịch dự kiến';
  String get urgent => isEnglish ? 'Urgent' : 'Khẩn cấp';
  String get search => isEnglish ? 'Search.....' : 'Tìm kiếm.....';
  String get add => isEnglish ? 'Add' : 'Thêm';
  String get edit => isEnglish ? 'Edit' : 'Sửa';
  String get save => isEnglish ? 'Save' : 'Lưu';
  String get cancel => isEnglish ? 'Cancel' : 'Hủy';
  String get delete => isEnglish ? 'Delete' : 'Xóa';
  String get close => isEnglish ? 'Close' : 'Đóng';
  String get taskName => isEnglish ? 'Task name' : 'Tên nhiệm vụ';
  String get taskNameRequired =>
      isEnglish ? 'Task name is required' : 'Tên nhiệm vụ không được để trống';
  String get description => isEnglish ? 'Description' : 'Mô tả';
  String get home => isEnglish ? 'Home' : 'Trang chủ';
  String get schedule => isEnglish ? 'Schedule' : 'Lịch trình';
  String get tasks => isEnglish ? 'Tasks' : 'Nhiệm vụ';
  String get newTask => isEnglish ? 'New task' : 'Mới';
  String get doing => isEnglish ? 'Doing' : 'Đang thực hiện';
  String get paused => isEnglish ? 'Paused' : 'Tạm hoãn';
  String get done => isEnglish ? 'Done' : 'Đã xử lý';
  String get cancelled => isEnglish ? 'Cancelled' : 'Đã hủy';
  String get account => isEnglish ? 'Account' : 'Tài khoản';
  String get editProfile => isEnglish ? 'Edit profile' : 'Chỉnh sửa thông tin';
  String get history => isEnglish ? 'History' : 'Lịch sử';
  String get languageLabel => isEnglish ? 'Language' : 'Ngôn ngữ';
  String get appearance => isEnglish ? 'Appearance' : 'Giao diện';
  String get systemMode => isEnglish ? 'Auto' : 'Tự động';
  String get lightMode => isEnglish ? 'Light' : 'Sáng';
  String get darkMode => isEnglish ? 'Dark' : 'Tối';
  String get logout => isEnglish ? 'Log out' : 'Đăng xuất';
  String get noTasks =>
      isEnglish ? 'No tasks for this day' : 'Không có nhiệm vụ cho ngày này';
  String get noSchedules =>
      isEnglish ? 'No schedule yet' : 'Chưa có lịch trình';
  String get flowlyBot => 'Flowly Bot';
  String get botPlaceholder => isEnglish
      ? 'Example: I need to study and go to a meeting today'
      : 'Ví dụ: Hôm nay tôi cần làm: học bài, đi họp';
  String get botWelcome => isEnglish
      ? 'Hi, I can create tasks or schedules from your text.'
      : 'Xin chào, mình có thể tạo task hoặc lịch từ câu bạn nhập.';
  String get botThinking =>
      isEnglish ? 'Reading your request' : 'Mình đang đọc yêu cầu của bạn';
  String get profileName => isEnglish ? 'Name' : 'Tên';
  String get phone => isEnglish ? 'Phone number' : 'Số điện thoại';
  String get birthday => isEnglish ? 'Birthday' : 'Ngày sinh';
  String get priority => isEnglish ? 'Priority' : 'Mức độ ưu tiên';
  String get markPriority =>
      isEnglish ? 'Mark as priority' : 'Đánh dấu ưu tiên';
  String get removePriority => isEnglish ? 'Remove priority' : 'Bỏ ưu tiên';
  String get tag => isEnglish ? 'Tag' : 'Thẻ';
  String get startHour => isEnglish ? 'Start hour' : 'Giờ bắt đầu';
  String get endHour => isEnglish ? 'End hour' : 'Giờ kết thúc';
  String get date => isEnglish ? 'Date' : 'Ngày';
  String get repeat => isEnglish ? 'Repeat' : 'Lặp lại';
  String get noRepeat => isEnglish ? 'No repeat' : 'Không lặp';
  String get weekly => isEnglish ? 'Weekly' : 'Mỗi tuần';
  String get monthly => isEnglish ? 'Monthly' : 'Mỗi tháng';
  String get yearly => isEnglish ? 'Yearly' : 'Mỗi năm';
  String get configTitle =>
      isEnglish ? 'Configuration needed' : 'Cần cấu hình ứng dụng';

  List<String> get monthNames => isEnglish
      ? const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ]
      : const [
          'Tháng 1',
          'Tháng 2',
          'Tháng 3',
          'Tháng 4',
          'Tháng 5',
          'Tháng 6',
          'Tháng 7',
          'Tháng 8',
          'Tháng 9',
          'Tháng 10',
          'Tháng 11',
          'Tháng 12',
        ];

  List<String> get weekdayShort => const [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  String statusLabel(String status) {
    return switch (status) {
      'new' => newTask,
      'doing' => doing,
      'paused' => paused,
      'done' || 'completed' => done,
      'cancelled' || 'canceled' => cancelled,
      _ => newTask,
    };
  }
}
