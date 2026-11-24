import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'services/chat_service.dart';
import 'models/chat_message.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: 'https://bptllbnxpuglooqdmmyv.supabase.co',
    anonKey: 'sb_publishable_QctjbhHmweqyiB74MLfRuA_Z2Xr-sNR',
  );
  runApp(const MyApp());
}

final List<String> globalUkmList = [
  'UKM IECLOP (Improving English Club of Polytechnic)',
  'UKM LDK-FORDIMA',
  'UKM POLICY (Polytechnic Linux Community)',
  'UKM Sanggar Seni',
  'UKM Edelweis',
  'UKM Taekwondo',
  'UKM Polyrobocom',
  'UKM Merpati Putih',
  'BEM',
  'HIMATIK',
  'HIMABIS',
  'HIMA ELEKTRO',
  'HIMA MESIN',
  'HIMA SIPIL',
  'Wirausaha Mahasiswa Mandiri (UMKM)',
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voca-techXpo',
      home: SplashScreen(),
    );
  }
}

// ==================== 1. SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _splashController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late final List<Star> _stars;

  @override
  void initState() {
    super.initState();
    // Durasi diperpanjang agar pergerakan bintang jauh lebih lambat
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeIn),
    );
    _splashController.forward();
    final random = Random(42);
    _stars = List.generate(75, (i) => Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radius: random.nextDouble() * 1.8 + 0.6,
      speed: random.nextDouble() * 0.2 + 0.1, // Kecepatan diperkecil agar lambat
      seed: i,
    ));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var scaleTween = Tween<double>(begin: 0.9, end: 1.0).chain(
                CurveTween(curve: Curves.easeOutCubic),
              );
              var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: Curves.easeIn),
              );
              return FadeTransition(
                opacity: animation.drive(fadeTween),
                child: ScaleTransition(
                  scale: animation.drive(scaleTween),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _splashController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Center(
            child: AnimatedBuilder(
              animation: _splashController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  final double shimmerPosition = _shimmerController.value;
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
                                  'VOCA TECHXPO',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 38,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'EVENT WIRAUSAHA MAHASISWA MARKETPLACE BOOTH',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF00E699),
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 2. LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _adminUsernameController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
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
    _stars = List.generate(75, (i) => Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radius: random.nextDouble() * 1.8 + 0.6,
      speed: random.nextDouble() * 0.2 + 0.1,
      seed: i,
    ));
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
    final String username = (_selectedRoleTab == 0
            ? _usernameController.text
            : _adminUsernameController.text)
        .trim();
    final String email = (_selectedRoleTab == 0
            ? _emailController.text
            : _adminEmailController.text)
        .trim();
    final String password = (_selectedRoleTab == 0
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
      final AuthResponse response =
          await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

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

      // Role di public.profiles menjadi sumber utama untuk memilih dashboard.
      // Metadata Auth tidak dipakai sebagai sumber hak akses.
      late final String profileRole;
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        profileRole = (profile?['role'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
      } catch (profileError) {
        await Supabase.instance.client.auth.signOut();
        throw Exception(
          'Login berhasil, tetapi role profil tidak dapat dibaca. '
          'Pastikan SQL Supabase sudah dijalankan. Detail: $profileError',
        );
      }

      // Role 'admin' merupakan sisa data lama; migrasi SQL memetakannya ke
      // 'organizer'. Tetap ditangani sementara untuk kompatibilitas.
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
                                      const Color(0xFF1B143F).withOpacity(0.5),
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
                                            color: Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white.withOpacity(0.18)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.asset(
                                              'assets/images/voca_logo.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                            final double shimmerPosition = _shimmerController.value;
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
                              color: Colors.white.withOpacity(0.08),
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
                        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
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
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white.withOpacity(0.18)),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                      final double shimmerPosition = _shimmerController.value;
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
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
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
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRoleTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedRoleTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: _selectedRoleTab == 0 ? Colors.black : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Mahasiswa',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: _selectedRoleTab == 0 ? Colors.black : Colors.white60,
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
                            color: _selectedRoleTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 14,
                                color: _selectedRoleTab == 1 ? Colors.black : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Organizer',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: _selectedRoleTab == 1 ? Colors.black : Colors.white60,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedOrganizerUkm,
                      hint: const Text('Pilih UKM...', style: TextStyle(color: Colors.black38, fontSize: 12)),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8B5CF6)),
                      items: globalUkmList.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(color: Colors.black87, fontSize: 11),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedOrganizerUkm = val;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildPortfolioInputField(
                label: 'Username',
                controller: _selectedRoleTab == 0 ? _usernameController : _adminUsernameController,
                hintText: 'Masukkan Username...',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildPortfolioInputField(
                label: 'Email Kampus',
                controller: _selectedRoleTab == 0 ? _emailController : _adminEmailController,
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
                            controller: _selectedRoleTab == 0 ? _passwordController : _adminPasswordController,
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
                          side: BorderSide(color: Colors.white.withOpacity(0.4)),
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
                          const Color(0xFF3B82F6).withOpacity(0.8),
                          const Color(0xFF8B5CF6).withOpacity(0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
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
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
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
                    child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Belum punya akun?',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1),
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
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen(isOrganizer: false)),
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
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen(isOrganizer: true)),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
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
}

// ==================== 3. REGISTER SCREEN ====================
class RegisterScreen extends StatefulWidget {
  final bool isOrganizer;
  const RegisterScreen({super.key, this.isOrganizer = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;
  late AnimationController _starController;
  late AnimationController _shimmerController;
  late final List<Star> _stars;
  
  final List<String> _jurusanList = [
    'Teknik Elektro',
    'Teknik Mesin',
    'Teknik Kimia',
    'Teknik Sipil',
    'Bisnis',
    'Teknologi Informasi dan Komputer',
  ];
  final List<String> _angkatanList = ['2024', '2023', '2022', '2021', '2020'];
  String? _selectedJurusan;
  String? _selectedAngkatan = '2024';
  String? _selectedProdi;
  String? _selectedUkm;
  
  final Map<String, List<String>> _prodiMap = {
    'Teknologi Informasi dan Komputer': [
      'Teknik Informatika',
      'Teknologi Rekayasa Komputer Jaringan (TRKJ)',
      'Teknologi Rekayasa Multimedia',
      'Teknologi Rekayasa Perangkat Lunak',
      'Teknik Multimedia dan Jaringan',
    ],
    'Teknik Elektro': [
      'Teknologi Elektronika',
      'Teknologi Listrik',
      'Teknologi Telekomunikasi',
      'Teknologi Rekayasa Jaringan Telekomunikasi',
      'Teknologi Rekayasa Instrumentasi dan Kontrol',
      'Teknologi Rekayasa Pembangkit Energi',
      'Teknologi Rekayasa Mekatronika',
    ],
    'Teknik Mesin': [
      'Teknologi Mesin',
      'Teknologi Industri',
      'Teknologi Rekayasa Manufaktur',
      'Teknologi Rekayasa Pengelasan dan Fabrikasi',
    ],
    'Teknik Kimia': [
      'Teknologi Kimia',
      'Teknologi Pengolahan Minyak dan Gas',
      'Teknologi Rekayasa Kimia Industri',
      'Teknologi Rekayasa Kimia Berkelanjutan',
    ],
    'Teknik Sipil': [
      'Teknologi Konstruksi Bangunan Air',
      'Teknologi Konstruksi Bangunan Gedung',
      'Teknologi Konstruksi Jalan dan Jembatan',
      'Teknologi Rekayasa Konstruksi Bangunan Gedung',
      'Teknologi Rekayasa Konstruksi Jalan dan Jembatan',
      'Rekayasa Transportasi',
    ],
    'Bisnis': [
      'Administrasi Bisnis',
      'Akuntansi',
      'Perbankan dan Keuangan',
      'Akuntansi Lembaga Keuangan Syariah',
      'Akuntansi Sektor Publik',
      'Manajemen Keuangan Sektor Publik',
      'Bahasa Inggris untuk Komunikasi Bisnis dan Profesional',
      'Keuangan Islam Terapan (S2 Terapan)',
    ],
  };

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
    _stars = List.generate(75, (i) => Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radius: random.nextDouble() * 1.8 + 0.6,
      speed: random.nextDouble() * 0.2 + 0.1,
      seed: i,
    ));
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _starController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_namaController.text.isEmpty ||
        _nimController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _selectedUkm == null ||
        (!widget.isOrganizer && (_selectedJurusan == null || _selectedProdi == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data formulir pendaftaran!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi dan konfirmasi kata sandi tidak cocok!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'role': widget.isOrganizer ? 'organizer' : 'mahasiswa',
          'username': _namaController.text.trim(),
          'nim': _nimController.text.trim(),
          'phone': _phoneController.text.trim(),
          'ukm': _selectedUkm,
          'jurusan': widget.isOrganizer ? '-' : _selectedJurusan,
          'prodi': widget.isOrganizer ? '-' : _selectedProdi,
          'angkatan': _selectedAngkatan,
        },
      );
      if (response.user != null && mounted) {
        // Jika verifikasi email aktif, belum ada sesi untuk mengirim pengajuan booth.
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Akun berhasil dibuat. Konfirmasi email terlebih dahulu, lalu login untuk melanjutkan panduan booth.',
              ),
              backgroundColor: Color(0xFF8B5CF6),
              duration: Duration(seconds: 6),
            ),
          );
          Navigator.of(context).pop();
          return;
        }

        if (widget.isOrganizer) {
          // Setelah registrasi Organizer berhasil, langsung arahkan ke panduan buka booth.
          // pushReplacement membuat tombol kembali pada halaman panduan kembali ke Login,
          // bukan ke formulir registrasi Organizer yang sudah selesai.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran Organizer berhasil! Silakan ikuti panduan buka booth.'),
              backgroundColor: Color(0xFF00A878),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const BoothOnboardingScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran Mahasiswa Berhasil!'),
              backgroundColor: Color(0xFF00A878),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Mendaftar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = widget.isOrganizer ? 'Registrasi Akun Organizer' : 'Registrasi Akun Mahasiswa';
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        titleText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: 840,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.isOrganizer 
                                        ? 'Lengkapi Data Organizer dan Pilih UKM Penanggung Jawab Event.'
                                        : 'Lengkapi Data Identitas Kemahasiswaan & UKM Anda Untuk Pendaftaran Event Booth.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField('Nama Lengkap / Username', _namaController, Icons.person_outline, 'Masukkan Nama...'),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField('NIM / ID Anggota', _nimController, Icons.badge_outlined, 'Masukkan NIM/ID...'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField('Email Kampus / Resmi', _emailController, Icons.email_outlined, 'Masukkan Email...'),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField('Nomor WhatsApp', _phoneController, Icons.phone_android_rounded, 'Masukkan No WhatsApp...', keyboardType: TextInputType.phone),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pilihan UKM', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                                      const SizedBox(height: 6),
                                      _buildGlassDropdown(
                                        value: _selectedUkm,
                                        hint: 'Pilih UKM...',
                                        items: globalUkmList,
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedUkm = val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (!widget.isOrganizer) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Jurusan', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                                              const SizedBox(height: 6),
                                              _buildGlassDropdown(
                                                value: _selectedJurusan,
                                                hint: 'Pilih Jurusan...',
                                                items: _jurusanList,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _selectedJurusan = val;
                                                    _selectedProdi = null;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Angkatan', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                                              const SizedBox(height: 6),
                                              _buildGlassDropdown(
                                                value: _selectedAngkatan,
                                                hint: 'Pilih Angkatan...',
                                                items: _angkatanList,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _selectedAngkatan = val;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Program Studi', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                                        const SizedBox(height: 6),
                                        _buildGlassDropdown(
                                          value: _selectedProdi,
                                          hint: _selectedJurusan == null ? 'Pilih Jurusan terlebih dahulu...' : 'Pilih Program Studi...',
                                          items: _selectedJurusan == null ? [] : _prodiMap[_selectedJurusan!]!,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedProdi = val;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildPasswordField('Kata Sandi', _passwordController, _obscurePassword, () {
                                          setState(() => _obscurePassword = !_obscurePassword);
                                        }),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildPasswordField('Konfirmasi Kata Sandi', _confirmPasswordController, _obscureConfirmPassword, () {
                                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _agreeTerms,
                                        onChanged: (val) => setState(() => _agreeTerms = val ?? true),
                                        activeColor: const Color(0xFF8B5CF6),
                                        checkColor: Colors.white,
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Saya menyatakan bahwa data yang diinput adalah benar dan bersedia mematuhi tata tertib event.',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: _isLoading ? null : _handleRegister,
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : const Text(
                                              'Daftarkan Akun Baru',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.black38),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscure, VoidCallback onTapToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '••••••••••••',
                    hintStyle: TextStyle(color: Colors.black38),
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTapToggle,
                child: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF8B5CF6),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.black38, fontSize: 13)),
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8B5CF6)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(color: Colors.black87, fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ==================== 4. DASHBOARD SCREEN CLIENT ====================
// DASHBOARD SCREEN CLIENT: dipertahankan untuk role mahasiswa/client.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _selectedTabFilter = 0; 
  int _currentBannerIndex = 0;
  int _currentPosterIndex = 0;
  
  bool _hasUnreadMessages = true;
  bool _isDarkMode = false;
  int _membershipTab = 0;
  String _selectedFont = 'ppins';

  late final AnimationController _shimmerController = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat();

  final List<Map<String, dynamic>> _incomingMessages = [
    {'sender': 'Panitia Expo 2026', 'message': 'Halo tenant, mohon konfirmasi kehadiran pitching.', 'time': '10:15'},
    {'sender': 'Klien - Budi Santoso', 'message': 'Apakah stok Smart Hydroponic ready?', 'time': '09:30'},
    {'sender': 'Organizer Utama', 'message': 'Pemberitahuan: Setup booth dimulai pukul 08.00.', 'time': 'Kemarin'},
  ];

  final PageController _bannerController = PageController();
  final PageController _posterController = PageController();

  Timer? _posterTimer;

  final List<String> _bannerImages = [
    'assets/images/banner_1.PNG',
    'assets/images/banner_2.PNG',
    'assets/images/banner_3.PNG',
  ];

  final List<String> _posterImages = [
    'assets/images/poster_tenant_sanggar.png',
    'assets/images/poster_umkm_pom.jpeg',
    'assets/images/poster_bisnis_fest.jpeg',  
  ];

  final List<Map<String, dynamic>> _boothList = [
    {
      'title': 'Pastry Larana Booth',
      'category': 'Kuliner & F&B',
      'owner': 'UKM IECLOP',
      'price': 'Rp 10.000',
      'badge': 'Promo Hangat',
      'image': 'assets/images/Promo_Booth_Kue_Larana.png',
    },
    {
      'title': 'Open Koperasi Booth',
      'category': 'Koperasi UKM',
      'owner': 'UKM LDK-Fordima',
      'price': 'Rp 10.000',
      'badge': '', 
      'image': 'assets/images/Poster_Promosi_Open_Koperasi.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _posterTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (_posterController.hasClients) {
        int nextPage = _currentPosterIndex + 1;
        if (nextPage >= _posterImages.length) {
          nextPage = 0;
        }
        _posterController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _posterController.dispose();
    _shimmerController.dispose();
    _posterTimer?.cancel();
    super.dispose();
  }

  void _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 900;

    final Color bgColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final Color searchBgColor = _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: isDesktop ? null : _buildSidebarContent(context, isMobile: true),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  if (!isDesktop) ...[
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu_rounded, color: textColor),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'VOCA-TECHXPO',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: isDesktop ? 260 : 130,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: searchBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            onChanged: (val) {},
                            style: TextStyle(color: textColor, fontSize: 12),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Cari ...',
                              hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isDesktop) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDarkMode = !_isDarkMode;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: searchBgColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Icon(
                          _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: textColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _currentIndex == 1 ? Color(0xFF8B5CF6).withOpacity(0.2) : searchBgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _currentIndex == 1 ? const Color(0xFF8B5CF6) : Colors.transparent,
                        ),
                      ),
                      child: Icon(Icons.person_outline, color: _currentIndex == 1 ? const Color(0xFF8B5CF6) : textColor, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 260,
              child: _buildSidebarContent(context, isMobile: false),
            ),
          Expanded(
            child: _getSelectedBodyContent(),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedBodyContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent(MediaQuery.sizeOf(context).width > 900);
      case 1:
        return _buildProfileContent(context);
      case 2:
        return ChatRoomsScreen(
          isOrganizer: false,
          onBack: () {
            setState(() => _currentIndex = 0);
          },
        );
      case 3:
        return ChatRoomsScreen(
          isOrganizer: false,
          onBack: () {
            setState(() => _currentIndex = 0);
          },
        );
      default:
        return _buildHomeContent(MediaQuery.sizeOf(context).width > 900);
    }
  }

  Widget _buildSidebarContent(BuildContext context, {required bool isMobile}) {
    return Container(
      color: const Color(0xFF581C87), 
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const Text(
            'Menu',
            style: TextStyle(fontSize: 11, color: Colors.white60, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          _buildDrawerItem(0, Icons.home_rounded, 'Dashboard', isMobile),
          const SizedBox(height: 8),
          _buildDrawerItem(99, Icons.storefront_rounded, 'Temukan Event', isMobile, hasDropdown: true),
          const SizedBox(height: 8),
          _buildDrawerItem(97, Icons.star_border_rounded, 'Rating', isMobile),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 16),
          const Text(
            'Komunikasi & Layanan',
            style: TextStyle(fontSize: 11, color: Colors.white60, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          _buildDrawerItem(
            2,
            Icons.forum_rounded,
            'Pesan',
            isMobile,
            showRedDot: _hasUnreadMessages,
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 16),
          const Text(
            'Akun',
            style: TextStyle(fontSize: 11, color: Colors.white60, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          _buildDrawerItem(1, Icons.person_outline_rounded, 'Profile', isMobile),
          const SizedBox(height: 8),
          _buildDrawerItem(95, Icons.logout_rounded, 'Keluar', isMobile, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label, bool isMobile, {bool hasDropdown = false, bool isLogout = false, bool showRedDot = false}) {
    bool isSelected = (_currentIndex == index);
    return GestureDetector(
      onTap: () {
        if (isLogout) {
          _handleLogout(context);
          return;
        }
        if (index >= 0 && index <= 3) {
          setState(() {
            _currentIndex = index;
            if (index == 2) {
              _hasUnreadMessages = false;
            }
          });
        }
        if (isMobile) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF2E1065) : Colors.white70,
                ),
                if (showRedDot)
                  Positioned(
                    right: -2,
                    top: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF2E1065) : Colors.white,
                ),
              ),
            ),
            if (hasDropdown)
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOrganizerContent() {
    final Color cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola komunikasi langsung dengan panitia event dan calon pembeli/klien booth Anda.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _incomingMessages.length,
              itemBuilder: (context, index) {
                final chat = _incomingMessages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF8B5CF6),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  chat['sender']!,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                                ),
                                Text(
                                  chat['time']!,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat['message']!,
                              style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotAIContent() {
    final Color cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final Color chatBubbleColor = _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Chatbot Assistant',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tanyakan seputar panduan pameran, tips promosi UMKM, atau bantuan teknis booth.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: chatBubbleColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Halo! Ada yang bisa saya bantu terkait persiapan booth atau informasi event Voca-techXpo 2026?',
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: textColor, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan ke AI Assistant...',
                            hintStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: chatBubbleColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.send_rounded, color: Color(0xFF8B5CF6)),
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

  Widget _buildHomeContent(bool isDesktop) {
    final Color textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final Color cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: isDesktop ? 340 : 200,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _bannerController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentBannerIndex = index;
                              });
                            },
                            itemCount: _bannerImages.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: const Color(0xFF060409),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        _bannerImages[index],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFF8B5CF6),
                                            child: Center(
                                              child: Text(
                                                'Banner tidak ditemukan:\n${_bannerImages[index]}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.white, fontSize: 11),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.85),
                                              Colors.black.withOpacity(0.55),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(28.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'EXPO & MARKETPLACE 2026',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B5CF6),
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'Pameran Wirausaha &\nInovasi UKM Mahasiswa',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  if (_currentBannerIndex < _bannerImages.length - 1) {
                                    _bannerController.nextPage(
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                    );
                                  } else {
                                    _bannerController.animateToPage(
                                      0,
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_bannerImages.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentBannerIndex == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentBannerIndex == index
                                ? const Color(0xFF8B5CF6)
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jelajahi Booth & Inovasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedTabFilter = 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booth Wirausaha Unggulan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabFilter == 0 ? const Color(0xFF8B5CF6) : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_selectedTabFilter == 0)
                                Container(width: 40, height: 3, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(2)))
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        GestureDetector(
                          onTap: () => setState(() => _selectedTabFilter = 1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UKM & Startup Mahasiswa',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabFilter == 1 ? const Color(0xFF8B5CF6) : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_selectedTabFilter == 1)
                                Container(width: 40, height: 3, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(2)))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: isDesktop ? 500 : 540, 
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _posterController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPosterIndex = index;
                        });
                      },
                      itemCount: _posterImages.length,
                      itemBuilder: (context, index) {
                        bool isCurrentActive = _currentPosterIndex == index;
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: isCurrentActive ? 0 : 16,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              _posterImages[index],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF8B5CF6),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Poster tidak ditemukan:\n${_posterImages[index]}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: isDesktop ? 24 : 4,
                      child: GestureDetector(
                        onTap: () {
                          if (_currentPosterIndex > 0) {
                            _posterController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _posterController.animateToPage(
                              _posterImages.length - 1,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: isDesktop ? 24 : 4,
                      child: GestureDetector(
                        onTap: () {
                          if (_currentPosterIndex < _posterImages.length - 1) {
                            _posterController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _posterController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Promo Spesial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 360,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _boothList.length,
                  itemBuilder: (context, index) {
                    final booth = _boothList[index];
                    final String badgeText = booth['badge'] ?? '';

                    return Container(
                      width: 320,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    height: 170, 
                                    color: Colors.transparent,
                                    child: booth['image'] != null
                                        ? Image.asset(
                                            booth['image'],
                                            fit: BoxFit.cover, 
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(Icons.storefront, color: Color(0xFF8B5CF6), size: 40),
                                              );
                                            },
                                          )
                                        : const Center(
                                            child: Icon(Icons.storefront, color: Color(0xFF8B5CF6), size: 40),
                                          ),
                                  ),
                                ),
                                if (badgeText.isNotEmpty)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              booth['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booth['owner'],
                              style: const TextStyle(fontSize: 11, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booth['price'],
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const Spacer(),
                            Container(
                              width: double.infinity,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {},
                                  child: const Center(
                                    child: Text(
                                      'Kunjungi Booth',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                        child: Container(
                          width: 650,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(150),
                            color: Color(0xFF8B5CF6).withOpacity(_isDarkMode ? 0.22 : 0.12),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                        child: Container(
                          width: 350,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Color(0xFF8B5CF6).withOpacity(_isDarkMode ? 0.18 : 0.08),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Lihat Lainnya',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gabung Membership',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMembershipTabItem('Kumpulkan Koin', 0),
                                const SizedBox(width: 20),
                                _buildMembershipTabItem('Penawaran Tiket', 1),
                              ],
                            ),
                          ),
                          const SizedBox(height: 35),
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: const [
                                      Color(0xFF3B82F6),
                                      Color(0xFF8B5CF6),
                                      Color(0xFFFFFFFF),
                                      Color(0xFF8B5CF6),
                                      Color(0xFF3B82F6),
                                    ],
                                    stops: [
                                      0.0,
                                      _shimmerController.value - 0.3,
                                      _shimmerController.value,
                                      _shimmerController.value + 0.3,
                                      1.0,
                                    ].map((s) => s.clamp(0.0, 1.0)).toList(),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'VOCA-TECHXPO',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'EVENT WIRAUSAHA MAHASISWA MARKETPLACE BOOTH',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Dapatkan poin lebih banyak dengan melakukan transaksi di booth pameran.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: const Text('Daftar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF8B5CF6),
                                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Pelajari Lebih Lanjut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildMembershipTabItem(String title, int index) {
    bool isSelected = _membershipTab == index;
    return GestureDetector(
      onTap: () => setState(() => _membershipTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(width: 24, height: 2, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(2)))
        ],
      ),
    );
  }


  void _openBoothFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BoothOnboardingScreen(),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    final bool isDark = _isDarkMode;
    final Color bgColor =
        isDark ? const Color(0xFF081225) : const Color(0xFFF8FAFF);
    final Color cardColor =
        isDark ? const Color(0xFF17263B) : Colors.white;
    final Color textColor =
        isDark ? const Color(0xFFF8FAFF) : const Color(0xFF111B45);
    final Color subTextColor =
        isDark ? const Color(0xFFB8C5DB) : const Color(0xFF727D9B);
    final Color borderColor =
        isDark ? const Color(0xFF34445F) : const Color(0xFFE5E4FA);
    final Color purple = const Color(0xFF8B5CF6);

    return Container(
      color: bgColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Header profil dengan tombol kembali seperti referensi.
              Row(
                children: [
                  Material(
                    color: isDark
                        ? const Color(0xFF17243B)
                        : Colors.white.withOpacity(0.9),
                    shape: CircleBorder(
                      side: BorderSide(color: borderColor, width: 1.2),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _currentIndex = 0),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? Colors.white : const Color(0xFF4C1D95),
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: purple.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 43,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelompok 5 - Voca-techXpo',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'marketplace_booth@voca-techxpo.ac.id',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Dompet Saya
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildProfileSectionHeader(
                      'Dompet Saya',
                      textColor,
                      subTextColor,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildWalletCard(
                            'Dana',
                            'Rp 0',
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF3478FF),
                            cardColor,
                            textColor,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _buildWalletCard(
                            'Koin VocaTech',
                            '0 Koin',
                            Icons.monetization_on_rounded,
                            const Color(0xFFFFB52E),
                            cardColor,
                            textColor,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _buildWalletCard(
                            'Voucher Saya',
                            '0 Voucher',
                            Icons.confirmation_num_rounded,
                            const Color(0xFFEC64C8),
                            cardColor,
                            textColor,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Keuangan / Vpaylater dengan gradien ungu.
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildProfileSectionHeader(
                      'Keuangan',
                      textColor,
                      subTextColor,
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {},
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF7C35E8),
                                      Color(0xFF5528B8),
                                      Color(0xFF34269A),
                                    ]
                                  : const [
                                      Color(0xFFF5EDFF),
                                      Color(0xFFE8D9FF),
                                      Color(0xFFDCCBFF),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isDark
                                  ? Color(0xFF9A79FF).withOpacity(0.8)
                                  : const Color(0xFFDCCBFF),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFFB89AFF))
                                  .withOpacity(isDark ? 0.25 : 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 15,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFF5E9FF),
                                            Color(0xFFBCA4FF),
                                            Color(0xFF8B5CF6),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.65),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 31,
                                        color: Color(0xFF5723B8),
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Vpaylater',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 17,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF682BC7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Cicilan Pasti 0% + Diskon Khusus untuk Organizer',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.35,
                                              color: isDark
                                                  ? Colors.white.withOpacity(0.88)
                                                  : const Color(0xFF8172A8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFFD8CCFF),
                                      size: 16,
                                    ),
                                  ],
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
              const SizedBox(height: 12),

              // Aktivitas Saya
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildProfileSectionHeader(
                      'Aktivitas Saya',
                      textColor,
                      subTextColor,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.8,
                      children: [
                        _buildActivityCard(
                          'Buka Booth Anda',
                          'Mulai berjualan dan perkenalkan event Anda',
                          Icons.storefront_rounded,
                          const Color(0xFFC084FC),
                          cardColor,
                          textColor,
                          isDark: isDark,
                          onTap: _openBoothFlow,
                        ),
                        _buildActivityCard(
                          'Favorit Saya',
                          '',
                          Icons.favorite_rounded,
                          const Color(0xFFFF4FA3),
                          cardColor,
                          textColor,
                          isDark: isDark,
                        ),
                        _buildActivityCard(
                          'VocaTechVIP',
                          '',
                          Icons.workspace_premium_rounded,
                          const Color(0xFFFFC857),
                          cardColor,
                          textColor,
                          isDark: isDark,
                        ),
                        _buildActivityCard(
                          'Terakhir Dilihat',
                          '',
                          Icons.history_rounded,
                          const Color(0xFF9B7CFF),
                          cardColor,
                          textColor,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Pilihan tema
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _buildPreferenceIcon(
                      Icons.palette_rounded,
                      const Color(0xFF9B5CFF),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your mode',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Change the colors that appear in apps',
                            style: TextStyle(
                              fontSize: 10,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A2B43)
                            : const Color(0xFFFAF9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool>(
                          value: _isDarkMode,
                          isDense: true,
                          dropdownColor: cardColor,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: subTextColor,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: false,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.wb_sunny_rounded,
                                    size: 16,
                                    color: Color(0xFFFFB020),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Light', style: TextStyle(color: textColor)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.nightlight_round,
                                    size: 16,
                                    color: isDark
                                        ? const Color(0xFFE0D7FF)
                                        : const Color(0xFF5B6478),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Dark', style: TextStyle(color: textColor)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _isDarkMode = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Pilihan font
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _buildPreferenceIcon(
                      Icons.text_fields_rounded,
                      const Color(0xFFB084FF),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your available font',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Set the font style in the application',
                            style: TextStyle(
                              fontSize: 10,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A2B43)
                            : const Color(0xFFFAF9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFont,
                          isDense: true,
                          dropdownColor: cardColor,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: subTextColor,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ppins',
                              child: Text('Poppins'),
                            ),
                            DropdownMenuItem(
                              value: 'geist',
                              child: Text('Geist'),
                            ),
                            DropdownMenuItem(
                              value: 'outfit',
                              child: Text('Outfit'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedFont = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tombol keluar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF343F),
                    backgroundColor: isDark
                        ? Color(0xFF200F20).withOpacity(0.35)
                        : const Color(0xFFFFF7F7),
                    side: const BorderSide(
                      color: Color(0xFFFF343F),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 19),
                  label: const Text(
                    'Keluar (Log Out)',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePanel({
    required Color cardColor,
    required Color borderColor,
    required bool isDark,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(10),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: borderColor.withOpacity(isDark ? 0.95 : 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProfileSectionHeader(
    String title,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 11,
                  color: subTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: subTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildWalletCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color cardColor,
    Color textColor, {
    bool isDark = false,
  }) {
    final Color borderColor =
        isDark ? const Color(0xFF3A4A64) : const Color(0xFFE8E6FA);

    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Color(0xFF223149).withOpacity(0.88)
            : const Color(0xFFFCFBFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withOpacity(0.95),
                      iconColor,
                      Color.lerp(iconColor, Colors.black, 0.12)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    title == 'Koin VocaTech' ? 50 : 9,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.45),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: title == 'Koin VocaTech' ? 24 : 22,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: isDark ? const Color(0xFF9CAED0) : const Color(0xFF8791B0),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: title == 'Koin VocaTech'
                  ? const Color(0xFFFFBE45)
                  : const Color(0xFFB17BFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color cardColor,
    Color textColor, {
    bool isDark = false,
    VoidCallback? onTap,
  }) {
    final Color borderColor =
        isDark ? const Color(0xFF3A4A64) : const Color(0xFFE8E6FA);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Color(0xFF223149).withOpacity(0.88)
            : const Color(0xFFFCFBFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(Colors.white, iconColor, isDark ? 0.22 : 0.12)!,
                  Color.lerp(iconColor, isDark ? const Color(0xFF18263D) : Colors.white, 0.62)!,
                  iconColor.withOpacity(isDark ? 0.18 : 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: iconColor.withOpacity(isDark ? 0.28 : 0.20),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(isDark ? 0.14 : 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                const BoxShadow(
                  color: Colors.white12,
                  blurRadius: 1,
                  offset: Offset(-1, -1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: iconColor.withOpacity(0.18),
                  size: 31,
                ),
                Transform.translate(
                  offset: const Offset(-0.8, -1.1),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 27,
                    shadows: [
                      Shadow(
                        color: iconColor.withOpacity(0.42),
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                      const Shadow(
                        color: Colors.white30,
                        blurRadius: 1,
                        offset: Offset(-1, -1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: textColor,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.25,
                      color: isDark
                          ? const Color(0xFFB8C5DB)
                          : const Color(0xFF7A84A2),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.chevron_right_rounded,
            size: 17,
            color: isDark ? const Color(0xFF9CAED0) : const Color(0xFF8791B0),
          ),
        ],
      ),
    ),
    );
  }
}



// ==================== 5. DASHBOARD SCREEN ORGANIZER ====================
// Dashboard Organizer terpisah dari Dashboard Client.
// Role akun dibaca dari public.profiles pada proses login.
class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  static const Color _purple = Color(0xFF581C87);
  static const Color _accent = Color(0xFF8B5CF6);
  static const Color _pageBackground = Color(0xFFF8FAFC);

  int _selectedIndex = 0;
  bool _hasUnreadMessages = true;
  bool _profileLoading = true;
  String _username = 'Organizer';
  String _email = '';
  String _ukm = '';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _menuMessages = const [
    {
      'sender': 'Panitia VocaTechXpo',
      'message': 'Selamat datang di dashboard Organizer.',
      'time': 'Baru',
    },
    {
      'sender': 'Informasi Sistem',
      'message': 'Lengkapi informasi booth untuk memulai pengajuan.',
      'time': 'Panduan',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadOrganizerProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizerProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _profileLoading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('username, email, ukm, role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      if (data != null) {
        _username = (data['username'] ?? '').toString().trim().isEmpty
            ? 'Organizer'
            : data['username'].toString();
        _email = (data['email'] ?? user.email ?? '').toString();
        _ukm = (data['ukm'] ?? '').toString();
      } else {
        _username = (user.userMetadata?['username'] ?? 'Organizer').toString();
        _email = user.email ?? '';
        _ukm = (user.userMetadata?['ukm'] ?? '').toString();
      }
    } catch (_) {
      if (mounted) {
        _username = (user.userMetadata?['username'] ?? 'Organizer').toString();
        _email = user.email ?? '';
        _ukm = (user.userMetadata?['ukm'] ?? '').toString();
      }
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Tetap kembalikan pengguna ke halaman login jika sign-out gagal.
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _selectMenu(int index, {required bool isMobile}) {
    if (index == 95) {
      _logout();
      return;
    }
    setState(() {
      _selectedIndex = index;
      if (index == 5) _hasUnreadMessages = false;
    });
    if (isMobile) Navigator.of(context).pop();
  }

  void _openBoothOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BoothOnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      backgroundColor: _pageBackground,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: _purple,
              child: _buildOrganizerSidebar(isMobile: true),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.16)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (!isDesktop) ...[
                    Builder(
                      builder: (context) => IconButton(
                        tooltip: 'Buka menu',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu_rounded, color: _purple),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Icon(Icons.storefront_rounded, color: _accent, size: 23),
                  const SizedBox(width: 9),
                  const Text(
                    'VOCA-TECHXPO',
                    style: TextStyle(
                      color: Color(0xFF21163F),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDesktop)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E9FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ORGANIZER',
                        style: TextStyle(
                          color: _purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (isDesktop)
                    SizedBox(
                      width: 260,
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari menu...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          filled: true,
                          fillColor: const Color(0xFFF5F3FA),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Profil Organizer',
                    onPressed: () => setState(() => _selectedIndex = 7),
                    icon: const Icon(
                      Icons.account_circle_outlined,
                      color: _purple,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 260,
              child: _buildOrganizerSidebar(isMobile: false),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildSelectedOrganizerPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerSidebar({required bool isMobile}) {
    return Container(
      color: _purple,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Tutup menu',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            const Text(
              'Menu',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white60,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            _organizerMenuItem(0, Icons.home_rounded, 'Dashboard', isMobile),
            const SizedBox(height: 8),
            _organizerMenuItem(
              1,
              Icons.storefront_rounded,
              'Kelola Booth',
              isMobile,
              hasDropdown: true,
            ),
            const SizedBox(height: 8),
            _organizerMenuItem(2, Icons.inventory_2_rounded, 'Produk Saya', isMobile),
            const SizedBox(height: 8),
            _organizerMenuItem(3, Icons.bar_chart_rounded, 'Insight Penjualan', isMobile),
            const SizedBox(height: 8),
            _organizerMenuItem(4, Icons.star_border_rounded, 'Rating & Ulasan', isMobile),
            const SizedBox(height: 24),
            Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
            const SizedBox(height: 16),
            const Text(
              'Komunikasi & Layanan',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white60,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            _organizerMenuItem(
              5,
              Icons.forum_rounded,
              'Pesan',
              isMobile,
              showRedDot: _hasUnreadMessages,
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
            const SizedBox(height: 16),
            const Text(
              'Akun',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white60,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            _organizerMenuItem(7, Icons.person_outline_rounded, 'Profile', isMobile),
            const SizedBox(height: 8),
            _organizerMenuItem(95, Icons.logout_rounded, 'Keluar', isMobile),
          ],
        ),
      ),
    );
  }

  Widget _organizerMenuItem(
    int index,
    IconData icon,
    String label,
    bool isMobile, {
    bool hasDropdown = false,
    bool showRedDot = false,
  }) {
    final bool selected = _selectedIndex == index;
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectMenu(index, isMobile: isMobile),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? _purple : Colors.white70,
                  ),
                  if (showRedDot)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5A66),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? const Color(0xFF2E1065) : Colors.white,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (hasDropdown)
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: selected ? _purple : Colors.white70,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedOrganizerPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildOrganizerOverview();
      case 1:
        return _buildOrganizerEmptyPage(
          key: const ValueKey('booths'),
          title: 'Kelola Booth',
          subtitle: 'Buat pengajuan booth dan pantau informasi usaha Anda.',
          icon: Icons.storefront_rounded,
          actionLabel: 'Buka Booth Anda',
          onAction: _openBoothOnboarding,
        );
      case 2:
        return _buildOrganizerEmptyPage(
          key: const ValueKey('products'),
          title: 'Produk Saya',
          subtitle: 'Kelola katalog produk yang ditampilkan di booth Anda.',
          icon: Icons.inventory_2_rounded,
          actionLabel: 'Buka Pengajuan Booth',
          onAction: _openBoothOnboarding,
        );
      case 3:
        return _buildOrganizerEmptyPage(
          key: const ValueKey('sales'),
          title: 'Insight Penjualan',
          subtitle: 'Ringkasan pesanan, pendapatan, dan performa penjualan akan tampil di sini setelah data transaksi terhubung.',
          icon: Icons.bar_chart_rounded,
        );
      case 4:
        return _buildOrganizerEmptyPage(
          key: const ValueKey('ratings'),
          title: 'Rating & Ulasan',
          subtitle: 'Pantau penilaian dan masukan pengunjung terhadap booth Anda.',
          icon: Icons.star_border_rounded,
        );
      case 5:
        return ChatRoomsScreen(
          isOrganizer: true,
          onBack: () {
            setState(() => _selectedIndex = 0);
          },
        );
      case 6:
        return ChatRoomsScreen(
          isOrganizer: true,
          onBack: () {
            setState(() => _selectedIndex = 0);
          },
        );
      case 7:
        return _buildOrganizerProfile();
      default:
        return _buildOrganizerOverview();
    }
  }

  Widget _buildOrganizerOverview() {
    return ListView(
      key: const ValueKey('organizer-dashboard'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Dashboard Organizer',
          style: const TextStyle(
            color: Color(0xFF21163F),
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _profileLoading ? 'Memuat profil...' : 'Halo, $_username! 👋',
          style: const TextStyle(
            color: Color(0xFF6B6484),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kelola booth, produk, dan aktivitas usaha Anda di VocaTechXpo.',
          style: TextStyle(color: Color(0xFF777493), height: 1.5),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF581C87), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _purple.withOpacity(0.18),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mulai kembangkan booth Anda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lengkapi informasi usaha, baca persyaratan, lalu ajukan booth untuk ditinjau penyelenggara.',
                style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _openBoothOnboarding,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _purple,
                    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Buka Booth Anda', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ringkasan Aktivitas',
          style: TextStyle(color: Color(0xFF21163F), fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final int columns = constraints.maxWidth > 850
                ? 4
                : constraints.maxWidth > 500
                    ? 2
                    : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 1 ? 3.0 : 1.65,
              children: const [
                _OrganizerMetricCard(
                  title: 'Status Booth',
                  value: '—',
                  caption: 'Belum dimuat',
                  icon: Icons.storefront_rounded,
                  color: Color(0xFF8B5CF6),
                ),
                _OrganizerMetricCard(
                  title: 'Produk',
                  value: '—',
                  caption: 'Data belum terhubung',
                  icon: Icons.inventory_2_rounded,
                  color: Color(0xFF3478FF),
                ),
                _OrganizerMetricCard(
                  title: 'Pesanan',
                  value: '—',
                  caption: 'Data belum terhubung',
                  icon: Icons.receipt_long_rounded,
                  color: Color(0xFFF59E0B),
                ),
                _OrganizerMetricCard(
                  title: 'Penjualan',
                  value: '—',
                  caption: 'Data belum terhubung',
                  icon: Icons.trending_up_rounded,
                  color: Color(0xFF10B981),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Akses Cepat',
          style: TextStyle(color: Color(0xFF21163F), fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _quickAction(
              icon: Icons.storefront_rounded,
              label: 'Kelola Booth',
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _quickAction(
              icon: Icons.inventory_2_rounded,
              label: 'Produk Saya',
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            _quickAction(
              icon: Icons.bar_chart_rounded,
              label: 'Insight Penjualan',
              onTap: () => setState(() => _selectedIndex = 3),
            ),
            _quickAction(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              onTap: () => setState(() => _selectedIndex = 5),
            ),
          ],
        ),
        if (_ukm.isNotEmpty) ...[
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAE4F8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, color: _accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kategori Organizer', style: TextStyle(fontSize: 11, color: Color(0xFF777493))),
                      const SizedBox(height: 3),
                      Text(_ukm, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF21163F))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 190,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAE4F8)),
            ),
            child: Row(
              children: [
                Icon(icon, color: _accent, size: 21),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF2D2448)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizerEmptyPage({
    required Key key,
    required String title,
    required String subtitle,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return ListView(
      key: key,
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF21163F)),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Color(0xFF777493), height: 1.5)),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEAE4F8)),
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(color: Color(0xFFF0E9FF), shape: BoxShape.circle),
                child: Icon(icon, color: _accent, size: 38),
              ),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF21163F))),
              const SizedBox(height: 8),
              Text(
                onAction == null
                    ? 'Belum ada data untuk ditampilkan.'
                    : 'Mulai dari pengajuan booth. Data akan tampil setelah proses dan database fitur ini terhubung.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF777493), height: 1.5),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerMessages() {
    return ListView(
      key: const ValueKey('organizer-chat'),
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Chat', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF21163F))),
        const SizedBox(height: 8),
        const Text(
          'Pusat komunikasi untuk informasi dan calon pembeli booth Anda.',
          style: TextStyle(color: Color(0xFF777493), height: 1.5),
        ),
        const SizedBox(height: 20),
        ..._menuMessages.map((message) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFEAE4F8)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFF0E9FF),
                    child: Icon(Icons.person_outline_rounded, color: _purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message['sender']!, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF21163F))),
                        const SizedBox(height: 5),
                        Text(message['message']!, style: const TextStyle(color: Color(0xFF777493), height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(message['time']!, style: const TextStyle(fontSize: 10, color: Color(0xFF8B5CF6))),
                ],
              ),
            )),
        const SizedBox(height: 4),
        const Text(
          'Daftar percakapan contoh ini belum terhubung dengan tabel chat Supabase.',
          style: TextStyle(fontSize: 11, color: Color(0xFF8A849F)),
        ),
      ],
    );
  }

  Widget _buildOrganizerProfile() {
    return ListView(
      key: const ValueKey('organizer-profile'),
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Profile Organizer', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF21163F))),
        const SizedBox(height: 8),
        const Text('Informasi akun Organizer yang sedang masuk.', style: TextStyle(color: Color(0xFF777493))),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAE4F8)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFF0E9FF),
                child: Icon(Icons.person_rounded, color: _accent, size: 38),
              ),
              const SizedBox(height: 12),
              Text(_username, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF21163F))),
              const SizedBox(height: 4),
              Text(_email, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF777493))),
              const SizedBox(height: 20),
              _profileRow('Role', 'Organizer', Icons.admin_panel_settings_outlined),
              const Divider(height: 24),
              _profileRow('UKM / Kategori', _ukm.isEmpty ? 'Belum diisi' : _ukm, Icons.groups_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _accent, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF777493), fontSize: 11)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Color(0xFF21163F), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrganizerMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  const _OrganizerMetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(color: Color(0xFF6F6889), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 19, color: color),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(color: Color(0xFF21163F), fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(caption, style: const TextStyle(color: Color(0xFF8A849F), fontSize: 10)),
        ],
      ),
    );
  }
}


// ==================== ALUR BUKA BOOTH ====================
class BoothOnboardingScreen extends StatefulWidget {
  const BoothOnboardingScreen({super.key});

  @override
  State<BoothOnboardingScreen> createState() => _BoothOnboardingScreenState();
}

class _BoothOnboardingScreenState extends State<BoothOnboardingScreen> {
  static const Color _purple = Color(0xFF8050F6);
  static const List<String> _businessTypes = ['Makanan', 'IoT/Pameran', 'Bazar'];
  static const List<String> _organizerTypes = [
    'UKM IECLOP (Improving English Club of Polytechnic)',
    'UKM LDK-FORDIMA',
    'UKM POLICY (Polytechnic Linux Community)',
    'UKM Sanggar Seni',
    'UKM Edelweis',
    'UKM Taekwondo',
    'UKM Polyrobocom',
    'UKM Merpati Putih',
    'Wirausaha Mahasiswa Mandiri (UMKM)',
  ];

  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _agreed = false;
  final Set<int> _expandedTutorialSteps = {1};
  String? _businessType;
  String? _organizerType;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _continueFromTerms() {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centang persetujuan persyaratan untuk melanjutkan.'),
          backgroundColor: Colors.deepOrange,
        ),
      );
      return;
    }
    _goToStep(2);
  }

  void _submitBooth() {
    if (!_formKey.currentState!.validate()) return;
    if (_businessType == null || _organizerType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis usaha dan kategori pelaku usaha terlebih dahulu.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
        title: const Text('Informasi Booth Lengkap'),
        content: const Text(
          'Data booth sudah diperiksa pada formulir ini. Pengajuan belum dikirim ke database atau penyelenggara; sambungkan proses ini ke Supabase untuk menyimpan pengajuan secara permanen.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: _purple),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF21163F),
        elevation: 0,
        scrolledUnderElevation: 0,
        // Geser judul sedikit mendekati tombol panah.
        titleSpacing: 0,
        title: const Text(
          'Buka Booth Anda',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF21163F),
          ),
        ),
        // Geser tombol kembali sedikit ke kanan, tanpa membuat jarak judul terlalu jauh.
        leadingWidth: 78,
        leading: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E0F4), width: 1.1),
            ),
            alignment: Alignment.center,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () {
                if (_step > 0) {
                  _goToStep(_step - 1);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: List.generate(3, (index) {
                      final active = index <= _step;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                          height: 5,
                          decoration: BoxDecoration(
                            color: active ? _purple : const Color(0xFFE4DDF8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildTutorialStep(size),
                      _buildTermsStep(),
                      _buildBoothFormStep(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tutorialIllustration({
    required IconData icon,
    required String label,
    required int variant,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E0FF)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 20,
                  top: 12,
                  child: Icon(Icons.auto_awesome, size: 22, color: Color(0xFFC3AEFF)),
                ),
                Positioned(
                  right: 22,
                  top: 25,
                  child: Icon(Icons.auto_awesome, size: 16, color: Color(0xFFB59AFF)),
                ),
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE9DEFF), Color(0xFFD2BEFF)],
                    ),
                  ),
                  child: Icon(icon, size: 54, color: _purple),
                ),
                if (variant == 0)
                  Positioned(
                    bottom: 1,
                    right: 48,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 3))]),
                      child: const Icon(Icons.edit_note_rounded, color: _purple, size: 25),
                    ),
                  ),
                if (variant == 1)
                  Positioned(
                    bottom: 2,
                    right: 43,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 3))]),
                      child: const Icon(Icons.add_photo_alternate_rounded, color: _purple, size: 24),
                    ),
                  ),
                if (variant == 2)
                  Positioned(
                    bottom: 1,
                    right: 43,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 3))]),
                      child: const Icon(Icons.campaign_rounded, color: _purple, size: 24),
                    ),
                  ),
                if (variant == 3)
                  Positioned(
                    bottom: 1,
                    right: 43,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 3))]),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF36A875), size: 24),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF55427D))),
        ],
      ),
    );
  }

  Widget _tutorialStepCard({
    required int number,
    required IconData icon,
    required String title,
    required String description,
    required String imageLabel,
    required int variant,
    required List<String> tips,
  }) {
    final isExpanded = _expandedTutorialSteps.contains(number);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isExpanded ? const Color(0xFFD7C7FF) : const Color(0xFFE9E3F7),
          width: isExpanded ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F4BC3).withOpacity(isExpanded ? 0.08 : 0.025),
            blurRadius: isExpanded ? 18 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedTutorialSteps.remove(number);
                    } else {
                      _expandedTutorialSteps.add(number);
                    }
                  });
                },
                splashColor: const Color(0xFF8050F6).withOpacity(0.08),
                highlightColor: const Color(0xFF8050F6).withOpacity(0.035),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0E9FF),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$number',
                          style: const TextStyle(color: _purple, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF20183F))),
                            const SizedBox(height: 5),
                            Text(description, style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF777493)), maxLines: isExpanded ? null : 2, overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isExpanded ? const Color(0xFFF0E9FF) : const Color(0xFFF8F6FC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: _purple, size: 21),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tutorialIllustration(icon: icon, label: imageLabel, variant: variant),
                          const SizedBox(height: 13),
                          ...tips.map((tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 17, color: _purple),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(tip, style: const TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF5E5878)))),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showIosStylePicker({
    required String title,
    required List<String> options,
    required String? selectedValue,
  }) {
    return showCupertinoModalPopup<String>(
      context: context,
      barrierDismissible: true,
      builder: (popupContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.72),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8FD),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 28, offset: Offset(0, -4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 9),
                Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD8D4E2), borderRadius: BorderRadius.circular(20))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 12, 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF21163F)))),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        onPressed: () => Navigator.of(popupContext).pop(),
                        child: const Text('Tutup', style: TextStyle(color: _purple, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEAE6F2)),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 5),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final selected = option == selectedValue;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () => Navigator.of(popupContext).pop(option),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFEDE5FF) : Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: selected ? const Color(0xFFCBB8FF) : const Color(0xFFEDE9F5)),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(option, style: TextStyle(fontSize: 13.5, height: 1.3, color: const Color(0xFF292142), fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
                                if (selected) const Icon(CupertinoIcons.check_mark_circled_solid, color: _purple, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTutorialStep(Size size) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Panduan Membuka Booth',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 25, height: 1.2, fontWeight: FontWeight.w900, color: Color(0xFF17133A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ikuti panduan berikut untuk mulai berjualan, memamerkan karya, atau memperkenalkan kegiatan UKM di VocaTechXpo. Baca setiap tahap sebelum melanjutkan.',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF777493)),
          ),
          const SizedBox(height: 20),
          _tutorialStepCard(
            number: 1,
            icon: Icons.storefront_rounded,
            title: 'Buka menu Buka Booth Anda',
            description: 'Masuk ke halaman Profil, lalu pilih menu “Buka Booth Anda” pada bagian Aktivitas Saya. Kamu akan diarahkan ke panduan pendaftaran booth.',
            imageLabel: 'Mulai dari menu profil',
            variant: 0,
            tips: [
              'Pastikan kamu masuk menggunakan akun VocaTechXpo milikmu.',
              'Baca panduan ini sampai selesai agar memahami proses pendaftaran booth.',
            ],
          ),
          _tutorialStepCard(
            number: 2,
            icon: Icons.assignment_rounded,
            title: 'Pahami alur dan persyaratan',
            description: 'Sebelum mengisi data, pahami ketentuan yang berlaku untuk semua pemilik booth. Informasi yang diberikan harus benar dan konten harus sesuai aturan.',
            imageLabel: 'Baca ketentuan sebelum mendaftar',
            variant: 1,
            tips: [
              'Baca seluruh persyaratan buka booth dengan teliti.',
              'Centang “Saya menyetujui semua persyaratan yang telah ditentukan” jika kamu setuju.',
              'Tekan tombol “Mulai Buka Booth Anda” untuk masuk ke formulir.',
            ],
          ),
          _tutorialStepCard(
            number: 3,
            icon: Icons.edit_document,
            title: 'Lengkapi informasi booth',
            description: 'Isi formulir dengan identitas usaha, event, atau kegiatan yang ingin kamu tampilkan. Pilih jenis usaha dan kategori yang paling sesuai.',
            imageLabel: 'Isi data booth dengan benar',
            variant: 0,
            tips: [
              'Nama Event / Usaha: tulis nama yang mudah dikenali pengunjung.',
              'Jenis Usaha: pilih Makanan, IoT/Pameran, atau Bazar.',
              'Kategori Pelaku Usaha: pilih UKM yang sesuai atau Wirausaha Mahasiswa Mandiri (UMKM).',
              'Nomor Admin: masukkan nomor WhatsApp aktif yang dapat dihubungi pengunjung.',
            ],
          ),
          _tutorialStepCard(
            number: 4,
            icon: Icons.add_photo_alternate_rounded,
            title: 'Siapkan produk atau informasi event',
            description: 'Setelah booth diajukan dan tersedia, lengkapi tampilan booth dengan informasi yang membantu pengunjung memahami apa yang kamu tawarkan.',
            imageLabel: 'Tampilkan produk dan kegiatan',
            variant: 1,
            tips: [
              'Gunakan foto produk atau kegiatan yang jelas dan relevan.',
              'Tulis nama, deskripsi, harga, atau jadwal kegiatan jika diperlukan.',
              'Pastikan informasi yang ditampilkan akurat dan tidak menyesatkan.',
            ],
          ),
          _tutorialStepCard(
            number: 5,
            icon: Icons.campaign_rounded,
            title: 'Perkenalkan booth kepada pengunjung',
            description: 'Buat booth mudah dikenali dan informatif. Kamu dapat membagikan informasi booth melalui kanal promosi yang tersedia dan mengarahkan pengunjung untuk melihat produk atau kegiatanmu.',
            imageLabel: 'Kenalkan booth di VocaTechXpo',
            variant: 2,
            tips: [
              'Gunakan nama dan deskripsi yang jelas.',
              'Tanggapi pertanyaan pengunjung dengan sopan.',
              'Jaga komunikasi dan informasi kontak tetap aktif.',
            ],
          ),
          _tutorialStepCard(
            number: 6,
            icon: Icons.verified_user_rounded,
            title: 'Tunggu pemeriksaan pengajuan',
            description: 'Informasi booth dapat ditinjau oleh penyelenggara sebelum ditampilkan. Pastikan data yang kamu berikan lengkap agar proses pemeriksaan berjalan lebih lancar.',
            imageLabel: 'Pemeriksaan sebelum booth ditampilkan',
            variant: 3,
            tips: [
              'Penyelenggara dapat meminta perbaikan jika ada informasi yang kurang sesuai.',
              'Booth dapat ditampilkan setelah proses persetujuan sesuai mekanisme aplikasi.',
            ],
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5DAFF)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: _purple, size: 23),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tips: gunakan informasi yang jelas, foto yang sesuai, dan nomor admin yang aktif agar pengunjung lebih mudah mengenali booth kamu.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF55427D)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _goToStep(1),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Lanjut ke Persyaratan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsStep() {
    final terms = [
      'Informasi yang diberikan harus benar, lengkap, dan sesuai dengan event atau usaha yang dibuka.',
      'Konten booth tidak boleh mengandung unsur SARA, kekerasan, penipuan, atau hal yang melanggar hukum.',
      'Penyelenggara berhak menolak atau menonaktifkan booth yang tidak sesuai dengan ketentuan.',
      'Pemilik booth bertanggung jawab atas produk, layanan, harga, dan aktivitas yang ditampilkan.',
      'Komunikasi dan transaksi dengan pengunjung menjadi tanggung jawab pemilik booth masing-masing.',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.fact_check_rounded, color: _purple, size: 64),
          const SizedBox(height: 12),
          const Text('Persyaratan Buka Booth', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF17133A))),
          const SizedBox(height: 8),
          const Text('Harap baca dan pahami ketentuan berikut sebelum melanjutkan.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF777493), height: 1.4)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFEAE4FF))),
            child: Column(
              children: terms.asMap().entries.map((entry) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: entry.key == terms.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFF0EDFA)))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 32, height: 32, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFFF0E9FF), shape: BoxShape.circle), child: Text('${entry.key + 1}', style: const TextStyle(color: _purple, fontWeight: FontWeight.w900))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value, style: const TextStyle(height: 1.45, color: Color(0xFF55516F), fontSize: 13))),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _agreed ? _purple : const Color(0xFFE4DDF8))),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: _purple,
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              title: const Text('Saya menyetujui semua persyaratan yang telah ditentukan.', style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600, color: Color(0xFF282142))),
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton('Mulai Buka Booth Anda', Icons.arrow_forward_rounded, _continueFromTerms),
        ],
      ),
    );
  }

  Widget _buildBoothFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.store_mall_directory_rounded, color: _purple, size: 58),
            const SizedBox(height: 10),
            const Text('Lengkapi Informasi Booth', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF17133A))),
            const SizedBox(height: 8),
            const Text('Isi informasi berikut untuk mulai mengajukan booth Anda.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF777493), height: 1.4)),
            const SizedBox(height: 22),
            _fieldLabel('Nama Event / Usaha'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Masukkan nama event atau usaha Anda', Icons.description_outlined),
              validator: (value) => value == null || value.trim().isEmpty ? 'Nama event/usaha wajib diisi.' : null,
            ),
            const SizedBox(height: 18),
            _fieldLabel('Jenis Usaha'),
            FormField<String>(
              initialValue: _businessType,
              validator: (value) => value == null ? 'Pilih jenis usaha.' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final value = await _showIosStylePicker(title: 'Pilih Jenis Usaha', options: _businessTypes, selectedValue: _businessType);
                      if (value != null) {
                        setState(() => _businessType = value);
                        field.didChange(value);
                      }
                    },
                    child: InputDecorator(
                      decoration: _inputDecoration('Pilih jenis usaha', Icons.calendar_month_outlined).copyWith(errorText: field.errorText, suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: _purple, size: 23)),
                      child: Text(_businessType ?? 'Pilih jenis usaha', style: TextStyle(fontSize: 13, color: _businessType == null ? const Color(0xFFAAA5C2) : const Color(0xFF292142))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Kategori Pelaku Usaha'),
            FormField<String>(
              initialValue: _organizerType,
              validator: (value) => value == null ? 'Pilih kategori pelaku usaha.' : null,
              builder: (field) => InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final value = await _showIosStylePicker(title: 'Kategori Pelaku Usaha', options: _organizerTypes, selectedValue: _organizerType);
                  if (value != null) {
                    setState(() => _organizerType = value);
                    field.didChange(value);
                  }
                },
                child: InputDecorator(
                  decoration: _inputDecoration('Pilih kategori pelaku usaha', Icons.grid_view_rounded).copyWith(errorText: field.errorText, suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: _purple, size: 23)),
                  child: Text(_organizerType ?? 'Pilih kategori pelaku usaha', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: _organizerType == null ? const Color(0xFFAAA5C2) : const Color(0xFF292142))),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Nomor Admin WhatsApp'),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Masukkan nomor WhatsApp admin', Icons.phone_outlined),
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return 'Nomor admin wajib diisi.';
                if (phone.replaceAll(RegExp(r'[^0-9+]'), '').length < 9) return 'Masukkan nomor WhatsApp yang valid.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _primaryButton('Buka Booth', Icons.storefront_rounded, _submitBooth),
            const SizedBox(height: 10),
            const Text('Pastikan semua informasi benar sebelum melanjutkan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF88839F))),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF21183F))),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFAAA5C2), fontSize: 13),
    prefixIcon: Icon(icon, color: _purple, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4DDF8))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4DDF8))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _purple, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
  );

  Widget _primaryButton(String label, IconData icon, VoidCallback onPressed) => SizedBox(
    height: 54,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      style: FilledButton.styleFrom(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
      ),
    ),
  );
}

