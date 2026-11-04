import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPageView extends StatefulWidget {
  const AdminPageView({super.key});

  @override
  State<AdminPageView> createState() => _AdminPageViewState();
}

class _AdminPageViewState extends State<AdminPageView> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final yearController = TextEditingController();
  final mileageController = TextEditingController();
  final colorController = TextEditingController();
  final fuelController = TextEditingController();
  final transmissionController = TextEditingController();
  final descriptionController = TextEditingController();

  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> models = [];
  List<XFile> selectedImages = [];

  String? selectedBrandId;
  String? selectedModelId;
  String? dealershipId;

  bool isLoading = true;
  bool isUploading = false;
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    yearController.dispose();
    mileageController.dispose();
    colorController.dispose();
    fuelController.dispose();
    transmissionController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please login first.');
      }

      // Check platform administrator permission.
      final profile =
          await supabase
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

      final isAdmin = profile?['role'] == 'platform_admin';

      // Get the user's dealership.
      final membership =
          await supabase
              .from('dealership_members')
              .select('dealership_id, role')
              .eq('user_id', user.id)
              .eq('role', 'owner')
              .limit(1)
              .maybeSingle();

      if (membership != null) {
        dealershipId = membership['dealership_id'].toString();
      } else if (isAdmin) {
        final dealership =
            await supabase
                .from('dealerships')
                .select('id')
                .order('created_at')
                .limit(1)
                .maybeSingle();

        dealershipId = dealership?['id']?.toString();
      }

      if (dealershipId == null) {
        throw Exception('No dealership assigned to this account.');
      }

      if (!isAdmin && membership == null) {
        throw Exception('You do not have permission to manage cars.');
      }

      hasPermission = true;

      await _loadBrands();
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadBrands() async {
    final result = await supabase
        .from('brands')
        .select('id, name')
        .order('name');

    if (!mounted) return;

    setState(() {
      brands = List<Map<String, dynamic>>.from(result);
    });
  }

  Future<void> _loadModels(String brandId) async {
    setState(() {
      models = [];
      selectedModelId = null;
    });

    try {
      final result = await supabase
          .from('models')
          .select('id, name')
          .eq('brand_id', brandId)
          .order('name');

      if (!mounted) return;

      setState(() {
        models = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString(), isError: true);
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await picker.pickMultiImage(imageQuality: 85);

      if (images.isNotEmpty && mounted) {
        setState(() {
          selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  Future<Uint8List> _compressImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Could not read one of the selected images.');
    }

    final resized = img.copyResize(
      decoded,
      width: decoded.width > 1600 ? 1600 : decoded.width,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
  }

  Future<void> _uploadCar() async {
    if (!hasPermission || dealershipId == null) {
      _showMessage('You do not have permission.', isError: true);
      return;
    }

    if (titleController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        selectedBrandId == null ||
        selectedModelId == null ||
        selectedImages.isEmpty) {
      _showMessage(
        'Please complete the required fields and select at least one image.',
        isError: true,
      );
      return;
    }

    final price = double.tryParse(priceController.text.trim());
    final year = int.tryParse(yearController.text.trim());
    final mileage = int.tryParse(mileageController.text.trim());

    if (price == null || price < 0) {
      _showMessage('Please enter a valid price.', isError: true);
      return;
    }

    if (yearController.text.trim().isNotEmpty && year == null) {
      _showMessage('Please enter a valid year.', isError: true);
      return;
    }

    if (mileageController.text.trim().isNotEmpty &&
        (mileage == null || mileage < 0)) {
      _showMessage('Please enter valid mileage.', isError: true);
      return;
    }

    setState(() => isUploading = true);

    try {
      // Create the car as draft first.
      final car =
          await supabase
              .from('cars')
              .insert({
                'dealership_id': dealershipId,
                'brand_id': selectedBrandId,
                'model_id': selectedModelId,
                'title': titleController.text.trim(),
                'price': price,
                'year': year,
                'mileage': mileage,
                'color': colorController.text.trim(),
                'fuel_type': fuelController.text.trim(),
                'transmission': transmissionController.text.trim(),
                'description': descriptionController.text.trim(),
                'status': 'draft',
              })
              .select('id')
              .single();

      final carId = car['id'].toString();

      // Upload images and save their URLs.
      for (int i = 0; i < selectedImages.length; i++) {
        final bytes = await _compressImage(selectedImages[i]);

        final filePath =
            '$dealershipId/$carId/${DateTime.now().microsecondsSinceEpoch}_$i.jpg';

        await supabase.storage
            .from('car-images')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );

        final imageUrl = supabase.storage
            .from('car-images')
            .getPublicUrl(filePath);

        await supabase.from('car_images').insert({
          'car_id': carId,
          'image_url': imageUrl,
          'display_order': i,
        });
      }

      // Publish only after all images have been uploaded.
      await supabase
          .from('cars')
          .update({'status': 'published'})
          .eq('id', carId);

      if (!mounted) return;

      _clearForm();

      _showMessage('Car added successfully!');
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  void _clearForm() {
    titleController.clear();
    priceController.clear();
    yearController.clear();
    mileageController.clear();
    colorController.clear();
    fuelController.clear();
    transmissionController.clear();
    descriptionController.clear();

    setState(() {
      selectedImages.clear();
      selectedBrandId = null;
      selectedModelId = null;
      models.clear();
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(border: InputBorder.none),
        hint: Text(hint),
        items:
            items.map((item) {
              return DropdownMenuItem<String>(
                value: item['id'].toString(),
                child: Text(item['name'].toString()),
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('MOTORA Admin')),
        body: const Center(
          child: Text(
            'You do not have permission to access this page.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: const Text('Add New Car'),
        backgroundColor: Colors.grey.shade300,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Car Images',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: isUploading ? null : _pickImages,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.cloud_upload,
                      size: 35,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 8),
                    Text('Select car images'),
                  ],
                ),
              ),
            ),

            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(selectedImages[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 3,
                            right: 3,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: const CircleAvatar(
                                radius: 13,
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.close,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 25),

            const Text(
              'Basic Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),

            const SizedBox(height: 12),

            _buildField('Car Title', titleController),

            _buildDropdown(
              hint: 'Choose Car Brand',
              value: selectedBrandId,
              items: brands,
              onChanged: (value) {
                if (value == null) return;

                setState(() => selectedBrandId = value);
                _loadModels(value);
              },
            ),

            _buildDropdown(
              hint: 'Choose Car Model',
              value: selectedModelId,
              items: models,
              onChanged: (value) {
                setState(() => selectedModelId = value);
              },
            ),

            _buildField(
              'Car Price',
              priceController,
              keyboardType: TextInputType.number,
            ),

            _buildField(
              'Manufacturing Year',
              yearController,
              keyboardType: TextInputType.number,
            ),

            _buildField(
              'Mileage (km)',
              mileageController,
              keyboardType: TextInputType.number,
            ),

            _buildField('Color', colorController),

            _buildField('Fuel Type', fuelController),

            _buildField('Transmission', transmissionController),

            _buildField('Description', descriptionController, maxLines: 4),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isUploading ? null : _uploadCar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    isUploading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                          'Publish Car',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
