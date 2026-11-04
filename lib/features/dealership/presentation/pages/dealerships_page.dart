import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:motora/features/dealership/data/dealerships_service.dart';
import 'package:motora/features/dealership/presentation/pages/dealership_application_page.dart';
import 'package:motora/features/dealership/presentation/pages/dealership_dashboard_page.dart';

class DealershipsPage extends StatefulWidget {
  const DealershipsPage({super.key});

  @override
  State<DealershipsPage> createState() => _DealershipsPageState();
}

class _DealershipsPageState extends State<DealershipsPage> {
  static const Color _background = Color(0xFF101114);
  static const Color _surface = Color(0xFF1E2024);
  static const Color _accent = Color(0xFFF8ED00);

  final DealershipsService _service = DealershipsService();
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _dealershipsFuture;

  String? _myDealershipId;
  bool _checkingMembership = true;
  bool _openingPortal = false;
  String? _membershipError;

  @override
  void initState() {
    super.initState();
    _loadDealerships();
    _checkMyDealership();
  }

  void _loadDealerships() {
    _dealershipsFuture = _service.getDealerships();
  }

  Future<void> _checkMyDealership() async {
    if (mounted) {
      setState(() {
        _checkingMembership = true;
        _membershipError = null;
      });
    }

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _myDealershipId = null;
          _checkingMembership = false;
        });
        return;
      }

      final response = await _supabase
          .from('dealership_members')
          .select('dealership_id')
          .eq('user_id', user.id)
          .eq('role', 'owner')
          .limit(1);

      if (!mounted) return;

      setState(() {
        _myDealershipId = response.isNotEmpty
            ? response.first['dealership_id']?.toString()
            : null;
        _checkingMembership = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _membershipError = e.toString();
        _checkingMembership = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(_loadDealerships);
    await Future.wait([
      _dealershipsFuture,
      _checkMyDealership(),
    ]);
  }

  Future<void> _openDealershipPortal() async {
    if (_openingPortal) return;

    if (_membershipError != null) {
      await _checkMyDealership();
      return;
    }

    if (_checkingMembership) return;

    setState(() => _openingPortal = true);

    try {
      if (_myDealershipId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DealershipDashboardPage(),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DealershipApplicationPage(),
          ),
        );
      }

      if (!mounted) return;

      await _refresh();
    } finally {
      if (mounted) {
        setState(() => _openingPortal = false);
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
              SliverToBoxAdapter(
                child: _buildJoinDealershipCard(),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _dealershipsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Unable to load dealerships',
                        subtitle: 'Check your connection and try again.',
                        action: true,
                      ),
                    );
                  }

                  final dealerships = snapshot.data ?? [];

                  if (dealerships.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildMessage(
                        icon: Icons.storefront_outlined,
                        title: 'No dealerships yet',
                        subtitle:
                            'Active dealerships will appear here when available.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildDealershipCard(dealerships[index]);
                        },
                        childCount: dealerships.length,
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
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXPLORE',
            style: TextStyle(
              color: _accent,
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Dealerships',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Find trusted dealerships and explore their collections.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinDealershipCard() {
    final bool isOwner = _myDealershipId != null;

    final String buttonText;
    final IconData buttonIcon;

    if (_checkingMembership) {
      buttonText = 'Checking your account...';
      buttonIcon = Icons.hourglass_empty_rounded;
    } else if (_membershipError != null) {
      buttonText = 'Retry account check';
      buttonIcon = Icons.refresh_rounded;
    } else if (isOwner) {
      buttonText = 'Open dealership dashboard';
      buttonIcon = Icons.dashboard_rounded;
    } else {
      buttonText = 'Register your dealership';
      buttonIcon = Icons.add_business_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _accent.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isOwner
                      ? Icons.store_rounded
                      : Icons.storefront_rounded,
                  color: _accent,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwner ? 'Your dealership' : 'Own a dealership?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isOwner
                          ? 'Manage your cars and dealership.'
                          : 'Join MOTORA and showcase your cars.',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _checkingMembership || _openingPortal
                  ? null
                  : _openDealershipPortal,
              icon: _openingPortal
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Icon(buttonIcon, size: 19),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: _accent.withValues(alpha: 0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          if (_membershipError != null) ...[
            const SizedBox(height: 9),
            const Text(
              'تعذر التحقق من عضوية المعرض. تحقق من الاتصال ثم أعد المحاولة.',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDealershipCard(Map<String, dynamic> dealership) {
    final name = dealership['name']?.toString() ?? 'Dealership';
    final description = dealership['description']?.toString() ?? '';
    final address = dealership['address']?.toString() ?? '';
    final phone = dealership['phone']?.toString() ?? '';
    final logoUrl = dealership['logo_url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _logoPlaceholder(),
                  )
                : _logoPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoLine(Icons.location_on_outlined, address),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  _infoLine(Icons.phone_outlined, phone),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    return const Center(
      child: Icon(
        Icons.directions_car_filled_rounded,
        color: _accent,
        size: 29,
      ),
    );
  }

  Widget _infoLine(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool action = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accent, size: 52),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            if (action) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  setState(_loadDealerships);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}