import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUrlCache {
  ImageUrlCache._();

  static final Map<String, String> _cache = {};

  static String publicUrl({required String bucket, required String path}) {
    final key = '$bucket|$path';
    return _cache.putIfAbsent(
      key,
      () => Supabase.instance.client.storage.from(bucket).getPublicUrl(path),
    );
  }

  static void clear() => _cache.clear();

  // optional: hapus hanya 1 item
  static void remove({required String bucket, required String path}) {
    _cache.remove('$bucket|$path');
  }
}
