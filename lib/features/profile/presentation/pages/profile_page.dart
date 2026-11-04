import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:motora/features/auth/data/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _background = Color(0xFF101114);
  static const Color _surface = Color(0xFF1E2024);
  static const Color _accent = Color(0xFFF8ED00);

  final AuthService _authService = AuthService();

  late Future<Map<String, dynamic>?> _profileFuture;

  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getMyProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = _authService.getMyProfile();
    });

    await _profileFuture;
  }

  Future<void> _signOut() async {
    if (_signingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          title: const Text(
            'Sign out?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Sign out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);

    try {
      await _authService.signOut();

      // AuthGate handles navigation after the session ends.
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not sign out: $error'),
          backgroundColor: Colors.red.shade800,
        ),
      );

      setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accent,
          backgroundColor: _surface,
          onRefresh: _refreshProfile,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data ?? {};

              final name = profile['full_name']?.toString().trim();
              final fullName =
                  name != null && name.isNotEmpty ? name : 'MOTORA User';

              final email = user?.email ?? 'No email available';
              final phone = profile['phone']?.toString() ?? '';
              final role = profile['role']?.toString() ?? 'customer';

              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 25, 22, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACCOUNT',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 10,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'My Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Profile avatar
                          Center(
                            child: Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(35),
                                border: Border.all(
                                  color: _accent.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: _accent,
                                size: 58,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Center(
                            child: Text(
                              isLoading ? 'Loading profile...' : fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),

                          const SizedBox(height: 7),

                          Center(
                            child: Text(
                              email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: _accent.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                role == 'platform_admin'
                                    ? 'PLATFORM ADMIN'
                                    : 'CUSTOMER ACCOUNT',
                                style: const TextStyle(
                                  color: _accent,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 35),

                          _sectionTitle('PERSONAL INFORMATION'),

                          const SizedBox(height: 14),

                          _profileTile(
                            icon: Icons.person_outline_rounded,
                            label: 'Full name',
                            value: fullName,
                          ),

                          _profileTile(
                            icon: Icons.email_outlined,
                            label: 'Email address',
                            value: email,
                          ),

                          _profileTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone number',
                            value: phone.isEmpty ? 'Not provided' : phone,
                          ),

                          _profileTile(
                            icon: Icons.verified_user_outlined,
                            label: 'Account type',
                            value: role == 'platform_admin'
                                ? 'Platform administrator'
                                : 'Customer',
                          ),

                          const SizedBox(height: 25),

                          _sectionTitle('ACCOUNT SETTINGS'),

                          const SizedBox(height: 14),

                          _profileTile(
                            icon: Icons.shield_outlined,
                            label: 'Account security',
                            value: 'Managed by Supabase Auth',
                            showArrow: false,
                          ),

                          _profileTile(
                            icon: Icons.info_outline_rounded,
                            label: 'Application',
                            value: 'MOTORA',
                            showArrow: false,
                          ),

                          const SizedBox(height: 30),

                          // Refresh profile
                          SizedBox(
                            width: double.infinity,
                            height: 49,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _refreshProfile,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 19,
                              ),
                              label: const Text('Refresh profile'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 13),

                          // Sign out
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: _signingOut ? null : _signOut,
                              icon: _signingOut
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.redAccent,
                                      ),
                                    )
                                  : const Icon(Icons.logout_rounded),
                              label: Text(
                                _signingOut
                                    ? 'Signing out...'
                                    : 'Sign out',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                          if (snapshot.hasError) ...[
                            const SizedBox(height: 18),
                            Text(
                              'Profile details could not be loaded. '
                              'Your login session is still active.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontSize: 11,
                              ),
                            ),
                          ],

                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _accent,
        fontSize: 10,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String label,
    required String value,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white30,
              size: 19,
            ),
        ],
      ),
    );
  }
}