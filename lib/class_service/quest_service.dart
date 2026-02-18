import 'package:supabase_flutter/supabase_flutter.dart';

class QuestService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getDailyQuest() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};

    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    try {
      Map<String, dynamic>? data = await supabase
          .from('daily_quests')
          .select()
          .eq('user_id', user.id)
          .eq('date', todayStr)
          .maybeSingle();

      // Kalau belum ada data hari ini, insert baris baru (Trigger DB akan isi target random)
      if (data == null) {
        data = await supabase
            .from('daily_quests')
            .insert({
              'user_id': user.id,
              'date': todayStr,
            })
            .select()
            .single();
      }

      return data;
    } catch (e) {
      print("Error getDailyQuest: $e");
      return {};
    }
  }

  Future<void> trackReadNews() async {
    try {
      await supabase.rpc('increment_quest', params: {'row_name': 'news_read'});
    } catch (e) {
      print("Error tracking news: $e");
    }
  }

  Future<void> trackPlayQuiz() async {
    try {
      await supabase.rpc('increment_quest', params: {'row_name': 'quiz_played'});
    } catch (e) {
      print("Error tracking quiz: $e");
    }
  }

  Future<void> trackScanFish() async {
    try {
      await supabase.rpc('increment_quest', params: {'row_name': 'fish_scanned'});
    } catch (e) {
      print("Error tracking fish: $e");
    }
  }
}