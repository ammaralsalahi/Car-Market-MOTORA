
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:motora/features/home/data/cars_service.dart';
import 'package:motora/features/home/presentation/pages/car_details_page.dart';
import 'package:motora/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:motora/features/notifications/presentation/pages/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _background = Color(0xFF101114);
  static const Color _surface = Color(0xFF1E2024);
  static const Color _accent = Color(0xFFF8ED00);

  final CarsService _carsService = CarsService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _carsFuture;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCars() {
    _carsFuture = _carsService.getPublishedCars();
  }

  Future<void> _refreshCars() async {
    setState(_loadCars);
    await _carsFuture;
  }

  void _openCarDetails(Map<String, dynamic> car) {
    final brand = car['brands'] is Map
        ? car['brands']['name']?.toString() ?? ''
        : '';

    final model = car['models'] is Map
        ? car['models']['name']?.toString() ?? ''
        : '';

    final images = (car['car_images'] as List<dynamic>?) ?? [];

    debugPrint('========== MOTORA CAR DEBUG ==========');
    debugPrint('Car ID: ${car['id']}');
    debugPrint('Title: ${car['title']}');
    debugPrint('Brand: $brand');
    debugPrint('Model: $model');
    debugPrint('Color: ${car['color']}');

    for (final image in images) {
      debugPrint(
        'Image URL: ${image['image_url']} | '
        'Order: ${image['display_order']}',
      );
    }

    debugPrint('======================================');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailsPage(car: car),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Price unavailable';

    final value = double.tryParse(price.toString());

    if (value == null) return price.toString();

    return value.toStringAsFixed(0);
  }

  List<Map<String, dynamic>> _filterCars(
    List<Map<String, dynamic>> cars,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return cars;

    return cars.where((car) {
      final brand = car['brands'] is Map
          ? car['brands']['name']?.toString() ?? ''
          : '';

      final model = car['models'] is Map
          ? car['models']['name']?.toString() ?? ''
          : '';

      final dealership = car['dealerships'] is Map
          ? car['dealerships']['name']?.toString() ?? ''
          : '';

      final title = car['title']?.toString() ?? '';
      final year = car['year']?.toString() ?? '';
      final color = car['color']?.toString() ?? '';

      final searchableText =
          '$title $brand $model $dealership $year $color'.toLowerCase();

      return searchableText.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final fullName =
        user?.userMetadata?['full_name']?.toString().trim() ?? '';

    final displayName = fullName.isNotEmpty ? fullName : 'Driver';

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accent,
          backgroundColor: _surface,
          onRefresh: _refreshCars,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 25),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(),
                    const SizedBox(height: 38),
                    _buildWelcome(displayName),
                    const SizedBox(height: 28),
                    _buildSearchBar(),
                    const SizedBox(height: 32),
                    _buildSectionTitle(),
                    const SizedBox(height: 18),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                sliver: _buildCarsList(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: Colors.black,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'MOTORA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 21,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Notifications',
          onPressed: _openNotifications,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcome(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WELCOME BACK',
          style: TextStyle(
            color: _accent,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Find the car that matches your journey.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? _accent.withValues(alpha: 0.45)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: _accent,
            size: 23,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              cursorColor: _accent,
              decoration: const InputDecoration(
                hintText: 'Search cars, brands, models...',
                hintStyle: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white54,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore MOTORA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Discover your next ride',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCarsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _carsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: _CarSkeletonList(),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _buildMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load cars',
              subtitle: 'Please check your connection and try again.',
              action: true,
            ),
          );
        }

        final allCars = snapshot.data ?? [];
        final cars = _filterCars(allCars);

        if (cars.isEmpty) {
          final isSearching = _searchQuery.trim().isNotEmpty;

          return SliverToBoxAdapter(
            child: _buildMessage(
              icon: isSearching
                  ? Icons.search_off_rounded
                  : Icons.directions_car_outlined,
              title: isSearching
                  ? 'No matching cars'
                  : 'No cars available yet',
              subtitle: isSearching
                  ? 'Try another car name, brand or model.'
                  : 'Vehicles will appear here when dealerships publish them.',
              action: isSearching,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _buildCarCard(cars[index]),
            ),
            childCount: cars.length,
          ),
        );
      },
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    final brand = car['brands'] as Map<String, dynamic>?;
    final model = car['models'] as Map<String, dynamic>?;
    final dealership = car['dealerships'] as Map<String, dynamic>?;

    final images = (car['car_images'] as List<dynamic>?) ?? [];

    final sortedImages = [...images]
      ..sort(
        (a, b) => (a['display_order'] ?? 0)
            .compareTo(b['display_order'] ?? 0),
      );

    final imageUrl = sortedImages.isNotEmpty
        ? sortedImages.first['image_url']?.toString()
        : null;

    final brandName = brand?['name']?.toString() ?? '';
    final modelName = model?['name']?.toString() ?? '';

    final title = car['title']?.toString() ??
        '$brandName $modelName'.trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () => _openCarDetails(car),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 205,
                    width: double.infinity,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: FavoriteButton(
                      carId: car['id'].toString(),
                    ),
                  ),
                  Positioned(
                    top: 13,
                    right: 13,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${car['year'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Vehicle' : title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (brandName.isNotEmpty || modelName.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        '$brandName $modelName'.trim(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _carFeature(
                          Icons.speed_rounded,
                          '${car['mileage'] ?? 'N/A'} km',
                        ),
                        const SizedBox(width: 16),
                        _carFeature(
                          Icons.local_gas_station_outlined,
                          car['fuel_type']?.toString() ?? 'N/A',
                        ),
                        const SizedBox(width: 16),
                        _carFeature(
                          Icons.settings_outlined,
                          car['transmission']?.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PRICE',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _formatPrice(car['price']),
                                style: const TextStyle(
                                  color: _accent,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (dealership?['name'] != null)
                          Flexible(
                            child: Text(
                              dealership!['name'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
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
        ),
      ),
    );
  }

  Widget _carFeature(IconData icon, String value) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFF292B30),
      child: const Center(
        child: Icon(
          Icons.directions_car_rounded,
          color: Colors.white24,
          size: 65,
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool action = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: _accent, size: 45),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (action) ...[
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () {
                if (_searchQuery.isNotEmpty) {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                } else {
                  setState(_loadCars);
                }
              },
              icon: const Icon(Icons.refresh_rounded, color: _accent),
              label: Text(
                _searchQuery.isNotEmpty ? 'Clear search' : 'Try again',
                style: const TextStyle(color: _accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =======================================================
// CAR SKELETON LOADING
// =======================================================

class _CarSkeletonList extends StatefulWidget {
  const _CarSkeletonList();

  @override
  State<_CarSkeletonList> createState() => _CarSkeletonListState();
}

class _CarSkeletonListState extends State<_CarSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Color _baseColor = Color(0xFF25272D);
  static const Color _highlightColor = Color(0xFF383B43);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmer({
    required double height,
    double? width,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3 * _controller.value, 0),
              end: Alignment(-0.5 + 3 * _controller.value, 0),
              colors: const [
                _baseColor,
                _highlightColor,
                _baseColor,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          _shimmer(
            height: 205,
            width: double.infinity,
            radius: 0,
          ),

          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(height: 19, width: 175),
                const SizedBox(height: 9),

                _shimmer(height: 12, width: 115),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _shimmer(height: 13, width: 65),
                    const SizedBox(width: 16),
                    _shimmer(height: 13, width: 65),
                    const SizedBox(width: 16),
                    _shimmer(height: 13, width: 65),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  height: 1,
                  color: Colors.white10,
                ),

                const SizedBox(height: 17),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmer(height: 9, width: 42),
                        const SizedBox(height: 8),
                        _shimmer(height: 21, width: 105),
                      ],
                    ),
                    _shimmer(height: 12, width: 85),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => _buildSkeletonCard(),
      ),
    );
  }
}
