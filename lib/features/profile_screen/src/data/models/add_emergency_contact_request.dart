class AddEmergencyContactRequest {
  final String phoneNumber;
  final String contactName;

  AddEmergencyContactRequest({
    required this.phoneNumber,
    required this.contactName,
  });

  factory AddEmergencyContactRequest.fromJson(Map<String, dynamic> json) {
    return AddEmergencyContactRequest(
      phoneNumber: json['phoneNumber'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'contactName': contactName,
    };
  }
}
