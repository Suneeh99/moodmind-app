class MotivationReel {
  final String id;
  final String title;
  final String author;
  final String source; // "youtube" | "mp4" | "web"
  final String videoUrl;
  final String? thumbnailUrl;

  const MotivationReel({
    required this.id,
    required this.title,
    required this.author,
    required this.source,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  factory MotivationReel.fromMap(String id, Map<String, dynamic> data) {
    return MotivationReel(
      id: id,
      title: data['title'] ?? '',
      author: data['author'] ?? 'Unknown',
      source: (data['source'] ?? 'web').toString().toLowerCase(),
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: (data['thumbnailUrl'] as String?)?.isEmpty == true
          ? null
          : data['thumbnailUrl'],
    );
  }
}
