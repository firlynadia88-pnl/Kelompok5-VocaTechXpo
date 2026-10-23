import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Memuat file .env sebelum inisialisasi Supabase
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: 'https://bptllbnxpuglooqdmmyv.supabase.co',
    anonKey: 'sb_publishable_QctjbhHmweqyiB74MLfRuA_Z2Xr-sNR',
  );
  runApp(const MyApp());
}

// Daftar UKM Resmi Voca Tech
final List<String> globalUkmList = [
  'UKM IECLOP (Improving English Club of Polytechnic)',
  'UKM LDK-FORDIMA',
  'UKM POLICY (Polytechnic Linux Community)',
  'UKM Sanggar Seni',
  'UKM Edelweis',
  'UKM Taekwondo',
  'UKM Polyrobocom',
  'UKM Merpati Putih',
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
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
                                    fontFamily: 'Outfit',
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
                              fontFamily: 'Geist',
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
      duration: const Duration(seconds: 10),
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
    String username = _selectedRoleTab == 0 ? _usernameController.text.trim() : _adminUsernameController.text.trim();
    String email = _selectedRoleTab == 0 ? _emailController.text.trim() : _adminEmailController.text.trim();
    String password = _selectedRoleTab == 0 ? _passwordController.text.trim() : _adminPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Username, Email, dan Kata Sandi terlebih dahulu!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedRoleTab == 1 && _selectedOrganizerUkm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih UKM Organizer terlebih dahulu!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Bypass khusus untuk akun demo Kelompok 5 jika diperlukan
    if (username == 'Kelompok5!' && 
        email == 'kelompok5_kereen@gmail.com' && 
        password == '12345678') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Cek autentikasi lewat Supabase Auth (Email & Password)
      final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userData = response.user!.userMetadata;
        final registeredUsername = userData?['username'] ?? '';

        // Validasi kecocokan Username
        if (registeredUsername.isNotEmpty && registeredUsername != username) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Username yang Anda masukkan salah!'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      String errorMessage = 'Login Gagal!';
      if (e.message.toLowerCase().contains('invalid login credentials') || 
          e.message.toLowerCase().contains('password')) {
        errorMessage = 'Kata sandi salah!';
      } else if (e.message.toLowerCase().contains('email') || 
                 e.message.toLowerCase().contains('not found') ||
                 e.message.toLowerCase().contains('invalid email')) {
        errorMessage = 'Email tidak terdata!';
      } else {
        errorMessage = e.message;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
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
                                                fontFamily: 'Outfit',
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
                                                fontFamily: 'Geist',
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
                                              fontFamily: 'Outfit',
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
                                        fontFamily: 'Geist',
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
                              const Text(
                                'VOCA-TECHXPO',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'MARKETPLACE BOOTH SYSTEM',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF00E699),
                                  letterSpacing: 2,
                                ),
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
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Masukkan Kredensial Akun Anda Untuk Mengakses Portal.',
                style: TextStyle(
                  fontFamily: 'Geist',
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
                                  fontFamily: 'Geist',
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
                                  fontFamily: 'Geist',
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
                    fontFamily: 'Geist',
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
                            style: const TextStyle(color: Colors.black87, fontSize: 11, fontFamily: 'Geist'),
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
                label: 'Email Kampus / NIM',
                controller: _selectedRoleTab == 0 ? _emailController : _adminEmailController,
                hintText: 'Masukkan Email atau NIM...',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kata Sandi',
                    style: TextStyle(
                      fontFamily: 'Geist',
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
                              fontFamily: 'Geist',
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
                          fontFamily: 'Geist',
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
                        fontFamily: 'Geist',
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
                                        fontFamily: 'Geist',
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
                        fontFamily: 'Geist',
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
                                fontFamily: 'Geist',
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
                                fontFamily: 'Geist',
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
            fontFamily: 'Geist',
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
                    fontFamily: 'Geist',
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

// ==================== 3. REGISTER SCREEN (MAHASISWA & ORGANIZER) ====================
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
      duration: const Duration(seconds: 10),
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
          'role': widget.isOrganizer ? 'Organizer' : 'Mahasiswa',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran ${widget.isOrganizer ? 'Organizer' : 'Mahasiswa'} Berhasil!'),
            backgroundColor: const Color(0xFF00E699),
          ),
        );
        Navigator.pop(context);
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
                          fontFamily: 'Outfit',
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
                                      fontFamily: 'Outfit',
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
                                      fontFamily: 'Geist',
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
                                      const Text('Pilihan UKM', style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: Color(0xFF9CA3AF))),
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
                                              const Text('Jurusan', style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: Color(0xFF9CA3AF))),
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
                                              const Text('Angkatan', style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: Color(0xFF9CA3AF))),
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
                                        const Text('Program Studi', style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: Color(0xFF9CA3AF))),
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
                                          style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: Color(0xFF9CA3AF)),
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
                                                fontFamily: 'Geist',
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
        Text(label, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: Color(0xFF9CA3AF))),
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
        Text(label, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: Color(0xFF9CA3AF))),
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
                style: const TextStyle(color: Colors.black87, fontSize: 12, fontFamily: 'Geist'),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ==================== 4. DASHBOARD SCREEN (WIRAUSAHA & UKM) ====================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _selectedTabFilter = 0; 
  int _currentBannerIndex = 0;
  String _searchQuery = '';
  
  bool _hasUnreadMessages = true;

  final List<Map<String, dynamic>> _incomingMessages = [
    {'sender': 'Panitia Expo 2026', 'message': 'Halo tenant, mohon konfirmasi kehadiran pitching.', 'time': '10:15'},
    {'sender': 'Klien - Budi Santoso', 'message': 'Apakah stok Smart Hydroponic ready?', 'time': '09:30'},
    {'sender': 'Organizer Utama', 'message': 'Pemberitahuan: Setup booth dimulai pukul 08.00.', 'time': 'Kemarin'},
  ];

  final PageController _bannerController = PageController();
  late AnimationController _shimmerController;

  final List<String> _bannerImages = [
    'assets/images/Banner_1.PNG',
    'assets/images/Banner_2.PNG',
    'assets/images/Banner_3.PNG',
  ];

  final List<Map<String, dynamic>> _boothList = [
    {
      'title': 'Smart Hydroponic IoT',
      'category': 'Teknologi & IoT',
      'owner': 'UKM Robotik & TRPL',
      'price': 'Rp 450.000',
      'badge': 'Terlaris',
    },
    {
      'title': 'Kripik Pisang Madu Kece',
      'category': 'Kuliner & F&B',
      'owner': 'Kewirausahaan Mahasiswa Bisnis',
      'price': 'Rp 15.000',
      'badge': 'Favorit',
    },
    {
      'title': 'Aplikasi Kasir UMKM Pintar',
      'category': 'Startup Digital',
      'owner': 'UKM Komputer & Informatika',
      'price': 'Rp 100.000 /bln',
      'badge': 'Inovatif',
    },
    {
      'title': 'Fashion Eco-Print Kain Lokal',
      'category': 'Kriya & Fashion',
      'owner': 'UKM Kewirausahaan Vokasi',
      'price': 'Rp 175.000',
      'badge': 'Eco-Friendly',
    },
    {
      'title': 'Coffee Bagasse Cup',
      'category': 'Produk Kreatif',
      'owner': 'Tim Riset Teknik Kimia',
      'price': 'Rp 25.000',
      'badge': 'Green Product',
    },
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _shimmerController.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isDesktop ? null : _buildSidebarContent(context, isMobile: true),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                children: [
                  if (!isDesktop) ...[
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text(
                    'Voca-techXpo',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF1E293B),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: isDesktop ? 260 : 160,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontFamily: 'Geist'),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Cari produk / UKM...',
                              hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _currentIndex == 1 ? const Color(0xFF8B5CF6).withOpacity(0.2) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _currentIndex == 1 ? const Color(0xFF8B5CF6) : Colors.transparent,
                        ),
                      ),
                      child: Icon(Icons.person_outline, color: _currentIndex == 1 ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B), size: 18),
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
        return _buildChatOrganizerContent();
      case 3:
        return _buildChatbotAIContent();
      default:
        return _buildHomeContent(MediaQuery.sizeOf(context).width > 900);
    }
  }

  Widget _buildSidebarContent(BuildContext context, {required bool isMobile}) {
    return Container(
      color: const Color(0xFF2E1065), // Diperbarui ke warna #2E1065
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TenantXpo',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else ...[
            const Text(
              'TenantXpo',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
          const SizedBox(height: 30),
          const Text(
            'Menu',
            style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: Colors.white60, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          _buildDrawerItem(0, Icons.home_rounded, 'Dashboard', isMobile),
          const SizedBox(height: 8),
          _buildDrawerItem(99, Icons.storefront_rounded, 'Temukan Event', isMobile, hasDropdown: true),
          const SizedBox(height: 8),
          _buildDrawerItem(98, Icons.bar_chart_rounded, 'Insight Penjualan', isMobile),
          const SizedBox(height: 8),
          _buildDrawerItem(97, Icons.star_border_rounded, 'Rating', isMobile),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 16),
          const Text(
            'Komunikasi & Layanan',
            style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: Colors.white60, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          _buildDrawerItem(
            2, 
            Icons.chat_bubble_outline_rounded, 
            'Chat', 
            isMobile, 
            showRedDot: _hasUnreadMessages,
          ),
          const SizedBox(height: 8),
          _buildDrawerItem(3, Icons.smart_toy_outlined, 'Chatbot', isMobile),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 16),
          const Text(
            'Akun',
            style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: Colors.white60, letterSpacing: 1.1),
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
                  fontFamily: 'Geist',
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chat Organizer & Klien (Pesan Masuk)',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola komunikasi langsung dengan panitia event dan calon pembeli/klien booth Anda.',
            style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: Colors.grey),
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
                    color: Colors.white,
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
                                  style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  chat['time']!,
                                  style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat['message']!,
                              style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: Colors.black54),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Chatbot Assistant (Voca-Bot)',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tanyakan seputar panduan pameran, tips promosi UMKM, atau bantuan teknis booth.',
            style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Halo! Ada yang bisa saya bantu terkait persiapan booth atau informasi event Voca-techXpo 2026?',
                          style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan ke AI Assistant...',
                            hintStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(
                  height: isDesktop ? 320 : 200,
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
                                            style: const TextStyle(color: Colors.white, fontFamily: 'Geist', fontSize: 11),
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
                                              fontFamily: 'Geist',
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF8B5CF6),
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        AnimatedBuilder(
                                          animation: _shimmerController,
                                          builder: (context, child) {
                                            final double shimmerPosition = _shimmerController.value;
                                            return ShaderMask(
                                              shaderCallback: (bounds) {
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
                                                'Pameran Wirausaha &\nInovasi UKM Mahasiswa',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  height: 1.2,
                                                ),
                                              ),
                                            );
                                          },
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
                const Text(
                  'Jelajahi Booth & Inovasi',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                              fontFamily: 'Outfit',
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
                              fontFamily: 'Outfit',
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
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _boothList.length,
              itemBuilder: (context, index) {
                final booth = _boothList[index];
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: Icon(Icons.storefront, color: Color(0xFF8B5CF6), size: 48),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                booth['badge'],
                                style: const TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booth['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booth['owner'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Geist', fontSize: 10, color: Color(0xFF8B5CF6)),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Kunjungi Booth',
                                  style: TextStyle(fontFamily: 'Geist', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
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

  Widget _buildProfileContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: 400,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF8B5CF6),
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kelompok 5 - Voca-techXpo',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'marketplace_booth@voca-techxpo.ac.id',
                  style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.redAccent, width: 1),
                      ),
                    ),
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Keluar (Log Out)',
                      style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 5. BOTTOM NAVIGATION BAR ====================
class SpaceBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  const SpaceBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  State<SpaceBottomNavBar> createState() => _SpaceBottomNavBarState();
}

class _SpaceBottomNavBarState extends State<SpaceBottomNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  late final List<Star> _stars;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    final random = Random(99);
    _stars = List.generate(30, (i) => Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radius: random.nextDouble() * 1.5 + 0.4,
      seed: i,
    ));
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF060409),
        border: Border(
          top: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3), width: 1),
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 70),
                painter: StarrySkyPainter(
                  animationValue: _starController.value,
                  stars: _stars,
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.person_rounded, 'Profile'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = widget.currentIndex == index;
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00E699) : Colors.white60,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00E699),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== 6. UTILITIES & PAINTER ====================
class Star {
  final double x;
  final double y;
  final double radius;
  final int seed;
  Star({required this.x, required this.y, required this.radius, required this.seed});
}

class StarrySkyPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;
  StarrySkyPainter({required this.animationValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var star in stars) {
      double x = star.x * size.width;
      double y = star.y * size.height;
      
      y = (y + (animationValue * size.height * 0.2)) % size.height;
      
      double opacity = (sin((animationValue * 2 * pi) + star.seed) + 1) / 2;
      opacity = opacity * 0.4 + 0.1;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), star.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarrySkyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}