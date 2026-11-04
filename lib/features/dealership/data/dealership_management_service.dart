
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class DealershipManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getMyDealership() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final memberships = await _supabase
        .from('dealership_members')
        .select('dealership_id, role')
        .eq('user_id', user.id)
        .eq('role', 'owner')
        .limit(1);

    if (memberships.isEmpty) {
      throw Exception('لا يوجد معرض مرتبط بحسابك أو أن دورك ليس owner');
    }

    final dealershipId = memberships.first['dealership_id'].toString();

    final dealership = await _supabase
        .from('dealerships')
        .select('id, name, description, phone, address, logo_url, is_active')
        .eq('id', dealershipId)
        .maybeSingle();

    if (dealership == null || dealership['is_active'] != true) {
      throw Exception('المعرض غير موجود أو غير نشط');
    }

    return dealership;
  }

  Future<List<Map<String, dynamic>>> getMyCars() async {
    final dealership = await getMyDealership();

    final response = await _supabase
        .from('cars')
        .select('''
          id,
          title,
          description,
          price,
          year,
          mileage,
          color,
          fuel_type,
          transmission,
          status,
          brands!cars_brand_id_fkey(id, name),
          models!cars_model_brand_fk(id, name),
          car_images(id, image_url, display_order)
        ''')
        .eq('dealership_id', dealership['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    final response = await _supabase
        .from('brands')
        .select('id, name')
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getModels(String brandId) async {
    final response = await _supabase
        .from('models')
        .select('id, name')
        .eq('brand_id', brandId)
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addCar({
    required String title,
    required String description,
    required String brandId,
    required String modelId,
    required int year,
    required double price,
    required int mileage,
    required String color,
    required String fuelType,
    required String transmission,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) {
      throw Exception('اختر صورة واحدة على الأقل للسيارة');
    }

    final dealership = await getMyDealership();
    final dealershipId = dealership['id'].toString();

    final now = DateTime.now().toUtc().toIso8601String();

    // إنشاء السيارة والتأكد من إرجاع معرفها
    final carResponse = await _supabase
        .from('cars')
        .insert({
          'dealership_id': dealershipId,
          'brand_id': brandId,
          'model_id': modelId,
          'title': title.trim(),
          'description': description.trim(),
          'year': year,
          'price': price,
          'mileage': mileage,
          'color': color.trim(),
          'fuel_type': fuelType,
          'transmission': transmission,
          'status': 'draft',
          'created_at': now,
          'updated_at': now,
        })
        .select('id')
        .single();

    final carId = carResponse['id'].toString();
    final uploadedPaths = <String>[];

    try {
      final imageRecords = <Map<String, dynamic>>[];

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final extension = _getExtension(image.name);
        final timestamp = DateTime.now().microsecondsSinceEpoch;

        final filePath =
            '$dealershipId/$carId/${timestamp}_$i.$extension';

        await _supabase.storage.from('car-images').uploadBinary(
          filePath,
          await image.readAsBytes(),
          fileOptions: FileOptions(
            contentType: _getContentType(extension),
            upsert: false,
          ),
        );

        uploadedPaths.add(filePath);

        final imageUrl = _supabase.storage
            .from('car-images')
            .getPublicUrl(filePath);

        imageRecords.add({
          'car_id': carId,
          'image_url': imageUrl,
          'display_order': i + 1,
        });
      }

      await _supabase.from('car_images').insert(imageRecords);

      // التأكد من حفظ الصور
      final savedImages = await _supabase
          .from('car_images')
          .select('id')
          .eq('car_id', carId);

      if (savedImages.isEmpty) {
        throw Exception('لم يتم حفظ صور السيارة');
      }
    } catch (e) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await _supabase.storage
              .from('car-images')
              .remove(uploadedPaths);
        } catch (_) {}
      }

      try {
        await _supabase.from('cars').delete().eq('id', carId);
      } catch (_) {}

      rethrow;
    }
  }

  Future<void> updateCar({
    required String carId,
    required String title,
    required String description,
    required String brandId,
    required String modelId,
    required int year,
    required double price,
    required int mileage,
    required String color,
    required String fuelType,
    required String transmission,
    required List<Map<String, dynamic>> existingImages,
    required List<XFile> newImages,
  }) async {
    final dealership = await getMyDealership();
    final dealershipId = dealership['id'].toString();

    final existingCar = await _supabase
        .from('cars')
        .select('id')
        .eq('id', carId)
        .eq('dealership_id', dealershipId)
        .maybeSingle();

    if (existingCar == null) {
      throw Exception('السيارة غير موجودة أو لا تتبع معرضك');
    }

    final now = DateTime.now().toUtc().toIso8601String();

    // التعديل مع التأكد من أن قاعدة البيانات أعادت السيارة
    final updatedCar = await _supabase
        .from('cars')
        .update({
          'brand_id': brandId,
          'model_id': modelId,
          'title': title.trim(),
          'description': description.trim(),
          'year': year,
          'price': price,
          'mileage': mileage,
          'color': color.trim(),
          'fuel_type': fuelType,
          'transmission': transmission,
          'updated_at': now,
        })
        .eq('id', carId)
        .eq('dealership_id', dealershipId)
        .select('id')
        .maybeSingle();

    if (updatedCar == null) {
      throw Exception(
        'لم يتم تعديل السيارة. تحقق من صلاحيات UPDATE في Supabase (RLS)',
      );
    }

    // الاحتفاظ بالصور الموجودة التي لم يطلب المستخدم حذفها
    final keepIds = existingImages
        .map((image) => image['id'].toString())
        .toSet();

    final allImages = await _supabase
        .from('car_images')
        .select('id, image_url')
        .eq('car_id', carId);

    final removedImages = List<Map<String, dynamic>>.from(allImages)
        .where((image) => !keepIds.contains(image['id'].toString()))
        .toList();

    final removedPaths = removedImages
        .map((image) => _storagePathFromUrl(
              image['image_url']?.toString() ?? '',
            ))
        .whereType<String>()
        .toList();

    if (removedPaths.isNotEmpty) {
      await _supabase.storage
          .from('car-images')
          .remove(removedPaths);
    }

    for (final image in removedImages) {
      await _supabase
          .from('car_images')
          .delete()
          .eq('id', image['id'].toString())
          .eq('car_id', carId);
    }

    // إضافة الصور الجديدة
    if (newImages.isNotEmpty) {
      final currentImages = await _supabase
          .from('car_images')
          .select('id')
          .eq('car_id', carId);

      final imageRecords = <Map<String, dynamic>>[];
      final uploadedPaths = <String>[];

      try {
        for (int i = 0; i < newImages.length; i++) {
          final image = newImages[i];
          final extension = _getExtension(image.name);
          final timestamp = DateTime.now().microsecondsSinceEpoch;

          final filePath =
              '$dealershipId/$carId/${timestamp}_edit_$i.$extension';

          await _supabase.storage.from('car-images').uploadBinary(
            filePath,
            await image.readAsBytes(),
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: false,
            ),
          );

          uploadedPaths.add(filePath);

          imageRecords.add({
            'car_id': carId,
            'image_url': _supabase.storage
                .from('car-images')
                .getPublicUrl(filePath),
            'display_order': currentImages.length + i + 1,
          });
        }

        await _supabase.from('car_images').insert(imageRecords);
      } catch (e) {
        if (uploadedPaths.isNotEmpty) {
          try {
            await _supabase.storage
                .from('car-images')
                .remove(uploadedPaths);
          } catch (_) {}
        }

        rethrow;
      }
    }
  }

  Future<void> setCarPublished({
    required String carId,
    required bool published,
  }) async {
    final dealership = await getMyDealership();

    final result = await _supabase
        .from('cars')
        .update({
          'status': published ? 'published' : 'draft',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', carId)
        .eq('dealership_id', dealership['id'])
        .select('id')
        .maybeSingle();

    if (result == null) {
      throw Exception('لم يتم تحديث حالة السيارة');
    }
  }

  Future<void> deleteCar(String carId) async {
    final dealership = await getMyDealership();
    final dealershipId = dealership['id'].toString();

    final car = await _supabase
        .from('cars')
        .select('id')
        .eq('id', carId)
        .eq('dealership_id', dealershipId)
        .maybeSingle();

    if (car == null) {
      throw Exception('السيارة غير موجودة أو لا تتبع معرضك');
    }

    final images = await _supabase
        .from('car_images')
        .select('id, image_url')
        .eq('car_id', carId);

    final paths = List<Map<String, dynamic>>.from(images)
        .map((image) => _storagePathFromUrl(
              image['image_url']?.toString() ?? '',
            ))
        .whereType<String>()
        .toList();

    if (paths.isNotEmpty) {
      await _supabase.storage.from('car-images').remove(paths);
    }

    await _supabase
        .from('car_images')
        .delete()
        .eq('car_id', carId);

    await _supabase
        .from('cars')
        .delete()
        .eq('id', carId)
        .eq('dealership_id', dealershipId);
  }

  String? _storagePathFromUrl(String url) {
    const marker = '/object/public/car-images/';

    final index = url.indexOf(marker);
    if (index == -1) return null;

    return Uri.decodeComponent(
      url.substring(index + marker.length),
    );
  }

  String _getExtension(String fileName) {
    if (!fileName.contains('.')) return 'jpg';
    return fileName.split('.').last.toLowerCase();
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
