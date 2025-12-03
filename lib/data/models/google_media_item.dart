class GoogleMediaItem {
  final String id;
  final String baseUrl;
  final String filename;
  final String mimeType;

  GoogleMediaItem({
    required this.id,
    required this.baseUrl,
    required this.filename,
    required this.mimeType,
  });

  factory GoogleMediaItem.fromJson(Map<String, dynamic> json) {
    return GoogleMediaItem(
      id: json['id'] as String,
      baseUrl: json['baseUrl'] as String,
      filename: json['filename'] as String,
      mimeType: json['mimeType'] as String,
    );
  }
}
