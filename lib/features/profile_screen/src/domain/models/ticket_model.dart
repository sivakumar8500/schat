class TicketModel {
  final String id;
  final String title;
  final String description;
  final String? attachmentPath;
  final String status; // 'Open', 'In Progress', 'Resolved'
  final String createdAt;

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    this.attachmentPath,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'attachmentPath': attachmentPath,
    'status': status,
    'createdAt': createdAt,
  };

  factory TicketModel.fromJson(Map<String, dynamic> json) => TicketModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    attachmentPath: json['attachmentPath'] as String?,
    status: json['status'] as String,
    createdAt: json['createdAt'] as String,
  );
}
