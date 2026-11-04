import 'package:flutter/material.dart';
import 'package:motora/features/inquiries/data/inquiries_service.dart';

class InquiriesPage extends StatefulWidget {
  const InquiriesPage({super.key});

  @override
  State<InquiriesPage> createState() => _InquiriesPageState();
}

class _InquiriesPageState extends State<InquiriesPage> {
  final InquiriesService _service = InquiriesService();

  late Future<List<Map<String, dynamic>>> _inquiriesFuture;

  static const Color backgroundColor = Color(0xFF101114);
  static const Color cardColor = Color(0xFF1E2024);
  static const Color accentColor = Color(0xFFF8ED00);
  static const Color secondaryText = Color(0xFF9A9CA3);

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  void _loadInquiries() {
    _inquiriesFuture = _service.getMyInquiries();
  }

  Future<void> _refresh() async {
    setState(_loadInquiries);
    await _inquiriesFuture;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'replied':
        return 'Replied';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'closed':
        return 'Closed';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'replied':
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
      case 'closed':
        return Colors.redAccent;
      default:
        return accentColor;
    }
  }

  String _carName(Map<String, dynamic>? car) {
    if (car == null) return 'Car information unavailable';

    final brand = car['brands'];
    final model = car['models'];

    final brandName = brand is Map ? brand['name']?.toString() : '';
    final modelName = model is Map ? model['name']?.toString() : '';

    final parts = [
      brandName,
      modelName,
    ].where((item) => item != null && item.isNotEmpty).toList();

    if (parts.isNotEmpty) return parts.join(' ');

    return car['title']?.toString() ?? 'Car';
  }

  String _dealershipName(Map<String, dynamic>? car) {
    if (car == null) return 'Dealership unavailable';

    final dealership = car['dealerships'];

    if (dealership is Map) {
      return dealership['name']?.toString() ?? 'Dealership';
    }

    return 'Dealership';
  }

  String? _carImage(Map<String, dynamic>? car) {
    if (car == null) return null;

    final images = car['car_images'];

    if (images is! List || images.isEmpty) return null;

    final sortedImages = List<Map<String, dynamic>>.from(
      images.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
    );

    sortedImages.sort(
      (a, b) => (a['display_order'] ?? 0).compareTo(b['display_order'] ?? 0),
    );

    if (sortedImages.isEmpty) return null;

    return sortedImages.first['image_url']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          backgroundColor: cardColor,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Inquiries',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Follow up on your car inquiries',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(_loadInquiries);
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _inquiriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildMessage(
                        icon: Icons.error_outline_rounded,
                        title: 'Something went wrong',
                        subtitle: snapshot.error.toString(),
                        showRetry: true,
                      ),
                    );
                  }

                  final inquiries = snapshot.data ?? [];

                  if (inquiries.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildMessage(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No inquiries yet',
                        subtitle:
                            'Your car inquiries will appear here once you contact a dealership.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildInquiryCard(inquiries[index]);
                        },
                        childCount: inquiries.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRetry = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 55),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            if (showRetry) ...[
              const SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  setState(_loadInquiries);
                },
                child: const Text(
                  'Try again',
                  style: TextStyle(color: accentColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryCard(Map<String, dynamic> inquiry) {
    final car = inquiry['car'] as Map<String, dynamic>?;
    final status = inquiry['status']?.toString() ?? '';
    final imageUrl = _carImage(car);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 88,
                    height: 78,
                    color: const Color(0xFF292B30),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.directions_car_rounded,
                              color: secondaryText,
                              size: 35,
                            ),
                          )
                        : const Icon(
                            Icons.directions_car_rounded,
                            color: secondaryText,
                            size: 35,
                          ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _carName(car),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            color: secondaryText,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _dealershipName(car),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            Divider(color: Colors.white.withValues(alpha: 0.07)),
            const SizedBox(height: 10),

            const Text(
              'Your message',
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              inquiry['message']?.toString() ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 17),

            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: secondaryText,
                  size: 13,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(inquiry['created_at']),
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}