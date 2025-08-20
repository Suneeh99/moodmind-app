import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodmind_new/screens/settings/emergency_contact_screen.dart';

import '../../utils/app_theme.dart';
import '../../models/emergency_contact_model.dart';
import '../../services/emergency_contact_service.dart';
import '../../services/sos_service.dart';

class SmartSOSScreen extends StatefulWidget {
  const SmartSOSScreen({super.key});

  @override
  _SmartSOSScreenState createState() => _SmartSOSScreenState();
}

class _SmartSOSScreenState extends State<SmartSOSScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  int _tapCount = 0;
  int _freeChancessLeft = 2; // keep your existing logic/limit
  bool _isActivated = false;

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Smart SOS',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SOS Button
                        GestureDetector(
                          onTap: _handleSOSTap,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isActivated
                                    ? _pulseAnimation.value
                                    : 1.0,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isActivated
                                          ? [
                                              const Color(0xFFff6b6b),
                                              const Color(0xFFee5a24),
                                            ]
                                          : [
                                              const Color(0xFFff9a9e),
                                              const Color(0xFFfecfef),
                                            ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFff6b6b,
                                        ).withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.emergency,
                                          color: Colors.white,
                                          size: 60,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'SOS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_tapCount > 0)
                                          Text(
                                            '$_tapCount/5',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
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

                        const SizedBox(height: 40),

                        // Instructions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.primaryBlue,
                                size: 30,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Tap 5 times to send message to trusted contacts',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Free Chances Left
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    'You have $_freeChancessLeft Free Chances left',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

  void _handleSOSTap() {
    HapticFeedback.heavyImpact();

    setState(() {
      _tapCount++;
      if (_tapCount == 1) {
        _isActivated = true;
        _pulseController.repeat(reverse: true);
      }
    });

    if (_tapCount >= 5) {
      _sendSOSMessage();
    }

    // Reset after 3 seconds if not completed
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_tapCount < 5) {
        setState(() {
          _tapCount = 0;
          _isActivated = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  Future<void> _sendSOSMessage() async {
    _pulseController.stop();

    // If no chances, show dialog and bail
    if (_freeChancessLeft <= 0) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Chances Left'),
          content: const Text(
            'You have used all your free SOS chances. Please contact support for more.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // 1) Load contacts
    final List<EmergencyContact> contacts =
        await EmergencyContactService.getEmergencyContacts();

    // 2) If none, ask to set up
    if (contacts.isEmpty) {
      if (!mounted) return;
      final shouldSetup = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No emergency contacts'),
          content: const Text(
            'You need at least one emergency contact to send an SOS. '
            'Would you like to add one now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add contact'),
            ),
          ],
        ),
      );

      if (shouldSetup == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmergencyContactScreen()),
        );
      }

      if (!mounted) return;
      setState(() {
        _tapCount = 0;
        _isActivated = false;
      });
      _pulseController.reset();
      return;
    }

    // 3) Build SOS message
    final me = FirebaseAuth.instance.currentUser;
    final who = (me?.displayName?.trim().isNotEmpty ?? false)
        ? me!.displayName!.trim()
        : 'A MoodMind user';
    final message =
        'SOS! I need help right now. Please call or reach me ASAP. – $who';

    // 4) Try to send (Cloud Function first; fallback to SMS composer)
    bool ok = false;
    try {
      ok = await SosService.sendSOS(
        contacts: contacts.take(3).toList(), // sensible limit for free plan
        message: message,
      );
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;

    // 5) Update state & show feedback
    setState(() {
      if (ok) _freeChancessLeft--;
      _tapCount = 0;
      _isActivated = false;
    });
    _pulseController.reset();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ok ? 'SOS Sent!' : 'Could not send SOS'),
        content: Text(
          ok
              ? 'Your emergency message was sent to your trusted contacts.'
              : 'We could not send the SOS automatically. If your SMS app opened, please send the message from there. Otherwise, try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
