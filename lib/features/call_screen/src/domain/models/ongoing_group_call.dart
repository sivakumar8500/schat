import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';

class OngoingGroupCall {
  final String conversationId;
  final String groupName;
  final bool isVideo;
  final String? profilePictureUrl;
  final List<UserModel> participants;
  final Set<String> connectedParticipantIds;
  final DateTime startedAt;

  const OngoingGroupCall({
    required this.conversationId,
    required this.groupName,
    this.isVideo = false,
    this.profilePictureUrl,
    this.participants = const [],
    this.connectedParticipantIds = const {},
    required this.startedAt,
  });

  OngoingGroupCall copyWith({
    String? conversationId,
    String? groupName,
    bool? isVideo,
    String? profilePictureUrl,
    List<UserModel>? participants,
    Set<String>? connectedParticipantIds,
    DateTime? startedAt,
  }) {
    return OngoingGroupCall(
      conversationId: conversationId ?? this.conversationId,
      groupName: groupName ?? this.groupName,
      isVideo: isVideo ?? this.isVideo,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      participants: participants ?? this.participants,
      connectedParticipantIds: connectedParticipantIds ?? this.connectedParticipantIds,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
