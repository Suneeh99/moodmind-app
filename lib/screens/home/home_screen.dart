import 'package:flutter/material.dart';
import 'package:moodmind_new/screens/chat/consultants_list_screen.dart';
import 'package:moodmind_new/screens/chat/my_chats_screen.dart';
import 'package:moodmind_new/screens/emergency/smart_sos_screen.dart';
import '../../utils/app_theme.dart';
import '../../widgets/feature_card.dart';
import '../diary/magic_diary_screen.dart';
import '../tasks/task_scheduler_screen.dart';
import '../motivation/motivation_lounge_screen.dart';
import '../emergency/emergency_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/user_profile_service.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;

  UserModel? _currentUser;
  String _greeting = 'Good Morning';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _fabAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));

    _setGreetingBasedOnTime();
    _loadCurrentUser();
    _animationController.forward();
  }

  void _setGreetingBasedOnTime() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      _greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      _greeting = 'Good Evening';
    } else {
      _greeting = 'Good Night';
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserProfileService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error loading user: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  String _getUserDisplayName() {
    if (_isLoadingUser) {
      return 'Loading...';
    }

    if (_currentUser?.name != null && _currentUser!.name.isNotEmpty) {
      // Get first name only
      final firstName = _currentUser!.name.split(' ').first;
      return firstName;
    }

    // Fallback to email username if name is not available
    if (_currentUser?.email != null && _currentUser!.email.isNotEmpty) {
      final emailUsername = _currentUser!.email.split('@').first;
      // Capitalize first letter
      return emailUsername.isNotEmpty
          ? '${emailUsername[0].toUpperCase()}${emailUsername.substring(1)}'
          : 'User';
    }

    return 'User';
  }

  String _getMotivationalMessage() {
    final hour = DateTime.now().hour;
    final messages = {
      'morning': [
        'Start your journey to wellness!',
        'Today is full of possibilities!',
        'Begin your day with positivity!',
        'Make today amazing!',
      ],
      'afternoon': [
        'Keep up the great work!',
        'You\'re doing wonderfully!',
        'Stay focused and positive!',
        'Continue your wellness journey!',
      ],
      'evening': [
        'Reflect on your achievements!',
        'Wind down and relax!',
        'You\'ve made it through the day!',
        'Time to unwind and recharge!',
      ],
      'night': [
        'Rest well and recharge!',
        'Tomorrow brings new opportunities!',
        'Take care of yourself!',
        'Sweet dreams and peaceful rest!',
      ],
    };

    String timeOfDay;
    if (hour >= 5 && hour < 12) {
      timeOfDay = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }

    final messageList = messages[timeOfDay]!;
    return messageList[DateTime.now().day % messageList.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header with Settings Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(0),
                          topLeft: Radius.circular(0),
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showSettingsOverlay(),
                            child: const Icon(
                              Icons.menu,
                              color: Color.fromARGB(255, 255, 255, 255),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_greeting, ${_getUserDisplayName()}!',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getMotivationalMessage(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child:
                                      _currentUser?.photoUrl != null &&
                                          _currentUser!.photoUrl!.isNotEmpty
                                      ? Image.network(
                                          _currentUser!.photoUrl!,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return _buildDefaultAvatar();
                                              },
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                );
                                              },
                                        )
                                      : _buildDefaultAvatar(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          FeatureCard(
                            title: 'Magic eDiary',
                            icon: Icons.book_rounded,
                            backgroundImagePath: 'assets/images/diary_bg.png',
                            onTap: () => _navigateToScreen(MagicDiaryScreen()),
                          ),
                          const SizedBox(height: 5),
                          FeatureCard(
                            title: 'Task Scheduler',
                            icon: Icons.schedule_rounded,
                            backgroundImagePath: 'assets/images/task_bg.png',
                            onTap: () =>
                                _navigateToScreen(TaskSchedulerScreen()),
                          ),
                          const SizedBox(height: 5),
                          FeatureCard(
                            title: 'Motivational\nLounge',
                            icon: Icons.self_improvement_rounded,
                            backgroundImagePath:
                                'assets/images/motivation_bg.png',
                            onTap: () =>
                                _navigateToScreen(MotivationLoungeScreen()),
                          ),
                          const SizedBox(height: 5),
                          FeatureCard(
                            title: 'Chat with\nConsultants',
                            icon: Icons.chat_rounded,
                            backgroundImagePath: 'assets/images/chat_bg.png',
                            onTap: () =>
                                _navigateToScreen(ConsultantListScreen()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // Floating Emergency Button
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFff6b6b), Color(0xFFee5a24)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFff6b6b).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => _navigateToScreen(const SmartSOSScreen()),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        Icons.person,
        color: Colors.white.withValues(alpha: 0.8),
        size: 35,
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showSettingsOverlay() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SettingsScreen(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }
}
