import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/features/call_screen/src/domain/call_history.dart';
import 'package:schat/features/call_screen/src/domain/repositories/call_history_repository.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_history_cubit.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_history_state.dart';

class MockCallHistoryRepository extends Mock implements CallHistoryRepository {}

void main() {
  late MockCallHistoryRepository mockRepository;
  late CallHistoryCubit cubit;

  setUp(() {
    mockRepository = MockCallHistoryRepository();
    cubit = CallHistoryCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('CallHistoryCubit', () {
    test('initial state is CallHistoryState.initial()', () {
      expect(cubit.state, const CallHistoryState.initial());
    });

    blocTest<CallHistoryCubit, CallHistoryState>(
      'emits [loading, loaded] with empty list when API returns empty list',
      build: () {
        when(() => mockRepository.getCallHistory(limit: 50))
            .thenAnswer((_) async => <CallHistoryModel>[]);
        return cubit;
      },
      act: (c) => c.fetchCallHistory(),
      expect: () => const [
        CallHistoryState.loading(),
        CallHistoryState.loaded(<CallHistoryModel>[]),
      ],
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'emits [loading, loaded] with call items when API returns records',
      build: () {
        final mockCalls = [
          const CallHistoryModel(
            id: 'call_1',
            callerName: 'Alice',
            callType: 'audio',
            status: 'completed',
            direction: 'incoming',
          ),
        ];
        when(() => mockRepository.getCallHistory(limit: 50))
            .thenAnswer((_) async => mockCalls);
        return cubit;
      },
      act: (c) => c.fetchCallHistory(),
      expect: () => [
        const CallHistoryState.loading(),
        CallHistoryState.loaded([
          const CallHistoryModel(
            id: 'call_1',
            callerName: 'Alice',
            callType: 'audio',
            status: 'completed',
            direction: 'incoming',
          ),
        ]),
      ],
    );

    blocTest<CallHistoryCubit, CallHistoryState>(
      'emits [loading, error] when repository throws exception',
      build: () {
        when(() => mockRepository.getCallHistory(limit: 50))
            .thenThrow(Exception('Network error'));
        return cubit;
      },
      act: (c) => c.fetchCallHistory(),
      expect: () => const [
        CallHistoryState.loading(),
        CallHistoryState.error('Exception: Network error'),
      ],
    );
  });
}
