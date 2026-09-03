import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:schat/features/call_screen/src/domain/call_history.dart';

part 'call_history_state.freezed.dart';

@freezed
class CallHistoryState with _$CallHistoryState {
  const factory CallHistoryState.initial() = _Initial;
  const factory CallHistoryState.loading() = _Loading;
  const factory CallHistoryState.loaded(List<CallHistoryModel> calls) = _Loaded;
  const factory CallHistoryState.error(String message) = _Error;
}
