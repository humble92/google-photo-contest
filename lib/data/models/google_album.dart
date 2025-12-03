class GoogleAlbum {
  final String id;
  final String title;
  final String? productUrl;
  final String? coverPhotoBaseUrl;
  final int mediaItemsCount;

  GoogleAlbum({
    required this.id,
    required this.title,
    this.productUrl,
    this.coverPhotoBaseUrl,
    this.mediaItemsCount = 0,
  });

  factory GoogleAlbum.fromJson(Map<String, dynamic> json) {
    return GoogleAlbum(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      productUrl: json['productUrl'] as String?,
      coverPhotoBaseUrl: json['coverPhotoBaseUrl'] as String?,
      mediaItemsCount: int.tryParse(json['mediaItemsCount']?.toString() ?? '0') ?? 0,
    );
  }
}
