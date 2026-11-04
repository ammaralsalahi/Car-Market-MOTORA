import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:motora/features/dealership/data/dealership_management_service.dart';

class AddCarPage extends StatefulWidget {
  final Map<String, dynamic>? car;

  const AddCarPage({
    super.key,
    this.car,
  });

  bool get isEditing => car != null;

  @override
  State<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  static const Color background = Color(0xFF101114);
  static const Color surface = Color(0xFF1E2024);
  static const Color accent = Color(0xFFF8ED00);

  final _service = DealershipManagementService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _year = TextEditingController();
  final _price = TextEditingController();
  final _mileage = TextEditingController();
  final _color = TextEditingController();

  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _models = [];

  List<Map<String, dynamic>> _existingImages = [];
  List<XFile> _newImages = [];

  String? _brandId;
  String? _modelId;
  String? _fuelType;
  String? _transmission;

  bool _loading = false;
  bool _loadingData = true;

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Hybrid',
    'Electric',
  ];

  final List<String> _transmissions = [
    'Automatic',
    'Manual',
  ];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      final brands = await _service.getBrands();

      if (!mounted) return;

      _brands = brands;

      if (widget.car != null) {
        await _loadCarData(widget.car!);
      }

      if (!mounted) return;

      setState(() => _loadingData = false);
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingData = false);
      _message('تعذر تحميل البيانات: $e');
    }
  }

  Future<void> _loadCarData(Map<String, dynamic> car) async {
    _title.text = car['title']?.toString() ?? '';
    _description.text = car['description']?.toString() ?? '';
    _year.text = car['year']?.toString() ?? '';
    _price.text = car['price']?.toString() ?? '';
    _mileage.text = car['mileage']?.toString() ?? '';
    _color.text = car['color']?.toString() ?? '';

    _fuelType = car['fuel_type']?.toString();
    _transmission = car['transmission']?.toString();

    final brand = car['brands'];
    final model = car['models'];

    if (brand is Map && brand['id'] != null) {
      _brandId = brand['id'].toString();
      _models = await _service.getModels(_brandId!);
    }

    if (model is Map && model['id'] != null) {
      _modelId = model['id'].toString();
    }

    final images = car['car_images'] as List? ?? [];

    _existingImages = images
        .map((image) => Map<String, dynamic>.from(image as Map))
        .toList();

    _existingImages.sort(
      (a, b) => (a['display_order'] as num? ?? 0)
          .compareTo(b['display_order'] as num? ?? 0),
    );
  }

  
Future<void> _loadModels(String brandId) async {
  setState(() {
    _modelId = null;
    _models = [];
  });

  try {
    final models = await _service.getModels(brandId);

    if (!mounted) return;

    setState(() {
      _models = models;
    });
  } catch (e) {
    if (!mounted) return;
    _message('تعذر تحميل الموديلات: $e');
  }
}


  Future<void> _pickImages() async {
    try {
      final selected = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2000,
      );

      if (!mounted || selected.isEmpty) return;

      setState(() {
        _newImages = [..._newImages, ...selected];
      });
    } catch (e) {
      if (!mounted) return;
      _message('تعذر اختيار الصور: $e');
    }
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImages.removeAt(index));
  }

