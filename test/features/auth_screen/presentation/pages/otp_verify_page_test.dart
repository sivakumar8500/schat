import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/features/auth_screen/src/presentation/otp_verify_page.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_bloc.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_state.dart';
import 'package:schat/features/auth_screen/src/presentation/bloc/auth_event.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockAuthBloc mockAuthBloc;

  setUp(() async {
    mockAuthRepository = MockAuthRepository();
    mockAuthBloc = MockAuthBloc();
    await getIt.reset();
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);
    getIt.registerSingleton<ThemeController>(ThemeController());
    
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const OtpVerifyPage(mobileNumber: '9999999999', autoFill: false),
      ),
    );
  }

  testWidgets('renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify key titles and texts exist
    expect(find.text('Enter the '), findsOneWidget);
    expect(find.text('Code'), findsNWidgets(2));
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('Resend the code in'), findsOneWidget);
  });

  testWidgets('pasting a 6-digit code auto-fills all fields', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Enter paste text into the first TextField
    final firstField = find.byType(TextField).first;
    await tester.enterText(firstField, '654321');
    await tester.pump();

    // Verify all TextFields are filled
    final textFields = tester.widgetList<TextField>(find.byType(TextField));
    expect(textFields.elementAt(0).controller?.text, '6');
    expect(textFields.elementAt(1).controller?.text, '5');
    expect(textFields.elementAt(2).controller?.text, '4');
    expect(textFields.elementAt(3).controller?.text, '3');
    expect(textFields.elementAt(4).controller?.text, '2');
    expect(textFields.elementAt(5).controller?.text, '1');
  });

  testWidgets('backspace in empty box focuses previous box and clears it', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final textFields = find.byType(TextField);
    
    // Tap the second TextField to focus it and type a digit
    await tester.tap(textFields.at(1));
    await tester.enterText(textFields.at(1), '5');
    await tester.pump();

    // Request focus on the third TextField to simulate typing position
    await tester.tap(textFields.at(2));
    await tester.pump();

    // Press backspace key (which will trigger key event on the focused third box)
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    // The second TextField should now be empty
    final textFieldsWidgets = tester.widgetList<TextField>(find.byType(TextField));
    expect(textFieldsWidgets.elementAt(1).controller?.text, '');
  });
}
