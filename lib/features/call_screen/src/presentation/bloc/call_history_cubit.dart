import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/call_screen/src/domain/repositories/call_history_repository.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_history_state.dart';

@lazySingleton
class CallHistoryCubit extends Cubit<CallHistoryState> {
  final CallHistoryRepository _repository;

  CallHistoryCubit(this._repository) : super(const CallHistoryState.initial());

  Future<void> fetchCallHistory({int limit = 50}) async {
    emit(const CallHistoryState.loading());
    try {
      final calls = await _repository.getCallHistory(limit: limit);
      emit(CallHistoryState.loaded(calls));
    } catch (e) {
      emit(CallHistoryState.error(e.toString()));
    }
  }

  Future<void> deleteCall(String callId) async {
    state.maybeWhen(
      loaded: (calls) {
        final updated = calls.where((c) => c.id != callId).toList();
        emit(CallHistoryState.loaded(updated));
        _repository.deleteCall(callId);
      },
      orElse: () {},
    );
  }

  Future<void> deleteMultipleCalls(Set<String> callIds) async {
    state.maybeWhen(
      loaded: (calls) {
        final updated = calls.where((c) => !callIds.contains(c.id)).toList();
        emit(CallHistoryState.loaded(updated));
        for (final id in callIds) {
          _repository.deleteCall(id);
        }
      },
      orElse: () {},
    );
  }
}