Future<void> _saveCar() async {
  if (_loading) return;

  FocusScope.of(context).unfocus();

  // التحقق من الحقول
  if (!_formKey.currentState!.validate()) {
    _message('يرجى مراجعة الحقول المطلوبة');
    return;
  }

  // التحقق من الخيارات
  if (_brandId == null ||
      !_brands.any((b) => b['id'].toString() == _brandId)) {
    _message('يرجى اختيار ماركة السيارة');
    return;
  }

  if (_modelId == null ||
      !_models.any((m) => m['id'].toString() == _modelId)) {
    _message('يرجى اختيار موديل صحيح للسيارة');
    return;
  }

  if (_fuelType == null || !_fuelTypes.contains(_fuelType)) {
    _message('يرجى اختيار نوع الوقود');
    return;
  }

  if (_transmission == null ||
      !_transmissions.contains(_transmission)) {
    _message('يرجى اختيار ناقل الحركة');
    return;
  }

  // التحقق من الصور
  if (widget.isEditing) {
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      _message('يرجى الاحتفاظ بصورة واحدة على الأقل');
      return;
    }
  } else {
    if (_newImages.isEmpty) {
      _message('يرجى اختيار صورة واحدة على الأقل');
      return;
    }
  }

  // قراءة الأرقام
  final year = int.tryParse(_year.text.trim());
  final price = double.tryParse(
    _price.text.trim().replaceAll(',', '.'),
  );
  final mileage = int.tryParse(_mileage.text.trim());

  if (year == null || year < 1900 || year > DateTime.now().year + 2) {
    _message('سنة السيارة غير صحيحة');
    return;
  }

  if (price == null || price <= 0) {
    _message('يرجى إدخال سعر صحيح أكبر من صفر');
    return;
  }

  if (mileage == null || mileage < 0) {
    _message('يرجى إدخال مسافة مقطوعة صحيحة');
    return;
  }

  setState(() => _loading = true);

  try {
    debugPrint('========== MOTORA SAVE CAR ==========');
    debugPrint('Editing: ${widget.isEditing}');
    debugPrint('Brand: $_brandId');
    debugPrint('Model: $_modelId');
    debugPrint('New images: ${_newImages.length}');
    debugPrint('Existing images: ${_existingImages.length}');

    if (widget.isEditing) {
      await _service.updateCar(
        carId: widget.car!['id'].toString(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        brandId: _brandId!,
        modelId: _modelId!,
        year: year,
        price: price,
        mileage: mileage,
        color: _color.text.trim(),
        fuelType: _fuelType!,
        transmission: _transmission!,
        existingImages: _existingImages,
        newImages: _newImages,
      );
    } else {
      await _service.addCar(
        title: _title.text.trim(),
        description: _description.text.trim(),
        brandId: _brandId!,
        modelId: _modelId!,
        year: year,
        price: price,
        mileage: mileage,
        color: _color.text.trim(),
        fuelType: _fuelType!,
        transmission: _transmission!,
        images: _newImages,
      );
    }

    debugPrint('========== SAVE SUCCESS ==========');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'تم تحديث السيارة بنجاح'
              : 'تمت إضافة السيارة بنجاح',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, true);
  } catch (e, stackTrace) {
    debugPrint('========== SAVE ERROR ==========');
    debugPrint(e.toString());
    debugPrint(stackTrace.toString());

    if (!mounted) return;

    _message(
      'فشل الحفظ: ${e.toString().replaceFirst('Exception: ', '')}',
    );
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: surface,
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'هذا الحقل مطلوب';
            }

            if (keyboardType == TextInputType.number &&
                int.tryParse(value.trim()) == null) {
              return 'أدخل رقماً صحيحاً';
            }

            if (keyboardType ==
                    const TextInputType.numberWithOptions(decimal: true) &&
                double.tryParse(value.trim()) == null) {
              return 'أدخل قيمة صحيحة';
            }

            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accent),
            filled: true,
            fillColor: surface,
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: Colors.white30),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: surface,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: accent,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accent),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
          hint: Text(
            'Select $label',
            style: const TextStyle(color: Colors.white38),
          ),
          items: items,
          onChanged: onChanged,
          validator: (value) => value == null ? 'اختر $label' : null,
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final totalImages = _existingImages.length + _newImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Car Photos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'The first available photo will be used as the main image.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: accent,
                  size: 35,
                ),
                SizedBox(height: 9),
                Text(
                  'Select Car Photos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (totalImages > 0) ...[
          const SizedBox(height: 15),
          SizedBox(
            height: 135,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._existingImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  final url = image['image_url']?.toString() ?? '';

                  return _imageTile(
                    key: ValueKey('existing_${image['id']}'),
                    image: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _brokenImage(),
                    ),
                    onRemove: () => _removeExistingImage(index),
                    label: index == 0 ? 'Main' : '${index + 1}',
                  );
                }),
                ..._newImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  final displayIndex = _existingImages.length + index;

                  return _imageTile(
                    key: ValueKey('new_${image.path}'),
                    image: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _brokenImage(),
                    ),
                    onRemove: () => _removeNewImage(index),
                    label: displayIndex == 0 ? 'Main' : '${displayIndex + 1}',
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalImages images selected',
            style: const TextStyle(color: accent, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _imageTile({
    required Key key,
    required Widget image,
    required VoidCallback onRemove,
    required String label,
  }) {
    return Container(
      key: key,
      width: 115,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: image,
            ),
          ),
          Positioned(
            top: 5,
            left: 5,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokenImage() {
    return Container(
      color: surface,
      child: const Center(
        child: Icon(Icons.image, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          editing ? 'Edit Car' : 'Add New Car',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loadingData
          ? const Center(
              child: CircularProgressIndicator(color: accent),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _field(
                    label: 'Car Title',
                    controller: _title,
                    icon: Icons.directions_car_outlined,
                  ),
                  const SizedBox(height: 20),
                  _dropdown(
                    label: 'Brand',
                    value: _brandId,
                    icon: Icons.branding_watermark_outlined,
                    items: _brands.map((brand) {
                      return DropdownMenuItem<String>(
                        value: brand['id'].toString(),
                        child: Text(brand['name'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _brandId = value);
                      _loadModels(value);
                    },
                  ),
                  const SizedBox(height: 20),
                  _dropdown(
                    label: 'Model',
                    value: _modelId,
                    icon: Icons.car_repair_outlined,
                    items: _models.map((model) {
                      return DropdownMenuItem<String>(
                        value: model['id'].toString(),
                        child: Text(model['name'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _modelId = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'Year',
                    controller: _year,
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'Price',
                    controller: _price,
                    icon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'Mileage (km)',
                    controller: _mileage,
                    icon: Icons.speed_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'Color',
                    controller: _color,
                    icon: Icons.palette_outlined,
                  ),
                  const SizedBox(height: 20),
                  _dropdown(
                    label: 'Fuel Type',
                    value: _fuelType,
                    icon: Icons.local_gas_station_outlined,
                    items: _fuelTypes.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _fuelType = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  _dropdown(
                    label: 'Transmission',
                    value: _transmission,
                    icon: Icons.settings_outlined,
                    items: _transmissions.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _transmission = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'Description',
                    controller: _description,
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 25),
                  _buildImagePicker(),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveCar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                          : Text(
                              editing ? 'Save Changes' : 'Save Car',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _year.dispose();
    _price.dispose();
    _mileage.dispose();
    _color.dispose();
    super.dispose();
  }
}