import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../chat/my_chats_screen.dart';


class TipsRecommendationsScreen extends StatefulWidget {
  final String riskLevel;

  const TipsRecommendationsScreen({Key? key, required this.riskLevel}) : super(key: key);

  @override
  State<TipsRecommendationsScreen> createState() => _TipsRecommendationsScreenState();
}

class _TipsRecommendationsScreenState extends State<TipsRecommendationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
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

        title:const Text(
          'Tips & Recommendations',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration:const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Risk Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _getRiskColor(),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      '${_getRiskTitle()} Risk',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Content Card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,

                            offset:const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Do's Section
                            _buildSection(
                              title: "Do's",
                              icon: Icons.check_circle,
                              color: Colors.green,
                              items: _getDosList(),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Don'ts Section
                            _buildSection(
                              title: "Don'ts",
                              icon: Icons.cancel,
                              color: Colors.red,
                              items: _getDontsList(),
                            ),
                            
                            if (widget.riskLevel == 'high') ...[
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  'Mood Mind will recommend you to chat with our consultants.',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action Button
                  widget.riskLevel == 'high'
                      ? GradientButton(
                          text: 'Chat with consultants',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyChatsScreen(),
                              ),
                            );
                          },
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                          ),
                        )
                      : GradientButton(
                          text: 'Back to home',
                          onPressed: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          gradient: AppTheme.primaryGradient,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 8, right: 12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Color _getRiskColor() {
    switch (widget.riskLevel) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRiskTitle() {
    switch (widget.riskLevel) {
      case 'low':
        return 'Low';
      case 'moderate':
        return 'Moderate';
      case 'high':
        return 'High';
      default:
        return 'Unknown';
    }
  }

  List<String> _getDosList() {
    switch (widget.riskLevel) {
      case 'low':
        return [
          'Do journal daily',
          'Do engage in hobbies',
          'Do practice mindfulness',
          'Do check-in with loved ones',
          'Do support others',
        ];
      case 'moderate':
        return [
          'Do practice deep breathing',
          'Do organize tasks',
          'Do take regular breaks',
          'Do limit overstimulation',
          'Do reach out',
        ];
      case 'high':
        return [
          'Do seek help - Use the SOS feature',
          'Do express your feelings',
          'Do practice grounding techniques',
          'Do focus on small steps',
          'Do stay hydrated and nourished',
        ];
      default:
        return [];
    }
  }

  List<String> _getDontsList() {
    switch (widget.riskLevel) {
      case 'low':
        return [
          "Don't skip self-care",
          "Don't stop tracking",
          "Don't forget to celebrate",
          "Don't overload your schedule",
          "Don't become complacent",
        ];
      case 'moderate':
        return [
          "Don't ignore feelings",
          "Don't expect perfection",
          "Don't skip meals or sleep",
          "Don't isolate yourself",
          "Don't skip meals or rest",
        ];
      case 'high':
        return [
          "Don't stay silent",
          "Don't harm yourself",
          "Don't make major decisions right now",
          "Don't overload yourself",
          "Don't wait too long",
        ];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}