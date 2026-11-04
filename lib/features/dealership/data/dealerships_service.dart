import 'package:supabase_flutter/supabase_flutter.dart';

class DealershipsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getDealerships() async {
    final response = await _supabase
        .from('dealerships')
        .select(
          'id, name, description, phone, address, logo_url, is_active, created_at',
        )
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}