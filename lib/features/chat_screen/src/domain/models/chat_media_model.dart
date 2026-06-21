class ChatMediaModel {
  final String id;
  final String uploaderId;
  final String mediaType; // CHAT_IMAGE, CHAT_VIDEO, VOICE_NOTE, DOCUMENT
  final String mimeType;
  final String filename;
  final int fileSizeBytes;
  final String status;
  final String createdAt;
  final String url;
  final List<dynamic> thumbnails;

  ChatMediaModel({
    required this.id,
    required this.uploaderId,
    required this.mediaType,
    required this.mimeType,
    required this.filename,
    required this.fileSizeBytes,
    required this.status,
    required this.createdAt,
    required this.url,
    required this.thumbnails,
  });

  factory ChatMediaModel.fromJson(Map<String, dynamic> json) {
    return ChatMediaModel(
      id: json['id']?.toString() ?? '',
      uploaderId: json['uploader_id'] ?? json['uploaderId'] ?? '',
      mediaType: json['media_type'] ?? json['mediaType'] ?? '',
      mimeType: json['mime_type'] ?? json['mimeType'] ?? '',
      filename: json['filename'] ?? json['fileName'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? json['fileSizeBytes'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      url: json['url'] ?? '',
      thumbnails: json['thumbnails'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uploader_id': uploaderId,
    'media_type': mediaType,
    'mime_type': mimeType,
    'filename': filename,
    'file_size_bytes': fileSizeBytes,
    'status': status,
    'created_at': createdAt,
    'url': url,
    'thumbnails': thumbnails,
  };
}
