import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/screens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _page = 0;

  final List<_OnboardSlide> _slides = [
    _OnboardSlide(
      gradient: const LinearGradient(
        colors: [Color(0xFF1C3B07), Color(0xFF344F16)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.storefront_outlined,
      headline: 'Shop African Markets',
      subtitle:
          'Browse thousands of vendors across Nigeria, Ghana, Kenya and more — all in one place.',
    ),
    _OnboardSlide(
      gradient: const LinearGradient(
        colors: [Color(0xFF5C3A00), Color(0xFFA86200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.eco_outlined,
      headline: 'Fresh Produce & Goods',
      subtitle:
          'Buy directly from local farmers and producers. Authentic, fresh, and affordable.',
      accentColor: Color(0xFFF8B55B),
    ),
    _OnboardSlide(
      gradient: const LinearGradient(
        colors: [Color(0xFF7A2700), Color(0xFFD44000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.credit_card_outlined,
      headline: 'Pay the African Way',
      subtitle:
          'Seamlessly pay with Paystack or Flutterwave. Fast, secure, and designed for Africa.',
      accentColor: Color(0xFFFFD580),
    ),
    _OnboardSlide(
      gradient: const LinearGradient(
        colors: [Color(0xFF161000), Color(0xFF2D2200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.local_shipping_outlined,
      headline: 'Track Your Orders',
      subtitle:
          'Real-time order updates from checkout to your doorstep. Every step, every time.',
      accentColor: Color(0xFFF8B55B),
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    has_seen_onboarding.$ = true;
    has_seen_onboarding.save();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => Main(go_back: false)),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (p) => setState(() => _page = p),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(gradient: slide.gradient),
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Decorative circle with icon
                            Container(
                              width: size.width * 0.45,
                              height: size.width * 0.45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1.5),
                              ),
                              child: Center(
                                child: Icon(
                                  slide.icon,
                                  size: size.width * 0.2,
                                  color: slide.accentColor ?? Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                slide.headline,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                slide.subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: active
                                  ? (slide.accentColor ?? Colors.white)
                                  : Colors.white.withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            if (_page < _slides.length - 1)
                              TextButton(
                                onPressed: _skip,
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14),
                                ),
                              ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _next,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 14),
                                decoration: BoxDecoration(
                                  color: slide.accentColor ?? Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _page == _slides.length - 1
                                          ? 'Get Started'
                                          : 'Next',
                                      style: TextStyle(
                                        color: slide.accentColor != null
                                            ? const Color(0xFF161000)
                                            : MyTheme.accent_color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      _page == _slides.length - 1
                                          ? Icons.check
                                          : Icons.arrow_forward,
                                      size: 16,
                                      color: slide.accentColor != null
                                          ? const Color(0xFF161000)
                                          : MyTheme.accent_color,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OnboardSlide {
  final LinearGradient gradient;
  final IconData icon;
  final String headline;
  final String subtitle;
  final Color? accentColor;

  const _OnboardSlide({
    required this.gradient,
    required this.icon,
    required this.headline,
    required this.subtitle,
    this.accentColor,
  });
}
