import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CbtService {
  static const String _cbtUrlKey = 'cbt_url';
  static const String _defaultUrl = 'https://google.com'; // Default for testing
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get CBT URL - Try Supabase first, fallback to SharedPreferences
  Future<String> getCbtUrl() async {
    try {
      // Try to fetch from Supabase 'system_settings' table
      // Assuming table structure: id, key, value
      final response = await _supabase
          .from('system_settings')
          .select('value')
          .eq('key', 'cbt_url')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        // Cache it locally
        await _saveLocally(response['value']);
        return response['value'];
      }
    } catch (e) {
      print('Error fetching CBT URL from Supabase: $e');
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cbtUrlKey) ?? _defaultUrl;
  }

  // Save CBT URL - Save to Supabase and SharedPreferences
  Future<void> saveCbtUrl(String url) async {
    // Save locally first
    await _saveLocally(url);

    try {
      // Try to save to Supabase
      // Upsert logic: insert or update if key exists
      await _supabase.from('system_settings').upsert({
        'key': 'cbt_url',
        'value': url,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');
    } catch (e) {
      print('Error saving CBT URL to Supabase: $e');
      // If table doesn't exist, we just rely on local storage for now
      // In a real scenario, we'd need to create the table
    }
  }

  Future<void> _saveLocally(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cbtUrlKey, url);
  }
}
