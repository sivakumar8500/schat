import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late GetChatsUseCase useCase;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    useCase = GetChatsUseCase(mockChatRepository);
  });

  const chatList = [
    ChatModel(
      id: '1',
      isGroup: false,
      createdAt: 'now',
      updatedAt: 'now',
    ),
  ];

  test('should get chats from repository', () async {
    // arrange
    when(() => mockChatRepository.getChats())
        .thenAnswer((_) async => ApiResult.success(chatList));

    // act
    final result = await useCase.execute();

    // assert
    expect(result, isA<Success<List<ChatModel>>>());
    expect((result as Success).data, chatList);
    verify(() => mockChatRepository.getChats());
    verifyNoMoreInteractions(mockChatRepository);
  });
}
