
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:motora/features/inquiries/presentation/pages/chat_page.dart';

class CarDetailsPage extends StatelessWidget {
  final Map<String, dynamic> car;

  const CarDetailsPage({
    super.key,
    required this.car,
  });

  static const Color _background = Color(0xFF101114);
  static const Color _surface = Color(0xFF1E2024);
  static const Color _accent = Color(0xFFF8ED00);
  static const Color _muted = Color(0xFF92949B);

  @override
  Widget build(BuildContext context) {
    final brand = car['brands'] is Map
        ? car['brands'] as Map<String, dynamic>
        : null;

    final model = car['models'] is Map
        ? car['models'] as Map<String, dynamic>
        : null;

    final dealership = car['dealerships'] is Map
        ? car['dealerships'] as Map<String, dynamic>
        : null;

    final images = (car['car_images'] as List<dynamic>?) ?? [];

    final sortedImages = [...images]
      ..sort(
        (a, b) => (a['display_order'] ?? 0)
            .compareTo(b['display_order'] ?? 0),
      );

    final brandName = brand?['name']?.toString() ?? '';
    final modelName = model?['name']?.toString() ?? '';
    final title = car['title']?.toString() ??
        '$brandName $modelName'.trim();

    debugPrint('========== CAR DETAILS DEBUG ==========');
    debugPrint('Car ID: ${car['id']}');
    debugPrint('Title: ${car['title']}');
    debugPrint('Brand: $brandName');
    debugPrint('Model: $modelName');
    debugPrint('Color: ${car['color']}');

    for (final image in sortedImages) {
      debugPrint('Image: ${image['image_url']}');
    }

    debugPrint('========================================');

    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _background,
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 300,
            title: const Text(
              'Car Details',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: sortedImages.isNotEmpty
                  ? PageView.builder(
                      itemCount: sortedImages.length,
                      itemBuilder: (context, index) {
                        final url =
                            sortedImages[index]['image_url']?.toString();

                        return url != null && url.isNotEmpty
                            ? Image.network(
                                url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder();
                      },
                    )
                  : _imagePlaceholder(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 25, 22, 35),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  title.isEmpty ? 'Vehicle' : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$brandName $modelName'.trim(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                _priceCard(car['price']),
                const SizedBox(height: 30),

                _sectionTitle('Vehicle Information'),
                const SizedBox(height: 6),
                const Text(
                  'Everything you need to know about this vehicle',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                _infoGrid(car),

                const SizedBox(height: 30),
                _sectionTitle('Description'),
                const SizedBox(height: 12),
                Text(
                  car['description']?.toString().isNotEmpty == true
                      ? car['description'].toString()
                      : 'No description available.',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),

                const SizedBox(height: 28),
                _sectionTitle('Dealership'),
                const SizedBox(height: 14),
                _dealershipCard(dealership),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _contactDealership(context),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'Contact Dealership',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactDealership(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to contact the dealership'),
        ),
      );
      return;
    }

    final carId = car['id']?.toString();

    if (carId == null || carId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Car information is unavailable'),
        ),
      );
      return;
    }

    final controller = TextEditingController();

    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          title: const Text(
            'Contact Dealership',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Write your message...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: _background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isNotEmpty) {
                  Navigator.pop(dialogContext, text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (message == null || message.trim().isEmpty) return;

    try {
      // إنشاء المحادثة.
      final inquiry = await supabase
          .from('inquiries')
          .insert({
            'user_id': user.id,
            'car_id': carId,
            'message': message,
            'status': 'open',
          })
          .select()
          .single();

      // حفظ الرسالة الأولى داخل المحادثة.
      await supabase.from('inquiry_messages').insert({
        'inquiry_id': inquiry['id'],
        'sender_id': user.id,
        'message': message,
      });

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
  inquiry: {
    ...inquiry,
    'car': car,
  },
)
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start conversation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _priceCard(dynamic price) {
    final value = double.tryParse(price?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VEHICLE PRICE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value == null
                ? 'Price unavailable'
                : value.toStringAsFixed(0),
            style: const TextStyle(
              color: _accent,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Color _getCarColor(String color) {
    switch (color.trim().toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'brown':
        return Colors.brown;
      default:
        return Colors.transparent;
    }
  }

  Widget _infoGrid(Map<String, dynamic> car) {
    final year = car['year']?.toString() ?? 'N/A';
    final mileage = car['mileage']?.toString() ?? 'N/A';
    final color = car['color']?.toString() ?? 'N/A';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _highlightInfo(
                icon: Icons.calendar_month_rounded,
                label: 'MODEL YEAR',
                value: year,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _highlightInfo(
                icon: Icons.speed_rounded,
                label: 'MILEAGE',
                value: mileage == 'N/A' ? 'N/A' : '$mileage km',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              _specificationRow(
                icon: Icons.local_gas_station_rounded,
                title: 'Fuel Type',
                value: car['fuel_type']?.toString() ?? 'N/A',
              ),
              _specificationDivider(),
              _specificationRow(
                icon: Icons.settings_rounded,
                title: 'Transmission',
                value: car['transmission']?.toString() ?? 'N/A',
              ),
              _specificationDivider(),
              _specificationRow(
                icon: Icons.palette_outlined,
                title: 'Exterior Color',
                value: color,
                colorIndicator: _getCarColor(color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _highlightInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _accent.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accent, size: 20),
              const Spacer(),
              const Icon(
                Icons.arrow_outward_rounded,
                color: Colors.white24,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 19),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _specificationRow({
    required IconData icon,
    required String title,
    required String value,
    Color? colorIndicator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: _accent,
              size: 19,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (colorIndicator != null &&
              colorIndicator != Colors.transparent) ...[
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: colorIndicator,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specificationDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }

  Widget _dealershipCard(Map<String, dynamic>? dealership) {
    final name = dealership?['name']?.toString() ?? 'Dealership';
    final logo = dealership?['logo_url']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: logo != null && logo.isNotEmpty
                ? Image.network(
                    logo,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _dealershipIcon(),
                  )
                : _dealershipIcon(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.verified_outlined,
            color: _accent,
          ),
        ],
      ),
    );
  }

  Widget _dealershipIcon() {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFF303238),
      child: const Icon(
        Icons.storefront_rounded,
        color: _accent,
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _surface,
      child: const Center(
        child: Icon(
          Icons.directions_car_rounded,
          color: Colors.white24,
          size: 75,
        ),
      ),
    );
  }
}
