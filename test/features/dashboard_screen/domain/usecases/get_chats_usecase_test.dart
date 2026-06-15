import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/recipient_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late GetChatsUseCase useCase;
  late MockDashboardRepository mockDashboardRepository;

  setUp(() {
    mockDashboardRepository = MockDashboardRepository();
    useCase = GetChatsUseCase(mockDashboardRepository);
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
      id: '1',
      isGroup: false,
      createdAt: 'now',
      updatedAt: 'now',
      recipient: recipient,
    ),
  ];

  test('should get chats from repository', () async {
    // arrange
    when(() => mockDashboardRepository.getChats())
        .thenAnswer((_) async => ApiResult.success(chatList));

    // act
    final result = await useCase.execute();

    // assert
    expect(result, isA<Success<List<ChatModel>>>());
    expect((result as Success<List<ChatModel>>).data, chatList);
    verify(() => mockDashboardRepository.getChats());
    verifyNoMoreInteractions(mockDashboardRepository);
  });
}
