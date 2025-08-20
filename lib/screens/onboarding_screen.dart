import 'package:flutter/material.dart';
import '../models/onboarding_data.dart';
import '../widgets/onboarding_page.dart';
import '../utils/app_theme.dart';
import 'auth/sign_up_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  final List<OnboardingData> onboardingPages = [
    OnboardingData(
      title: "AI-powered Magic eDiary",
      description:
          "Write your thoughts and let AI detect your mood and give helpful tips to improve it.",
      imagePath: "assets/images/diary_illustration.png",
      gradientColors: [AppTheme.primaryBlue, AppTheme.primaryRose],
      icon: Icons.book_rounded,
    ),
    OnboardingData(
      title: "Smart Task Scheduler",
      description:
          "Boost your productivity by scheduling tasks, getting smart notifications and earning points for completing them.",
      imagePath: "assets/images/scheduler_illustration.png",
      gradientColors: [AppTheme.lightBlue, AppTheme.primaryRose],
      icon: Icons.schedule_rounded,
    ),
    OnboardingData(
      title: "Smart SOS System",
      description:
          "In emergencies, draw a pattern on the screen to instantly send an alert message to your trusted contacts.",
      imagePath: "assets/images/sos_illustration.png",
      gradientColors: [AppTheme.primaryRose, const Color(0xFFFF6B6B)],
      icon: Icons.emergency_rounded,
    ),
    OnboardingData(
      title: "Motivational Lounge",
      description:
          "A calming space filled with quotes, music, and videos to lift your mood and keep you inspired every day.",
      imagePath: "assets/images/lounge_illustration.png",
      gradientColors: [const Color(0xFF9C27B0), AppTheme.primaryBlue],
      icon: Icons.self_improvement_rounded,
    ),
    OnboardingData(
      title: "Chat with Consultants",
      description:
          "Get instant support by chatting with our professional consultants for guidance and help whenever you need it.",
      imagePath: "assets/images/chat_illustration.png",
      gradientColors: [AppTheme.primaryBlue, const Color(0xFF00BCD4)],
      icon: Icons.chat_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView with enhanced animations
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: onboardingPages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                data: onboardingPages[index],
                isActive: index == _currentPage,
              );
            },
          ),

          // Skip button with animation
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _currentPage < onboardingPages.length - 1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: TextButton(
                onPressed: _navigateToAuth,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Bottom section with enhanced animations
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Enhanced page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingPages.length,
                      (index) => _buildEnhancedPageIndicator(index),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Enhanced button with animations
                  AnimatedBuilder(
                    animation: _buttonScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonScaleAnimation.value,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withValues(alpha: 0.9)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _buttonController.forward().then((_) {
                                _buttonController.reverse();
                                if (_currentPage ==
                                    onboardingPages.length - 1) {
                                  _navigateToAuth();
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                  );
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              _currentPage == onboardingPages.length - 1
                                  ? 'Get Started'
                                  : 'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                foreground: Paint()
                                  ..shader = onboardingPages[_currentPage]
                                              .gradientColors
                                              .length >
                                          1
                                      ? LinearGradient(
                                          colors: onboardingPages[_currentPage]
                                              .gradientColors,
                                        ).createShader(
                                          const Rect.fromLTWH(0, 0, 200, 70))
                                      : null,
                                color: onboardingPages[_currentPage]
                                            .gradientColors
                                            .length >
                                        1
                                    ? null
                                    : onboardingPages[_currentPage]
                                        .gradientColors[0],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPageIndicator(int index) {
    bool isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }

  void _navigateToAuth() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    super.dispose();
  }
}
