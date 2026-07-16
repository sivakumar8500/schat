abstract class GroupEvent {
  const GroupEvent();
}

class CreateGroupEvent extends GroupEvent {
  final String name;
  final String? description;
  final String? groupPictureUrl;
  final String? groupImageUrl;
  final List<String> participantIds;

  const CreateGroupEvent({
    required this.name,
    this.description,
    this.groupPictureUrl,
    this.groupImageUrl,
    required this.participantIds,
  });
}
