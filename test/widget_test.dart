
import 'package:flutter_test/flutter_test.dart';
import 'package:motora/core/localization/app_locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('App locale defaults to English', () {
    final controller = AppLocaleController();

    expect(controller.locale.languageCode, 'en');
  });
}
