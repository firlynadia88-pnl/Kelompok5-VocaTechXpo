import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/constants.dart';
import '../../widgets/starry_sky.dart';
import '../client/dashboard_screen.dart';
import '../organizer/organizer_dashboard_screen.dart';
import 'register_screen.dart';

// ==================== LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _adminUsernameController =
      TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();

  String? _selectedOrganizerUkm;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  int _selectedRoleTab = 0;
  bool _isLoading = false;

  late AnimationController _starController;
  late AnimationController _shimmerController;
  late final List<Star> _stars;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final random = Random(42);
    _stars = List.generate(
      75,
      (i) => Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: random.nextDouble() * 1.8 + 0.6,
        speed: random.nextDouble() * 0.2 + 0.1,
        seed: i,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminUsernameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _starController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final String username =
        (_selectedRoleTab == 0
                ? _usernameController.text
                : _adminUsernameController.text)
            .trim();

    final String email =
        (_selectedRoleTab == 0
                ? _emailController.text
                : _adminEmailController.text)
            .trim();

    final String password =
        (_selectedRoleTab == 0
                ? _passwordController.text
                : _adminPasswordController.text)
            .trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi username, email, dan kata sandi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      final user = response.user;
      if (user == null) {
        throw const AuthException('Login tidak menghasilkan sesi pengguna.');
      }

      final metadata = user.userMetadata ?? <String, dynamic>{};
      final registeredUsername =
          (metadata['username'] ?? metadata['full_name'] ?? '')
              .toString()
              .trim();

      if (registeredUsername.isNotEmpty &&
          registeredUsername.toLowerCase() != username.toLowerCase()) {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username tidak sesuai dengan akun ini.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      late final String profileRole;

      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        profileRole = (profile?['role'] ?? '').toString().trim().toLowerCase();
      } catch (profileError) {
        await Supabase.instance.client.auth.signOut();
        throw Exception(
          'Login berhasil, tetapi role profil tidak dapat dibaca. '
          'Pastikan SQL Supabase sudah dijalankan. Detail: $profileError',
        );
      }

      final bool isOrganizer =
          profileRole == 'organizer' || profileRole == 'admin';
      final bool isClient =
          profileRole == 'mahasiswa' || profileRole == 'client';

      if (!isOrganizer && !isClient) {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Role profil belum valid. Jalankan SQL perbaikan agar public.profiles.role berisi mahasiswa atau organizer.',
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      if (!mounted) return;

      final Widget destination = isOrganizer
          ? const OrganizerDashboardScreen()
          : const DashboardScreen();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => destination),
        (route) => false,
      );
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      String errorMessage;

      if (message.contains('email not confirmed') ||
          message.contains('email_not_confirmed')) {
        errorMessage =
            'Email belum dikonfirmasi. Periksa email atau status konfirmasi di Supabase Authentication.';
      } else if (message.contains('invalid login credentials') ||
          message.contains('invalid_credentials') ||
          message.contains('password')) {
        errorMessage = 'Email atau kata sandi salah. Periksa kembali keduanya.';
      } else if (message.contains('user not found') ||
          message.contains('user_not_found')) {
        errorMessage = 'Akun tidak ditemukan di Supabase Authentication.';
      } else {
        errorMessage = 'Login gagal: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat login: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF060409),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              return CustomPaint(
                painter: StarrySkyPainter(
                  animationValue: _starController.value,
                  stars: _stars,
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                child: isDesktop
                    ? SizedBox(
                        width: double.infinity,
                        height: MediaQuery.sizeOf(context).height,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: double.infinity,
                                padding: const EdgeInsets.all(60.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF1B143F)
                                          .withValues(alpha: 0.5),
                                      const Color(0xFF060409),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.06),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.18),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.asset(
                                              'assets/images/voca_logo.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'VOCA-TECHXPO',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18,
                                                color: Colors.white,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'MARKETPLACE BOOTH',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                                color: Color(0xFF00E699),
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 36),
                                    AnimatedBuilder(
                                      animation: _shimmerController,
                                      builder: (context, child) {
                                        return ShaderMask(
                                          shaderCallback: (bounds) {
                                            final double shimmerPosition =
                                                _shimmerController.value;
                                            return LinearGradient(
                                              colors: const [
                                                Color(0xFF3B82F6),
                                                Color(0xFF8B5CF6),
                                                Colors.white,
                                                Color(0xFF8B5CF6),
                                                Color(0xFF3B82F6),
                                              ],
                                              stops: [
                                                0.0,
                                                shimmerPosition - 0.2,
                                                shimmerPosition,
                                                shimmerPosition + 0.2,
                                                1.0,
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ).createShader(bounds);
                                          },
                                          child: const Text(
                                            'Portal Inovasi & Wirausaha Digital',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 36,
                                              color: Colors.white,
                                              height: 1.2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Akses ratusan booth wirausaha digital inovatif dari mahasiswa secara real-time dan terintegrasi.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF9CA3AF),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: double.infinity,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            Expanded(
                              child: Container(
                                height: double.infinity,
                                color: const Color(0xFF030205),
                                child: Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(40.0),
                                    child: SizedBox(
                                      width: 420,
                                      child: _buildLoginFormCard(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24.0,
                          horizontal: 16.0,
                        ),
                        child: SizedBox(
                          width: 440,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.18),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        'assets/images/voca_logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'VOCA-TECHXPO',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'MARKETPLACE BOOTH SYSTEM',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 9.5,
                                          color: Color(0xFF00E699),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, child) {
                                  return ShaderMask(
                                    shaderCallback: (bounds) {
                                      final double shimmerPosition =
                                          _shimmerController.value;
                                      return LinearGradient(
                                        colors: const [
                                          Color(0xFF3B82F6),
                                          Color(0xFF8B5CF6),
                                          Colors.white,
                                          Color(0xFF8B5CF6),
                                          Color(0xFF3B82F6),
                                        ],
                                        stops: [
                                          0.0,
                                          shimmerPosition - 0.2,
                                          shimmerPosition,
                                          shimmerPosition + 0.2,
                                          1.0,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ).createShader(bounds);
                                    },
                                    child: const Text(
                                      'Portal Inovasi & Wirausaha Digital',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              _buildLoginFormCard(),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selamat Datang! 👋',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Masukkan Kredensial Akun Anda Untuk Mengakses Portal.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRoleTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedRoleTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: _selectedRoleTab == 0
                                    ? Colors.black
                                    : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Mahasiswa',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: _selectedRoleTab == 0
                                      ? Colors.black
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRoleTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedRoleTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 14,
                                color: _selectedRoleTab == 1
                                    ? Colors.black
                                    : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Organizer',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: _selectedRoleTab == 1
                                      ? Colors.black
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_selectedRoleTab == 1) ...[
                const Text(
                  'Pilih UKM Organizer',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                _buildGlassDropdown(
                  value: _selectedOrganizerUkm,
                  hint: 'Pilih UKM...',
                  items: globalUkmList,
                  onChanged: (val) {
                    setState(() {
                      _selectedOrganizerUkm = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              _buildPortfolioInputField(
                label: 'Username',
                controller: _selectedRoleTab == 0
                    ? _usernameController
                    : _adminUsernameController,
                hintText: 'Masukkan Username...',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildPortfolioInputField(
                label: 'Email Kampus',
                controller: _selectedRoleTab == 0
                    ? _emailController
                    : _adminEmailController,
                hintText: 'Masukkan Email ...',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kata Sandi',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _selectedRoleTab == 0
                                ? _passwordController
                                : _adminPasswordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: '••••••••••••',
                              hintStyle: TextStyle(color: Colors.black38),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 16,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? false;
                            });
                          },
                          activeColor: const Color(0xFF8B5CF6),
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Ingat saya di perangkat ini',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Lupa Sandi?',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Color(0xFF00E699),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.8),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _isLoading ? null : _handleLogin,
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Masuk ke Sistem',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.12),
                      thickness: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Belum punya akun?',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.12),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterScreen(isOrganizer: false),
                              ),
                            );
                          },
                          child: const Center(
                            child: Text(
                              'Daftar Mahasiswa',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterScreen(isOrganizer: true),
                              ),
                            );
                          },
                          child: const Center(
                            child: Text(
                              'Daftar Organizer',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: Color(0xFF00E699),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String hintText = '',
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 16, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: const TextStyle(color: Colors.black38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bool hasItems = items.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: !hasItems
          ? null
          : () async {
              final selected = await showDialog<String>(
                context: context,
                barrierDismissible: true,
                barrierColor: Colors.black.withValues(alpha: 0.52),
                builder: (dialogContext) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF160D25).withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFB794F6)
                                  .withValues(alpha: 0.55),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.18),
                                blurRadius: 28,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 16, 12, 12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.tune_rounded,
                                      color: Color(0xFFB794F6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        hint,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Tutup',
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 420),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    final selectedItem = item == value;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      child: Material(
                                        color: selectedItem
                                            ? const Color(0xFF8B5CF6)
                                                .withValues(alpha: 0.25)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () =>
                                              Navigator.of(dialogContext)
                                                  .pop(item),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  selectedItem
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons.circle_outlined,
                                                  size: 17,
                                                  color: selectedItem
                                                      ? const Color(0xFFC4B5FD)
                                                      : Colors.white38,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    item,
                                                    style: TextStyle(
                                                      color: selectedItem
                                                          ? Colors.white
                                                          : Colors.white
                                                              .withValues(
                                                                  alpha: 0.88),
                                                      fontSize: 13,
                                                      fontWeight: selectedItem
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );

              if (selected != null) {
                onChanged(selected);
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB794F6).withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null
                      ? Colors.white.withValues(alpha: 0.48)
                      : Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              hasItems ? Icons.keyboard_arrow_down_rounded : Icons.lock_outline,
              color: const Color(0xFFB794F6),
            ),
          ],
        ),
      ),
    );
  }
}