import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';

class MockGetChatsUseCase extends Mock implements GetChatsUseCase {}

void main() {
  late ChatsBloc chatsBloc;
  late MockGetChatsUseCase mockGetChatsUseCase;

  setUp(() {
    mockGetChatsUseCase = MockGetChatsUseCase();
    chatsBloc = ChatsBloc(mockGetChatsUseCase);
  });

  tearDown(() {
    chatsBloc.close();
  });

  const chatList = [
    ChatModel(
      id: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
      isGroup: true,
      groupName: 'string',
      groupDescription: 'string',
      createdAt: '2026-06-12T06:01:29.768Z',
      updatedAt: '2026-06-12T06:01:29.768Z',
    ),
  ];

  group('FetchChats', () {
    blocTest<ChatsBloc, ChatsState>(
      'emits [ChatsLoading, ChatsLoaded] when successful',
      build: () {
        when(() => mockGetChatsUseCase.execute())
            .thenAnswer((_) async => ApiResult.success(chatList));
        return chatsBloc;
      },
      act: (bloc) => bloc.add(const FetchChats()),
      expect: () => [
        const ChatsLoading(),
        const ChatsLoaded(chatList),
      ],
    );

    blocTest<ChatsBloc, ChatsState>(
      'emits [ChatsLoading, ChatsError] when failed',
      build: () {
        when(() => mockGetChatsUseCase.execute())
            .thenAnswer((_) async => ApiResult.failure('Error fetching chats'));
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
