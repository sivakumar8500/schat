import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/recipient_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';

class MockGetChatsUseCase extends Mock implements GetChatsUseCase {}
class MockDashboardRepository extends Mock implements DashboardRepository {}
class MockContactsRepository extends Mock implements ContactsRepository {}
class MockChatSocketRepository extends Mock implements ChatSocketRepository {}

void main() {
  late ChatsBloc chatsBloc;
  late MockGetChatsUseCase mockGetChatsUseCase;
  late MockDashboardRepository mockDashboardRepository;
  late MockContactsRepository mockContactsRepository;
  late MockChatSocketRepository mockChatSocketRepository;

  setUp(() {
    mockGetChatsUseCase = MockGetChatsUseCase();
    mockDashboardRepository = MockDashboardRepository();
    mockContactsRepository = MockContactsRepository();
    mockChatSocketRepository = MockChatSocketRepository();
    when(() => mockChatSocketRepository.onMessage).thenAnswer((_) => const Stream.empty());
    chatsBloc = ChatsBloc(
      mockGetChatsUseCase,
      mockDashboardRepository,
      mockContactsRepository,
      mockChatSocketRepository,
    );
  });

  tearDown(() {
    chatsBloc.close();
  });

  const recipient = RecipientModel(
    id: 'r1',
    phoneNumber: '1234567890',
    isActive: true,
    isOnline: false,
    isSubscribed: true,
    createdAt: 'now',
    updatedAt: 'now',
  );

  final chatList = [
    const ChatModel(
      id: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
      isGroup: true,
      groupName: 'string',
      groupDescription: 'string',
      createdAt: '2026-06-12T06:01:29.768Z',
      updatedAt: '2026-06-12T06:01:29.768Z',
      recipient: recipient,
    ),
  ];

  group('FetchChats', () {
    blocTest<ChatsBloc, ChatsState>(
      'emits [ChatsLoading, ChatsLoaded] when successful',
      build: () {
        when(() => mockGetChatsUseCase.execute())
            .thenAnswer((_) async => Success(chatList));
        return chatsBloc;
      },
      act: (bloc) => bloc.add(const FetchChats()),
      expect: () => [
        const ChatsLoading(),
        ChatsLoaded(chatList),
      ],
    );

    blocTest<ChatsBloc, ChatsState>(
      'emits [ChatsLoading, ChatsError] when failed',
      build: () {
        when(() => mockGetChatsUseCase.execute())
            .thenAnswer((_) async => const Failure('Error fetching chats'));
        return chatsBloc;
      },
      act: (bloc) => bloc.add(const FetchChats()),
      expect: () => [
        const ChatsLoading(),
        const ChatsError('Error fetching chats'),
      ],
    );
  });
}
