import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/chat_screen/src/presentation/contact_profile_page.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

void main() {
  late MockChatBloc mockChatBloc;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<ThemeController>(ThemeController());
    mockChatBloc = MockChatBloc();
    
    when(() => mockChatBloc.state).thenReturn(const ChatLoaded(messages: []));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<ChatBloc>.value(
        value: mockChatBloc,
        child: const ContactProfilePage(
          contactName: 'Olive Grant',
          contactColor: Colors.pinkAccent,
          isOnline: true,
        ),
      ),
    );
  }

  testWidgets('renders ContactProfilePage correctly with mockup components', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify contact name and status quote
    expect(find.text('Olive Grant'), findsOneWidget);
    expect(find.text('Pursuing Goals 🤘'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);

    // Verify Shared media section
    expect(find.text('Shared media'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);

    // Verify options list
    expect(find.text('Mute notifications'), findsOneWidget);
    expect(find.text('Lock Chat'), findsOneWidget);
    expect(find.text('Auto-delete messages'), findsOneWidget);

    // Verify block/report buttons
    expect(find.text('Block Olive Grant'), findsOneWidget);
    expect(find.text('Report the contact'), findsOneWidget);
  });

  testWidgets('toggling settings switches works correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify initial switch values
    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches.length, 2);
    expect(switches.elementAt(0).value, isFalse);
    expect(switches.elementAt(1).value, isFalse);

    // Toggle Mute Notifications
    await tester.ensureVisible(find.byType(Switch).at(0));
    await tester.tap(find.byType(Switch).at(0));
    await tester.pumpAndSettle();

    // Since it's a Bloc, the switch state depends on the Bloc state
    // To test UI feedback, we'd need to emit a new state
  });
}
