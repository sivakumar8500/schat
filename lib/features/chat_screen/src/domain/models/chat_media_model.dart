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
    // If the response is structured as a Message object with a content sub-object
    final content = json['content'];
    if (content is Map) {
      final contentMap = Map<String, dynamic>.from(content);
      return ChatMediaModel(
        id: json['id']?.toString() ?? '',
        uploaderId: json['senderId']?.toString() ?? json['sender_id']?.toString() ?? '',
        mediaType: json['type']?.toString() ?? '',
        mimeType: contentMap['mimeType']?.toString() ?? contentMap['mime_type']?.toString() ?? '',
        filename: contentMap['fileName']?.toString() ?? contentMap['filename']?.toString() ?? contentMap['text']?.toString() ?? 'File',
        fileSizeBytes: contentMap['fileSize'] as int? ?? contentMap['file_size_bytes'] as int? ?? 0,
        status: 'completed',
        createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
        url: contentMap['fileKey']?.toString() ?? contentMap['file_key']?.toString() ?? contentMap['url']?.toString() ?? '',
        thumbnails: contentMap['thumbnail'] != null ? [contentMap['thumbnail']] : [],
      );
    }

    return ChatMediaModel(
      id: json['id']?.toString() ?? '',
      uploaderId: json['uploader_id']?.toString() ?? json['uploaderId']?.toString() ?? '',
      mediaType: json['media_type']?.toString() ?? json['mediaType']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? json['mimeType']?.toString() ?? '',
      filename: json['filename']?.toString() ?? json['fileName']?.toString() ?? '',
      fileSizeBytes: json['file_size_bytes'] as int? ?? json['fileSizeBytes'] as int? ?? 0,
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
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
