import 'package:flutter/material.dart';

import 'package:motora/features/dealership/data/dealership_management_service.dart';
import 'package:motora/features/dealership/presentation/pages/add_car_page.dart';

class DealershipDashboardPage extends StatefulWidget {
  const DealershipDashboardPage({super.key});

  @override
  State<DealershipDashboardPage> createState() =>
      _DealershipDashboardPageState();
}

class _DealershipDashboardPageState
    extends State<DealershipDashboardPage> {
  static const Color background = Color(0xFF101114);
  static const Color surface = Color(0xFF1E2024);
  static const Color accent = Color(0xFFF8ED00);

  final _service = DealershipManagementService();

  late Future<Map<String, dynamic>> _dealershipFuture;
  late Future<List<Map<String, dynamic>>> _carsFuture;

  final Set<String> _processingCars = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dealershipFuture = _service.getMyDealership();
    _carsFuture = _service.getMyCars();
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await Future.wait([_dealershipFuture, _carsFuture]);
  }

  Future<void> _openAddCar() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddCarPage()),
    );

    if (!mounted) return;
    if (result == true) setState(_loadData);
  }

  Future<void> _editCar(Map<String, dynamic> car) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddCarPage(car: car)),
    );

    if (!mounted) return;
    if (result == true) setState(_loadData);
  }

  Future<void> _togglePublish(Map<String, dynamic> car) async {
    final carId = car['id'].toString();
    final isPublished = car['status'] == 'published';

    setState(() => _processingCars.add(carId));

    try {
      await _service.setCarPublished(
        carId: carId,
        published: !isPublished,
      );

      if (!mounted) return;

      _message(
        isPublished
            ? 'تم إخفاء السيارة من الصفحة الرئيسية'
            : 'تم نشر السيارة في الصفحة الرئيسية',
        success: true,
      );

      setState(_loadData);
    } catch (e) {
      if (!mounted) return;
      _message('تعذر تغيير حالة السيارة: $e');
    } finally {
      if (mounted) {
        setState(() => _processingCars.remove(carId));
      }
    }
  }

  Future<void> _deleteCar(Map<String, dynamic> car) async {
    final carId = car['id'].toString();
    final title = car['title']?.toString() ?? 'هذه السيارة';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface,
          title: const Text(
            'حذف السيارة',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'هل أنت متأكد من حذف "$title"؟ سيتم حذف صور السيارة أيضاً.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingCars.add(carId));

    try {
      await _service.deleteCar(carId);

      if (!mounted) return;

      _message('تم حذف السيارة وصورها بنجاح', success: true);
      setState(_loadData);
    } catch (e) {
      if (!mounted) return;
      _message('تعذر حذف السيارة: $e');
    } finally {
      if (mounted) {
        setState(() => _processingCars.remove(carId));
      }
    }
  }

  void _message(String text, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: success ? Colors.green.shade700 : surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dealership Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCar,
        backgroundColor: accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Car',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        color: accent,
        backgroundColor: surface,
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dealershipFuture,
          builder: (context, dealershipSnapshot) {
            if (dealershipSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: accent),
              );
            }

            if (dealershipSnapshot.hasError) {
              return _errorView(dealershipSnapshot.error.toString());
            }

            final dealership = dealershipSnapshot.data ?? {};

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _carsFuture,
              builder: (context, carsSnapshot) {
                if (carsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: accent),
                  );
                }

                if (carsSnapshot.hasError) {
                  return _errorView(carsSnapshot.error.toString());
                }

                final cars = carsSnapshot.data ?? [];

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                  children: [
                    _buildWelcome(dealership),
                    const SizedBox(height: 22),
                    _buildStatistics(cars),
                    const SizedBox(height: 27),
                    const Text(
                      'My Cars',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (cars.isEmpty)
                      _emptyCars()
                    else
                      ...cars.map(_buildCarCard),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcome(Map<String, dynamic> dealership) {
    final name = dealership['name']?.toString() ?? 'Dealership';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront_rounded, color: accent, size: 34),
          const SizedBox(height: 15),
          Text(
            'Welcome back',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Manage your vehicles and dealership listings.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(List<Map<String, dynamic>> cars) {
    final published = cars.where((car) => car['status'] == 'published').length;
    final drafts = cars.length - published;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _statItem('Total Cars', cars.length.toString(), Icons.directions_car),
          _statItem('Published', published.toString(), Icons.public),
          _statItem('Drafts', drafts.toString(), Icons.edit_note),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: accent, size: 23),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    final images = List<Map<String, dynamic>>.from(
      (car['car_images'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );

    images.sort(
      (a, b) => (a['display_order'] as num? ?? 0)
          .compareTo(b['display_order'] as num? ?? 0),
    );

    final imageUrl = images.isNotEmpty
        ? images.first['image_url']?.toString() ?? ''
        : '';

    final carId = car['id'].toString();
    final title = car['title']?.toString() ?? 'Car';
    final status = car['status']?.toString() ?? 'draft';
    final isPublished = status == 'published';
    final isProcessing = _processingCars.contains(carId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${car['price'] ?? 0} USD',
                        style: const TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${car['year'] ?? '-'} • ${car['mileage'] ?? '-'} km • ${images.length} photos',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 14),
                if (isProcessing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(color: accent),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _actionButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        onTap: () => _editCar(car),
                      ),
                      _actionButton(
                        label: isPublished ? 'Unpublish' : 'Publish',
                        icon: isPublished
                            ? Icons.visibility_off_outlined
                            : Icons.publish_rounded,
                        onTap: () => _togglePublish(car),
                        primary: !isPublished,
                      ),
                      _actionButton(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        onTap: () => _deleteCar(car),
                        danger: true,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
    bool danger = false,
  }) {
    final color = danger
        ? Colors.redAccent
        : primary
            ? accent
            : Colors.white70;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: primary ? Colors.black : color,
        backgroundColor: primary ? accent : Colors.transparent,
        side: BorderSide(
          color: primary ? accent : color.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isPublished = status == 'published';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isPublished
            ? Colors.green.withValues(alpha: 0.12)
            : accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPublished ? 'Published' : status,
        style: TextStyle(
          color: isPublished ? Colors.greenAccent : accent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFF292B30),
      child: const Center(
        child: Icon(
          Icons.directions_car_rounded,
          color: accent,
          size: 50,
        ),
      ),
    );
  }

  Widget _emptyCars() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.directions_car_outlined, color: accent, size: 48),
          SizedBox(height: 15),
          Text(
            'No cars added yet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start by adding your first vehicle.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _errorView(String error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(25),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
        const SizedBox(height: 15),
        const Text(
          'Unable to load dealership dashboard',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () => setState(_loadData),
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}