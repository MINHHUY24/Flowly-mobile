import 'package:flutter_test/flutter_test.dart';
import 'package:flowly_mobile/src/core/l10n.dart';

void main() {
  test('Flowly Vietnamese labels are available', () {
    final strings = AppStrings('vi');

    expect(strings.login, 'Đăng nhập');
    expect(strings.tasks, 'Nhiệm vụ');
  });
}
