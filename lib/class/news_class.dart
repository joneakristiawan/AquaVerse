class News {
  final String imageUrl;
  final String author;
  final String title;
  final String category;
  final DateTime publishTime;
  final String content;
  final String userpicture;

  News({
    required this.imageUrl,
    required this.author,
    required this.title,
    required this.category,
    required this.publishTime,
    required this.content,
    required this.userpicture,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    // Helper function buat handle tanggal biar gak crash
    DateTime safeTime() {
      // Prioritas 1: Cek publishTime (sesuai query lu)
      if (json['publishTime'] != null) {
        return DateTime.tryParse(json['publishTime'].toString()) ?? DateTime.now();
      }
      // Prioritas 2: Cek published_at (standard supabase)
      if (json['published_at'] != null) {
        return DateTime.tryParse(json['published_at'].toString()) ?? DateTime.now();
      }
      // Prioritas 3: Cek created_at
      if (json['created_at'] != null) {
        return DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return News(
      title: (json['title'] ?? 'No Title').toString(),
      author: (json['author'] ?? 'Admin').toString(),
      content: (json['content'] ?? '').toString(),
      category: (json['category'] ?? 'Berita').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      userpicture: (json['userpicture'] ?? '').toString(),
      publishTime: safeTime(),
    );
  }
}