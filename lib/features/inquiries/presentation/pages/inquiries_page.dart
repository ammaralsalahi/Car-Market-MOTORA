
import 'package:flutter/material.dart';

import 'package:motora/features/inquiries/data/inquiries_service.dart';
import 'package:motora/features/inquiries/presentation/pages/chat_page.dart';

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

  String _carName(Map<String, dynamic>? car) {
    if (car == null) return 'Car information unavailable';

    final brand = car['brands'];
    final model = car['models'];

    final brandName = brand is Map ? brand['name']?.toString() ?? '' : '';
    final modelName = model is Map ? model['name']?.toString() ?? '' : '';

    final parts = [
      brandName,
      modelName,
    ].where((item) => item.isNotEmpty).toList();

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
      images.whereType<Map>().map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    sortedImages.sort(
      (a, b) => (a['display_order'] ?? 0).compareTo(
        b['display_order'] ?? 0,
      ),
    );

    if (sortedImages.isEmpty) return null;

    return sortedImages.first['image_url']?.toString();
  }

  Future<void> _openChat(Map<String, dynamic> inquiry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(inquiry: inquiry),
      ),
    );

    if (mounted) {
      setState(_loadInquiries);
    }
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
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Messages',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Chat with your favorite dealerships',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(_loadInquiries);
                          },
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _inquiriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
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
                      child: _buildEmptyState(
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
                      child: _buildEmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No conversations yet',
                        subtitle:
                            'Contact a dealership from a car details page to start a conversation.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildConversationCard(
                            inquiries[index],
                          );
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

  Widget _buildEmptyState({
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

  Widget _buildConversationCard(Map<String, dynamic> inquiry) {
    final car = inquiry['car'] as Map<String, dynamic>?;
    final imageUrl = _carImage(car);
    final message = inquiry['message']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openChat(inquiry),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: const Color(0xFF292B30),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _carPlaceholder(),
                          )
                        : _carPlaceholder(),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dealershipName(car),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _carName(car),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message.isEmpty ? 'Start chatting...' : message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(inquiry['created_at']),
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: accentColor,
                      size: 15,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _carPlaceholder() {
    return const Center(
      child: Icon(
        Icons.directions_car_rounded,
        color: secondaryText,
        size: 32,
      ),
    );
  }
}