// ==================== SUPPORTING CLASSES ====================
class Star {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final int seed;

  Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.seed,
  });
}

class StarrySkyPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;

  StarrySkyPainter({required this.animationValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var star in stars) {
      // Pergerakan vertikal dengan kecepatan yang lebih lambat
      double currentY = (star.y + (animationValue * star.speed)) % 1.0;
      
      double opacity = (sin((animationValue * 2 * pi) + star.seed) + 1) / 2;
      opacity = opacity.clamp(0.2, 1.0);

      paint.color = Colors.white.withOpacity(opacity * 0.9);

      final dx = star.x * size.width;
      final dy = currentY * size.height;

      canvas.drawCircle(Offset(dx, dy), star.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarrySkyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ==================== PESAN TERPADU CLIENT & ORGANIZER ====================
// UI percakapan terpadu. Data contoh disimpan di memori aplikasi saat ini.
// Untuk sinkronisasi lintas perangkat dan AI sungguhan, hubungkan ke tabel
// Supabase conversations/messages serta Edge Function AI (lihat instruksi setelah kode).


// ==================== PESAN TERPADU CLIENT & ORGANIZER ====================

// 1. HALAMAN DAFTAR ROOM (CLIENT: PILIH UKM | ORGANIZER: INBOX PESAN MASUK)
class ChatRoomsScreen extends StatefulWidget {
  final bool isOrganizer;
  final VoidCallback? onBack;

  const ChatRoomsScreen({
    super.key,
    required this.isOrganizer,
    this.onBack,
  });

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  static const Color _purple = Color(0xFF581C87);
  static const Color _accent = Color(0xFF8B5CF6);

  static const List<String> _ukmList = [
    'UKM Edelweis',
    'UKM Taekwondo',
    'UKM Polyrobocom',
    'UKM Merpati Putih',
    'BEM',
    'HIMATIK',
    'HIMABIS',
    'HIMA ELEKTRO',
    'HIMA MESIN',
    'HIMA SIPIL',
    'Wirausaha Mahasiswa Mandiri (UMKM)',
    'UKM IECLOP (Improving English Club of Polytechnic)',
    'UKM LDK-FORDIMA',
    'UKM POLICY (Polytechnic Linux Community)',
    'UKM Sanggar Seni',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showSelectUkmDialog() async {
    String? selectedUkm;
    bool isOpening = false;
    String? errorMessage;

    final roomResult = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440, maxHeight: 540),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: _purple, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Pilih UKM...',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF21163F),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isOpening ? null : () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF777493), size: 20),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0ECF7)),
                    if (errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                        ),
                      ),
                    Flexible(
                      child: isOpening
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: _purple),
                                  SizedBox(height: 14),
                                  Text(
                                    'Membuka ruang obrolan UKM...',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF777493)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _ukmList.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                                color: Color(0xFFF8FAFC),
                              ),
                              itemBuilder: (context, index) {
                                final ukmName = _ukmList[index];
                                final isSelected = selectedUkm == ukmName;

                                return InkWell(
                                  onTap: () async {
                                    setModalState(() {
                                      selectedUkm = ukmName;
                                      isOpening = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      final user = Supabase.instance.client.auth.currentUser;
                                      final meta = user?.userMetadata ?? {};
                                      final clientName = (meta['username'] ??
                                              meta['full_name'] ??
                                              user?.email?.split('@').first ??
                                              'Mahasiswa')
                                          .toString();

                                      Map<String, dynamic>? existingRoom;
                                      if (user != null) {
                                        existingRoom = await Supabase.instance.client
                                            .from('conversations')
                                            .select()
                                            .eq('client_id', user.id)
                                            .eq('topic', ukmName)
                                            .maybeSingle();
                                      }

                                      if (existingRoom != null) {
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext, existingRoom);
                                        }
                                        return;
                                      }

                                      final inserted = await Supabase.instance.client
                                          .from('conversations')
                                          .insert({
                                            'user_id': user?.id,
                                            'client_id': user?.id,
                                            'client_name': clientName,
                                            'topic': ukmName,
                                            'last_message': 'Memulai percakapan dengan $ukmName',
                                            'last_message_at': DateTime.now().toIso8601String(),
                                            'status': 'bot',
                                            'unread_count': 0,
                                          })
                                          .select()
                                          .single();

                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext, inserted);
                                      }
                                    } catch (e) {
                                      setModalState(() {
                                        isOpening = false;
                                        errorMessage = 'Gagal membuka room: $e';
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked_rounded
                                              : Icons.radio_button_unchecked_rounded,
                                          size: 20,
                                          color: isSelected ? _purple : const Color(0xFF9CA3AF),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            ukmName,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                              color: isSelected ? _purple : const Color(0xFF21163F),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (roomResult != null && mounted) {
      _openChatRoom(roomResult);
    }
  }

  void _openChatRoom(Map<String, dynamic> room) {
    if (widget.isOrganizer && (room['unread_count'] ?? 0) > 0) {
      Supabase.instance.client
          .from('conversations')
          .update({'unread_count': 0})
          .eq('id', room['id']);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: SharedMessagesScreen(
              isOrganizer: widget.isOrganizer,
              conversationId: room['id'].toString(),
              roomTitle: widget.isOrganizer
                  ? '${room['client_name'] ?? 'Pengunjung'} • ${room['topic'] ?? 'UKM'}'
                  : (room['topic'] ?? 'Voca-TechXpo Support').toString(),
            ),
          ),
        ),
      ),
    );
  }

  String _formatRoomTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 760;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.all(isDesktop ? 24 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE6DDF8)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: _purple, size: 23),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.forum_rounded, color: _purple, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isOrganizer ? 'Inbox Pesan Masuk' : 'Ruang Percakapan',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF21163F)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.isOrganizer
                          ? 'Balas pesan masuk dari pengunjung dan cek bukti transfer per UKM.'
                          : 'Pilih riwayat chat UKM atau klik "Pilih UKM" untuk memulai obrolan.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF777493)),
                    ),
                  ],
                ),
              ),
              if (!widget.isOrganizer)
                FilledButton.icon(
                  onPressed: _showSelectUkmDialog,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Pilih UKM', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEAE4F8)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: widget.isOrganizer
                        ? 'Cari nama pengunjung atau nama UKM...'
                        : 'Cari nama UKM atau isi pesan...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF777493), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['Semua', 'Organizer', 'AI'].map((filter) {
                    final active = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          filter == 'Organizer' ? 'Butuh Organizer' : (filter == 'AI' ? 'AI Assistant' : 'Semua Room'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : _purple,
                          ),
                        ),
                        selected: active,
                        selectedColor: _purple,
                        backgroundColor: const Color(0xFFF0E9FF),
                        side: BorderSide.none,
                        onSelected: (_) => setState(() => _selectedFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('conversations')
                  .stream(primaryKey: ['id'])
                  .order('last_message_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var rooms = snapshot.data ?? [];

                if (!widget.isOrganizer && currentUserId != null) {
                  rooms = rooms.where((r) => r['client_id'] == currentUserId).toList();
                }

                if (_selectedFilter == 'Organizer') {
                  rooms = rooms.where((r) => r['status'] == 'organizer').toList();
                } else if (_selectedFilter == 'AI') {
                  rooms = rooms.where((r) => r['status'] != 'organizer').toList();
                }

                if (_searchQuery.isNotEmpty) {
                  rooms = rooms.where((r) {
                    final name = (r['client_name'] ?? '').toString().toLowerCase();
                    final topic = (r['topic'] ?? '').toString().toLowerCase();
                    final lastMsg = (r['last_message'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || topic.contains(_searchQuery) || lastMsg.contains(_searchQuery);
                  }).toList();
                }

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(color: Color(0xFFF0E9FF), shape: BoxShape.circle),
                          child: const Icon(Icons.mark_chat_unread_outlined, color: _purple, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.isOrganizer
                              ? 'Belum ada pesan masuk dari pengunjung.'
                              : 'Belum ada percakapan dengan UKM.',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF21163F), fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isOrganizer
                              ? 'Pesan dari pengunjung akan muncul otomatis di sini untuk Anda balas.'
                              : 'Klik tombol "Pilih UKM" di pojok kanan atas untuk memulai chat.',
                          style: const TextStyle(color: Color(0xFF777493), fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final clientName = (room['client_name'] ?? 'Pengunjung').toString();
                    final ukmTopic = (room['topic'] ?? 'UKM').toString();
                    final lastMsg = (room['last_message'] ?? '').toString();
                    final isNeedOrg = room['status'] == 'organizer';
                    final unread = (room['unread_count'] ?? 0) as int;

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openChatRoom(room),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (widget.isOrganizer && unread > 0) ? _accent : const Color(0xFFEAE4F8),
                              width: (widget.isOrganizer && unread > 0) ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFF0E9FF),
                                child: Text(
                                  widget.isOrganizer
                                      ? (clientName.isNotEmpty ? clientName[0].toUpperCase() : 'U')
                                      : (ukmTopic.isNotEmpty ? ukmTopic[0].toUpperCase() : 'U'),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: _purple, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.isOrganizer ? '$clientName • $ukmTopic' : ukmTopic,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: Color(0xFF21163F),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatRoomTime(room['last_message_at']?.toString()),
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF777493)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            lastMsg,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: (widget.isOrganizer && unread > 0)
                                                  ? const Color(0xFF21163F)
                                                  : const Color(0xFF777493),
                                              fontWeight: (widget.isOrganizer && unread > 0)
                                                  ? FontWeight.w700
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isNeedOrg ? const Color(0xFFFEF3C7) : const Color(0xFFEDE9FE),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isNeedOrg ? 'Organizer' : 'AI',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isNeedOrg ? const Color(0xFFB45309) : _purple,
                                            ),
                                          ),
                                        ),
                                        if (widget.isOrganizer && unread > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                                            child: Text(
                                              '$unread',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 2. RUANG OBROLAN TERPADU PER ROOM UKM
class SharedMessagesScreen extends StatefulWidget {
  final bool isOrganizer;
  final VoidCallback? onBack;
  final String conversationId;
  final String roomTitle;

  const SharedMessagesScreen({
    super.key,
    required this.isOrganizer,
    this.onBack,
    this.conversationId = '00000000-0000-0000-0000-000000000001',
    this.roomTitle = 'Voca-TechXpo Support',
  });

  @override
  State<SharedMessagesScreen> createState() => _SharedMessagesScreenState();
}

class _SharedMessagesScreenState extends State<SharedMessagesScreen> {
  static const Color _purple = Color(0xFF581C87);
  static const Color _accent = Color(0xFF8B5CF6);

  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _organizerRequested = false;
  bool _satisfied = false;

  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checkConversationStatus();
    if (widget.isOrganizer) {
      _chatService.markUserMessagesAsRead(widget.conversationId);
    }
  }

  Future<void> _checkConversationStatus() async {
    try {
      final res = await Supabase.instance.client
          .from('conversations')
          .select('status')
          .eq('id', widget.conversationId)
          .maybeSingle();
      if (res != null &&
          (res['status'] == 'organizer' || res['status'] == 'human') &&
          mounted) {
        setState(() => _organizerRequested = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _selectedImageBytes = file.bytes;
            _selectedFileName = file.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedFileName = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedImageBytes == null) || _isUploading) return;

    final imageBytes = _selectedImageBytes;
    final rawFileName = _selectedFileName ?? 'image.png';

    _messageController.clear();
    _clearSelectedImage();

    String? uploadedImageUrl;

    if (imageBytes != null) {
      setState(() => _isUploading = true);
      try {
        final ext = rawFileName.contains('.') ? rawFileName.split('.').last.toLowerCase() : 'png';
        final mimeType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
        final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${widget.isOrganizer ? 'org' : 'user'}.$ext';
        final filePath = '${widget.conversationId}/$uniqueName';

        await Supabase.instance.client.storage.from('chat_images').uploadBinary(
              filePath,
              imageBytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );

        uploadedImageUrl = Supabase.instance.client.storage.from('chat_images').getPublicUrl(filePath);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengunggah gambar: $e'), backgroundColor: Colors.redAccent),
          );
        }
        setState(() => _isUploading = false);
        return;
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }

    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      message: text,
      senderType: widget.isOrganizer ? 'organizer' : 'user',
      imageUrl: uploadedImageUrl,
    );

    _scrollToBottom();
  }

  Future<void> _connectToOrganizer() async {
    setState(() {
      _organizerRequested = true;
    });
    await _chatService.switchToOrganizer(widget.conversationId);
    _scrollToBottom();
  }

  Future<void> _switchBackToAi() async {
    setState(() {
      _organizerRequested = false;
      _satisfied = false;
    });
    await Supabase.instance.client
        .from('conversations')
        .update({'status': 'ai'})
        .eq('id', widget.conversationId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 760;

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.all(isDesktop ? 24 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE6DDF8)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: _purple, size: 23),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.forum_rounded, color: _purple, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF21163F),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Satu ruang percakapan untuk bantuan AI dan komunikasi dengan organizer.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF777493)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEAE4F8)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFF0E9FF),
                          child: Icon(Icons.support_agent_rounded, color: _purple, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voca-TechXpo Support',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF21163F),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'AI Assistant • Organizer',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF777493)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Percakapan aktif',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0ECF7)),
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _chatService.streamMessages(widget.conversationId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: _purple));
                        }

                        final messages = snapshot.data ?? [];

                        // Jika Admin sedang membuka room dan ada pesan baru dari client, tandai sudah dilihat
                        if (widget.isOrganizer &&
                            messages.any((m) => m.senderType == 'user' && !m.isRead)) {
                          _chatService.markUserMessagesAsRead(widget.conversationId);
                        }

                        if (messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                widget.isOrganizer
                                    ? 'Belum ada pesan pada percakapan ini.'
                                    : 'Halo! Tanyakan apa saja seputar event, jadwal, atau booth kepada AI Assistant kami.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF777493)),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isUser = msg.senderType == 'user';
                            final isOrganizerMsg = msg.senderType == 'organizer';
                            final isMe = widget.isOrganizer ? isOrganizerMsg : isUser;

                            // Cek apakah pesan dikirim Client pada sesi Organizer (bukan sesi AI)
                            int lastTakeover = -1;
                            int lastReturnAi = -1;
                            for (int i = 0; i < index; i++) {
                              if (messages[i].senderType == 'bot') {
                                if (messages[i].message.contains('dialihkan ke Organizer')) {
                                  lastTakeover = i;
                                } else if (messages[i].message.contains('dikembalikan ke Voca-Bot AI')) {
                                  lastReturnAi = i;
                                }
                              }
                            }

                            final isOrganizerChatMsg = isUser &&
                                (lastTakeover > lastReturnAi ||
                                    (lastTakeover == -1 && lastReturnAi == -1 && _organizerRequested));

                            final hasOrganizerReplyAfter = messages
                                .sublist(index + 1)
                                .any((m) => m.senderType == 'organizer');

                            final isSeenOrReplied = msg.isRead || hasOrganizerReplyAfter;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.sizeOf(context).width * (isDesktop ? 0.55 : 0.78),
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? _purple
                                      : (isOrganizerMsg
                                          ? const Color(0xFFEDE9FE)
                                          : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                  border: isMe
                                      ? null
                                      : Border.all(
                                          color: isOrganizerMsg
                                              ? const Color(0xFFDDD6FE)
                                              : const Color(0xFFEAE4F8),
                                        ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe) ...[
                                      Text(
                                        isOrganizerMsg
                                            ? 'Organizer'
                                            : (isUser ? 'Pengunjung' : 'Voca-Bot AI'),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: _purple,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          msg.imageUrl!,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              '[Gambar tidak dapat dimuat]',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (msg.message.isNotEmpty) const SizedBox(height: 8),
                                    ],
                                    if (msg.message.isNotEmpty)
                                      Text(
                                        msg.message,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          height: 1.4,
                                          color: isMe ? Colors.white : const Color(0xFF21163F),
                                        ),
                                      ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatTime(msg.createdAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe ? Colors.white70 : const Color(0xFF777493),
                                          ),
                                        ),
                                        if (isOrganizerChatMsg) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            isSeenOrReplied
                                                ? Icons.done_all_rounded
                                                : Icons.check_rounded,
                                            size: 15,
                                            color: isSeenOrReplied
                                                ? const Color(0xFF38BDF8) // Centang 2 biru
                                                : (isMe ? Colors.white70 : const Color(0xFF777493)), // Centang 1
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (!widget.isOrganizer && !_organizerRequested && !_satisfied)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF8FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEAE4F8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Apakah jawaban ini membantu?',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF21163F),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _satisfied = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Terima kasih! Senang jawaban AI membantu.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                                label: const Text('Puas', style: TextStyle(fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _purple,
                                  side: const BorderSide(color: Color(0xFFD8B4FE)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _connectToOrganizer,
                                icon: const Icon(Icons.support_agent_rounded, size: 17),
                                label: const Text(
                                  'Chat Organizer',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (!widget.isOrganizer && _organizerRequested)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFFB45309)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Terhubung dengan Organizer',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _switchBackToAi,
                            icon: const Icon(Icons.smart_toy_outlined, size: 16),
                            label: const Text(
                              'Kembali ke AI',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: _purple,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedImageBytes != null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E9FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _selectedImageBytes!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedFileName ?? 'Gambar terpilih',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF21163F),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _clearSelectedImage,
                            icon: const Icon(Icons.close_rounded, size: 18, color: _purple),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1, color: Color(0xFFF0ECF7)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _isUploading ? null : _pickImage,
                          tooltip: 'Lampirkan gambar / bukti transfer',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF0E9FF),
                            foregroundColor: _purple,
                          ),
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 21),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: widget.isOrganizer
                                  ? 'Tulis balasan untuk pengunjung...'
                                  : 'Tulis pesan tentang event atau booth...',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: _accent,
                          child: IconButton(
                            onPressed: _isUploading ? null : _sendMessage,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Terhubung secara real-time dengan Supabase & Groq AI.',
            style: TextStyle(fontSize: 11, color: Color(0xFF777493)),
          ),
        ],
      ),
    );
  }
}