import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hau_flutter/main.dart';
import 'package:hau_flutter/providers/auth_provider.dart';

void main() {
  testWidgets('PRIME Attendance smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const PrimeAttendanceApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PRIME ATTENDANCE'), findsOneWidget);
  });
}
