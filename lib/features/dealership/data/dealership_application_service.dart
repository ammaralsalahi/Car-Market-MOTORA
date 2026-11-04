
import 'package:supabase_flutter/supabase_flutter.dart';

class DealershipApplicationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitApplication({
    required String dealershipName,
    required String description,
    required String phone,
    required String address,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final existing = await _supabase
        .from('dealership_applications')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'pending')
        .limit(1);

    if ((existing as List).isNotEmpty) {
      throw Exception('لديك طلب معرض قيد المراجعة بالفعل');
    }

    await _supabase.from('dealership_applications').insert({
      'user_id': user.id,
      'dealership_name': dealershipName.trim(),
      'description': description.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
    });
  }

  Future<Map<String, dynamic>?> getMyApplication() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final response = await _supabase
        .from('dealership_applications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }
}
