import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/injection.dart';
import 'group_event.dart';
import 'group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final DashboardRepository _repository;

  GroupBloc({DashboardRepository? repository})
      : _repository = repository ?? getIt<DashboardRepository>(),
        super(const GroupInitial()) {
    on<CreateGroupEvent>(_onCreateGroup);
  }

  Future<void> _onCreateGroup(CreateGroupEvent event, Emitter<GroupState> emit) async {
    emit(const GroupLoading());
    final result = await _repository.createGroup(
      groupName: event.name,
      groupDescription: event.description,
      participantIds: event.participantIds,
    );

    result.when(
      success: (chat) => emit(GroupSuccess(chat)),
      failure: (message, _) => emit(GroupError(message)),
    );
  }
}
