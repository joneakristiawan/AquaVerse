import 'package:supabase_flutter/supabase_flutter.dart';

class News {
  final String id;
  final String title;
  final String content;
  final String imageUrl; 
  final String userImageUrl; 
  final String author; 
  final DateTime publishTime; 
  final String category; 

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.userImageUrl, 
    required this.author, 
    required this.category, 
    required this.publishTime, 
  });

  factory News.fromJson(Map<String, dynamic> json) {
    final supabase = Supabase.instance.client;

    final String newsImageFileName = json['image_url'] ?? '';
    final String userImageFileName = json['userpicture'] ?? '';

    return News(
      id: json['id'].toString(),
      title: json['title'].toString(),
      content: json['content'].toString(),
      imageUrl: newsImageFileName.isNotEmpty
          ? supabase.storage.from('aquaverse').getPublicUrl('assets/images/news/$newsImageFileName')
          : '',
      userImageUrl: userImageFileName.isNotEmpty
          ? supabase.storage.from('aquaverse').getPublicUrl('assets/images/news/$userImageFileName')
          : '', 
      author: json['author'].toString(), 
      category: json['category'].toString(), 
      publishTime: DateTime.parse(json['publishTime']) 
    );
  }
}