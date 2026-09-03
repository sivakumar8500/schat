import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/tickets_screen/src/domain/repositories/tickets_repository.dart';
import 'package:schat/features/tickets_screen/src/presentation/bloc/tickets_event.dart';
import 'package:schat/features/tickets_screen/src/presentation/bloc/tickets_state.dart';

@injectable
class TicketsBloc extends Bloc<TicketsEvent, TicketsState> {
  final TicketsRepository _repository;

  TicketsBloc(this._repository) : super(const TicketsInitial()) {
    on<LoadTicketsEvent>(_onLoadTickets);
    on<CreateTicketEvent>(_onCreateTicket);
  }

  Future<void> _onLoadTickets(LoadTicketsEvent event, Emitter<TicketsState> emit) async {
    emit(const TicketsLoading());
    final result = await _repository.getTickets();
    
    result.when(
      success: (tickets) {
        emit(TicketsLoaded(tickets: tickets));
      },
      failure: (error, _) {
        emit(TicketsError(errorMessage: error));
      },
    );
  }

  Future<void> _onCreateTicket(CreateTicketEvent event, Emitter<TicketsState> emit) async {
    emit(const TicketsLoading());
    final result = await _repository.createTicket(
      event.title, 
      event.description,
      attachmentPath: event.attachmentPath,
    );
    
    result.when(
      success: (_) {
        emit(const TicketCreateSuccess());
        add(const LoadTicketsEvent());
      },
      failure: (error, _) {
        emit(TicketCreateError(errorMessage: error));
        add(const LoadTicketsEvent()); // Reload list after error to restore state
      },
    );
  }
}
