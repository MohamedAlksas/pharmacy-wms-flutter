import 'package:flutter_test/flutter_test.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login screen when no stored session exists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initialize();

    await tester.pumpWidget(const PharmacyLoginApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('PHARMACY LOGISTICS'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
