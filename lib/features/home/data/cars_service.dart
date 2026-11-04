
import 'package:supabase_flutter/supabase_flutter.dart';

class CarsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPublishedCars() async {
    final response = await _supabase
        .from('cars')
        .select('''
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
          brands!cars_brand_id_fkey (
            id,
            name,
            logo_url
          ),
          models!cars_model_brand_fk (
            id,
            name
          ),
          dealerships!cars_dealership_id_fkey (
            id,
            name,
            logo_url
          ),
          car_images (
            id,
            image_url,
            display_order
          )
        ''')
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
