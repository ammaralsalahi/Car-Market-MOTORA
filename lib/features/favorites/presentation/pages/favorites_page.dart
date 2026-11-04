import 'package:flutter/material.dart';
import 'package:motora/features/favorites/data/favorites_service.dart';
import 'package:motora/features/home/presentation/pages/car_details_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const Color _background = Color(0xFF101114);
  static const Color _surface = Color(0xFF1E2024);
  static const Color _accent = Color(0xFFF8ED00);

  final FavoritesService _service = FavoritesService();

  late Future<List<Map<String, dynamic>>> _favoritesFuture;
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoritesFuture = _service.getFavorites();
  }

  Future<void> _refresh() async {
    setState(_loadFavorites);
    await _favoritesFuture;
  }

  Future<void> _removeFavorite(String carId) async {
    if (_removingIds.contains(carId)) return;

    setState(() => _removingIds.add(carId));

    try {
      await _service.removeFavorite(carId);

      if (!mounted) return;

      setState(_loadFavorites);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: _surface,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove favorite: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _removingIds.remove(carId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accent,
          backgroundColor: _surface,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _favoritesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _accent,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Unable to load favorites',
                        subtitle:
                            'Please check your connection and try again.',
                        buttonText: 'Try again',
                        onPressed: () {
                          setState(_loadFavorites);
                        },
                      ),
                    );
                  }

                  final favorites = snapshot.data ?? [];

                  final validFavorites = favorites.where((favorite) {
                    return favorite['cars'] != null;
                  }).toList();

                  if (validFavorites.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildMessage(
                        icon: Icons.favorite_border_rounded,
                        title: 'No favorites yet',
                        subtitle:
                            'Save cars you like and they will appear here.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      5,
                      20,
                      110,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final favorite = validFavorites[index];

                          final car = Map<String, dynamic>.from(
                            favorite['cars'] as Map,
                          );

                          return _buildCarCard(car);
                        },
                        childCount: validFavorites.length,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR COLLECTION',
            style: TextStyle(
              color: _accent,
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Favorites',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Your saved cars, all in one place.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    final carId = car['id']?.toString() ?? '';
    final title = car['title']?.toString() ?? 'Car';
    final price = car['price'];
    final year = car['year']?.toString() ?? '';
    final mileage = car['mileage']?.toString() ?? '';

    final images = car['car_images'] is List
        ? List<Map<String, dynamic>>.from(car['car_images'])
        : <Map<String, dynamic>>[];

    images.sort((a, b) {
      final first = a['display_order'] as int? ?? 0;
      final second = b['display_order'] as int? ?? 0;
      return first.compareTo(second);
    });

    final imageUrl = images.isNotEmpty
        ? images.first['image_url']?.toString() ?? ''
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _openDetails(car),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
              Positioned(
                top: 13,
                right: 13,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: carId.isEmpty ||
                            _removingIds.contains(carId)
                        ? null
                        : () => _removeFavorite(carId),
                    icon: _removingIds.contains(carId)
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accent,
                            ),
                          )
                        : const Icon(
                            Icons.favorite_rounded,
                            color: _accent,
                          ),
                  ),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _openDetails(car),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      if (year.isNotEmpty)
                        _detailItem(
                          Icons.calendar_today_rounded,
                          year,
                        ),
                      if (year.isNotEmpty && mileage.isNotEmpty)
                        const SizedBox(width: 15),
                      if (mileage.isNotEmpty)
                        _detailItem(
                          Icons.speed_rounded,
                          '$mileage km',
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatPrice(price),
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Row(
                        children: [
                          Text(
                            'View details',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _accent,
                            size: 15,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFF292B30),
      child: const Center(
        child: Icon(
          Icons.directions_car_rounded,
          color: _accent,
          size: 55,
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white54,
          size: 14,
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // يرجع Widget عادي، وليس SliverFillRemaining.
  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                color: _accent,
                size: 46,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                child: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDetails(Map<String, dynamic> car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailsPage(car: car),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Price unavailable';

    final number = num.tryParse(price.toString());

    if (number == null) return price.toString();

    return '\$${number.toStringAsFixed(0)}';
  }
}
