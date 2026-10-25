abstract class TicketsEvent {
  const TicketsEvent();
}

class LoadTicketsEvent extends TicketsEvent {
  const LoadTicketsEvent();
}

class CreateTicketEvent extends TicketsEvent {
  final String title;
  final String description;
  final String? attachmentPath;

  const CreateTicketEvent({
    required this.title,
    required this.description,
    this.attachmentPath,
  });
}
