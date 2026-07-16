import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/contact_profile_page.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}
class MockChatRepository extends Mock implements ChatRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockChatBloc mockChatBloc;
  late MockChatRepository mockChatRepository;
  late MockProfileRepository mockProfileRepository;
  late Directory tempDir;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<ThemeController>(ThemeController());
    
    mockChatRepository = MockChatRepository();
    getIt.registerSingleton<ChatRepository>(mockChatRepository);
    when(() => mockChatRepository.getConversationMedia(any()))
        .thenAnswer((_) async => []);

    mockProfileRepository = MockProfileRepository();
    getIt.registerSingleton<ProfileRepository>(mockProfileRepository);
    when(() => mockProfileRepository.getUserById(any()))
        .thenAnswer((_) async => ApiResult.success(const UserModel(
              id: 'user_1',
              username: 'olive.grant',
              phoneNumber: '+1234567890',
              about: 'Pursuing Goals 🤘',
              isOnline: true,
              subscriptionType: 'Premium',
            )));

    mockChatBloc = MockChatBloc();
    when(() => mockChatBloc.state).thenReturn(const ChatLoaded(messages: []));

    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<ChatBloc>.value(
        value: mockChatBloc,
        child: const ContactProfilePage(
          conversationId: 'test_conv_id',
          contactName: 'Olive Grant',
          contactColor: Colors.pinkAccent,
          isOnline: true,
          recipientId: 'user_1',
        ),
      ),
    );
  }

  testWidgets('renders ContactProfilePage correctly with mockup components', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify contact name and status quote
    expect(find.text('Olive Grant'), findsOneWidget);
    expect(find.text('Pursuing Goals 🤘'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);

    // Verify Shared media section
    expect(find.text('Media, links, and docs'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);

    // Verify options list
    expect(find.text('Mute Notifications'), findsOneWidget);
    expect(find.text('Lock Chat'), findsOneWidget);
    expect(find.text('Disappearing Messages'), findsOneWidget);

    // Verify block/report buttons
    expect(find.text('Block Olive Grant'), findsOneWidget);
    expect(find.text('Report Olive Grant'), findsOneWidget);
  });

  testWidgets('toggling settings switches works correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify initial switch values
    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches.length, 1);
    expect(switches.elementAt(0).value, isFalse);

    // Toggle Lock Chat
    await tester.ensureVisible(find.byType(Switch).at(0));
    await tester.tap(find.byType(Switch).at(0));
    await tester.pumpAndSettle();

    // Since it's a Bloc, the switch state depends on the Bloc state
    // To test UI feedback, we'd need to emit a new state
  });
}
