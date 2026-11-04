import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final userId = _userId;

    if (userId == null) {
      throw Exception('You must be logged in to view favorites.');
    }

    final response = await _supabase
        .from('favorites')
        .select('''
          id,
          user_id,
          car_id,
          created_at,
          cars (
            id,
            title,
            description,
            year,
            price,
            mileage,
            color,
            fuel_type,
            transmission,
            status,
            brands (
              id,
              name,
              logo_url
            ),
            models (
              id,
              name
            ),
            dealerships (
              id,
              name,
              logo_url
            ),
            car_images (
              id,
              image_url,
              display_order
            )
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addFavorite(String carId) async {
    final userId = _userId;

    if (userId == null) {
      throw Exception('You must be logged in to save favorites.');
    }

    await _supabase.from('favorites').insert({
      'user_id': userId,
      'car_id': carId,
    });
  }

  Future<void> removeFavorite(String carId) async {
    final userId = _userId;

    if (userId == null) {
      throw Exception('You must be logged in.');
    }

    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('car_id', carId);
  }

  Future<bool> isFavorite(String carId) async {
    final userId = _userId;

    if (userId == null) return false;

    final response = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('car_id', carId)
        .maybeSingle();

    return response != null;
  }

  Future<void> toggleFavorite({
    required String carId,
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      await removeFavorite(carId);
    } else {
      await addFavorite(carId);
    }
  }
}