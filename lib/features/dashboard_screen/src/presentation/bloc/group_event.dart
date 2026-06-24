abstract class GroupEvent {
  const GroupEvent();
}

class CreateGroupEvent extends GroupEvent {
  final String name;
  final String? description;
  final List<String> participantIds;

  const CreateGroupEvent({
    required this.name,
    this.description,
    required this.participantIds,
  });
}
