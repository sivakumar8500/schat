enum ToneType {
  CALL,
  MESSAGE,
}

class Tone {
  final String id;
  final String name;
  final String toneType; // "CALL" or "MESSAGE"
  final String fileUrl;
  final bool isDefault;

  Tone({
    required this.id,
    required this.name,
    required this.toneType,
    required this.fileUrl,
    required this.isDefault,
  });

  factory Tone.fromJson(Map<String, dynamic> json) {
    return Tone(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      toneType: (json['tone_type'] ?? json['toneType'] ?? 'CALL').toString(),
      fileUrl: (json['file_url'] ?? json['fileUrl'] ?? '').toString(),
      isDefault: json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tone_type': toneType,
        'file_url': fileUrl,
        'is_default': isDefault,
      };

  bool get isCallTone => toneType == 'CALL';
  bool get isMessageTone => toneType == 'MESSAGE';
}

class UserTonesPreference {
  final Tone? callRingtone;
  final Tone? messageTone;

  UserTonesPreference({
    this.callRingtone,
    this.messageTone,
  });

  factory UserTonesPreference.fromJson(Map<String, dynamic> json) {
    return UserTonesPreference(
      callRingtone: json['call_ringtone'] != null && json['call_ringtone'] is Map
          ? Tone.fromJson(Map<String, dynamic>.from(json['call_ringtone'] as Map))
          : null,
      messageTone: json['message_tone'] != null && json['message_tone'] is Map
          ? Tone.fromJson(Map<String, dynamic>.from(json['message_tone'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'call_ringtone': callRingtone?.toJson(),
        'message_tone': messageTone?.toJson(),
      };
}
