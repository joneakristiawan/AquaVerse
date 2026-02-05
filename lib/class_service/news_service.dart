import 'package:supabase_flutter/supabase_flutter.dart';
import '../class/news_class.dart';

class NewsService {
  NewsService({
    SupabaseClient? client,
    this.table = 'news',
    this.bucket = 'aquaverse',
    this.folder = 'assets/images/news',
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  final String table;
  final String bucket;
  final String folder;

  Future<List<News>> fetchLatest({int limit = 10}) async {
    final data = await _client
        .from(table)
        .select('id, title, author, image_url, content, publishTime')
        .order('id', ascending: false)
        .limit(limit);

    final rows = (data as List).map((e) => Map<String, dynamic>.from(e as Map));

    return rows.map((row) {
      final file = (row['image_url'] ?? '').toString();

      if (file.isNotEmpty && !file.startsWith('http')) {
        row['image_url'] = _client.storage.from(bucket).getPublicUrl('$folder/$file');
      }

      return News.fromJson(row);
    }).toList();
  }
}