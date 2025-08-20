import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _textController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  bool _hasNavigated = false;
  late VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Background floating animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _backgroundAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );
  }

  void _startAnimationSequence() async {
    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 300));

    // Start text animation
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Wait for animations and then check auth state
    await Future.delayed(const Duration(milliseconds: 2000));
    _checkAuthState();
  }

  void _checkAuthState() {
    if (_hasNavigated) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _authListener = () {
      if (_hasNavigated) return;

      if (!authProvider.isLoading) {
        _navigateBasedOnAuthState(authProvider);
      }
    };

    authProvider.addListener(_authListener);

    // Also check immediately in case auth state is already determined
    if (!authProvider.isLoading) {
      _navigateBasedOnAuthState(authProvider);
    }
  }

  void _navigateBasedOnAuthState(AuthProvider authProvider) {
    if (_hasNavigated) return;

    _hasNavigated = true;

    if (authProvider.isAuthenticated && authProvider.user != null) {
      print(
        'User is authenticated, navigating to home: ${authProvider.user!.name}',
      );
      // User is logged in, navigate to home
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      print('User is not authenticated, navigating to onboarding');
      // User is not logged in, navigate to onboarding
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // Animated background elements
            _buildAnimatedBackground(),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fade-in static logo
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  // Animated text
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: const Column(
                        children: [
                          Text(
                            'Mood Mind',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'AI powered insight for mental well-being and productivity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color.fromARGB(255, 117, 117, 117),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Loading indicator
                  const SizedBox(height: 40),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isLoading) {
                        return const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBlue,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating circles
            Positioned(
              top: 100 + sin(_backgroundAnimation.value) * 20,
              left: 50 + cos(_backgroundAnimation.value * 0.8) * 30,
              child: _buildFloatingCircle(
                60,
                AppTheme.lightBlue.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              top: 200 + cos(_backgroundAnimation.value * 1.2) * 25,
              right: 80 + sin(_backgroundAnimation.value * 0.6) * 20,
              child: _buildFloatingCircle(
                40,
                AppTheme.lightRose.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              bottom: 150 + sin(_backgroundAnimation.value * 0.9) * 30,
              left: 100 + cos(_backgroundAnimation.value * 1.1) * 25,
              child: _buildFloatingCircle(
                80,
                AppTheme.primaryBlue.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              bottom: 300 + cos(_backgroundAnimation.value * 0.7) * 20,
              right: 60 + sin(_backgroundAnimation.value * 1.3) * 35,
              child: _buildFloatingCircle(
                50,
                AppTheme.primaryRose.withValues(alpha: 0.08),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  @override
  void dispose() {
    Provider.of<AuthProvider>(
      context,
      listen: false,
    ).removeListener(_authListener);
    _backgroundController.dispose();
    _textController.dispose();
    super.dispose();
  }
}
