import 'package:schat/features/tickets_screen/src/domain/models/ticket_model.dart';

abstract class TicketsState {
  const TicketsState();
}

class TicketsInitial extends TicketsState {
  const TicketsInitial();
}

class TicketsLoading extends TicketsState {
  const TicketsLoading();
}

class TicketsLoaded extends TicketsState {
  final List<TicketModel> tickets;

  const TicketsLoaded({required this.tickets});
}

class TicketsError extends TicketsState {
  final String errorMessage;

  const TicketsError({required this.errorMessage});
}

class TicketCreateSuccess extends TicketsState {
  const TicketCreateSuccess();
}

class TicketCreateError extends TicketsState {
  final String errorMessage;

  const TicketCreateError({required this.errorMessage});
}
