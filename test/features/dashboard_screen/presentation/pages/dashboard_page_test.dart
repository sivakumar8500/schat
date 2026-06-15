import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/dashboard_screen/dashboard_screen.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_state.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';

import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/status_screen/src/domain/repositories/status_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockStatusRepository extends Mock implements StatusRepository {}
class MockChatSocketBloc extends MockBloc<ChatSocketEvent, ChatSocketState> implements ChatSocketBloc {}
class MockChatsBloc extends MockBloc<ChatsEvent, ChatsState> implements ChatsBloc {}
class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  late MockChatSocketBloc mockChatSocketBloc;
  late MockChatsBloc mockChatsBloc;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<ThemeController>(ThemeController());
    getIt.registerSingleton<ChatRepository>(MockChatRepository());
    
    mockChatSocketBloc = MockChatSocketBloc();
    mockChatsBloc = MockChatsBloc();
    
    getIt.registerFactory<ChatSocketBloc>(() => mockChatSocketBloc);
    getIt.registerLazySingleton<ChatsBloc>(() => mockChatsBloc);
    getIt.registerLazySingleton<ContactsRepository>(() => MockContactsRepository());

    when(() => mockChatSocketBloc.state).thenReturn(ChatSocketInitial());
    when(() => mockChatsBloc.state).thenReturn(const ChatsInitial());

    final statusRepo = MockStatusRepository();
    when(() => statusRepo.getRecentUpdates()).thenAnswer((_) async => []);
    when(() => statusRepo.getViewedUpdates()).thenAnswer((_) async => []);
    when(() => statusRepo.getMutedUpdates()).thenAnswer((_) async => []);
    getIt.registerSingleton<StatusRepository>(statusRepo);
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: DashboardPage(),
    );
  }

  testWidgets('DashboardPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(DashboardPage), findsOneWidget);
  });
}
