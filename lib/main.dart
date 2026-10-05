import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

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
  State createState() => _SplashScreenState();
}

class _SplashScreenState extends State with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _splashController;
  late AnimationController _shimmerController;
  late Animation _scaleAnimation;
  late Animation _fadeAnimation;
  late final List _stars;

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Controller untuk kilatan cahaya (shimmer) pada teks
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Controller untuk animasi kemunculan teks splash
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
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

    // Otomatis pindah ke LoginScreen dengan efek geser ke kiri setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 900),
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
          // Efek Bintang Angkasa
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
          // Teks VOCA TECHXPO dengan Efek Kilatan & Subtitle
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
                          // Teks Utama dengan Efek Shimmer (Kilatan Cahaya & Gradasi)
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
                          // Tulisan Event di Bawahnya
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
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  late AnimationController _starController;
  late AnimationController _shimmerController;
  late final List _stars;

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
    _starController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // Fungsi Validasi Login Sesuai Kredensial Pika
  void _handleLogin() {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (username == 'Kelompok5!' && 
        email == 'kelompok5_kereen@gmail.com' && 
        password == 'Kelompok5pintar') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Gagal! Username, Email, atau Kata Sandi salah.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060409),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. EFEK BINTANG-BINTANG GERAK
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

              // 2. KONTEN UTAMA DENGAN SCROLL AMAN
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // HEADER DENGAN LOGO DI KIRI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/images/voca_logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'VOCA-TECH',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF00E699),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'XPO SYSTEM',
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
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Header Teks "Welcome to Voca-techXpo" dengan Tema Angkasa & Kilat
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome to',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
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
                                    'Voca-techXpo',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // 3. KOTAK LOGIN (Frosted Glassmorphism)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF000000).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPortfolioInputField(
                                    label: 'Username',
                                    controller: _usernameController,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildPortfolioInputField(
                                    label: 'Alamat Email',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 14),
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
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.2),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.12),
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                style: const TextStyle(
                                                  fontFamily: 'Geist',
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
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
                                                size: 18,
                                                color: const Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {},
                                      child: const Text(
                                        'Lupa kata sandi?',
                                        style: TextStyle(
                                          fontFamily: 'Geist',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          color: Color(0xFF00E699),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. TOMBOL UTAMA DENGAN EFEK GLASS & KILATAN CAHAYA
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: AnimatedBuilder(
                              animation: _shimmerController,
                              builder: (context, child) {
                                return Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF3B82F6).withOpacity(0.7),
                                        const Color(0xFF8B5CF6).withOpacity(0.7),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: FractionallySizedBox(
                                          alignment: Alignment(
                                            (_shimmerController.value * 2) - 1, 
                                            0,
                                          ),
                                          widthFactor: 0.5,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.0),
                                                  Colors.white.withOpacity(0.25),
                                                  Colors.white.withOpacity(0.0),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: _handleLogin, // Diubah menggunakan onTap karena ini InkWell
                                          child: const Center(
                                            child: Text(
                                              'Masuk Sekarang',
                                              style: TextStyle(
                                                fontFamily: 'Geist',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer Daftar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Belum punya akun? ',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Daftar',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPortfolioInputField({
    required String label, 
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
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
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 46,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== 3. DASHBOARD SCREEN (WHITE BG & SPACE NAVBAR) ====================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Center(
      child: Text(
        'Selamat Datang di Home Dashboard!\n(Booth Pameran Wirausaha)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
      ),
    ),
    const Center(
      child: Text(
        'Halaman Profile Kelompok 5\n(Voca-techXpo Marketplace)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih bersih sesuai permintaan
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Voca-techXpo Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: SpaceBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// Bottom Navigation Bar Bertema Angkasa Khusus untuk Dashboard
class SpaceBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SpaceBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  State<SpaceBottomNavBar> createState() => _SpaceBottomNavBarState();
}

class _SpaceBottomNavBarState extends State<SpaceBottomNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  late final List _stars;

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

class Star {
  final double x;
  final double y;
  final double radius;
  final int seed;

  Star({required this.x, required this.y, required this.radius, required this.seed});
}

class StarrySkyPainter extends CustomPainter {
  final double animationValue;
  final List stars;

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