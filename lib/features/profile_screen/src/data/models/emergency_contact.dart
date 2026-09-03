class EmergencyContact {
  final String id;
  final String phoneNumber;
  final String contactName;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.phoneNumber,
    required this.contactName,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'contactName': contactName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
