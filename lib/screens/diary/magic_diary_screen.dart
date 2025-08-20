import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../services/diary_service.dart';
import '../../models/diary_entry_model.dart';
import '../../providers/auth_provider.dart';
import 'statistics_screen.dart';
import '../tips/tips_recommendations_screen.dart';

class MagicDiaryScreen extends StatefulWidget {
  const MagicDiaryScreen({Key? key}) : super(key: key);

  @override
  State<MagicDiaryScreen> createState() => _MagicDiaryScreenState();
}

class _MagicDiaryScreenState extends State<MagicDiaryScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  DateTime _selectedDate = DateTime.now();
  DiaryEntryModel? _currentEntry;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isFirstSave = true; // Track if this is the first save

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Add listeners to detect changes
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

    _loadDiaryEntry();
  }

  void _onTextChanged() {
    if (mounted && !_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _loadDiaryEntry() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      print('User not authenticated');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasUnsavedChanges = false;
    });

    try {
      print('Loading diary entry for date: $_selectedDate');
      final entry = await DiaryService.getDiaryEntry(_selectedDate);

      if (mounted) {
        setState(() {
          _currentEntry = entry;
          _titleController.text = entry?.title ?? '';
          _contentController.text = entry?.content ?? '';
          _isLoading = false;
          _hasUnsavedChanges = false;
          _isFirstSave =
              entry == null; // If no existing entry, it's a first save
        });
      }

      print('Loaded entry: ${entry?.title ?? 'No entry found'}');
    } catch (e) {
      print('Error loading diary entry: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading diary entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ... (keeping all the existing UI methods like _selectDate, _showUnsavedChangesDialog, etc.)

  Future<void> _selectDate() async {
    // Check for unsaved changes
    if (_hasUnsavedChanges) {
      final shouldContinue = await _showUnsavedChangesDialog();
      if (!shouldContinue) return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate && mounted) {
      setState(() {
        _selectedDate = pickedDate;
      });
      await _loadDiaryEntry();
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    if (!mounted) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Do you want to continue without saving?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Entry'),
            content: const Text(
              'Are you sure you want to delete this diary entry? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            if (_hasUnsavedChanges) {
              final shouldExit = await _showUnsavedChangesDialog();
              if (shouldExit && mounted) {
                Navigator.pop(context);
              }
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Magic eDiary',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () => _navigateToStats(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'Stats',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.bar_chart, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Date Navigation
              Container(
                width: 200,
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _changeDate(-1),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getDateTitle(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_hasUnsavedChanges) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.circle,
                                      color: Colors.orange,
                                      size: 8,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                _getDateSubtitle(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeDate(1),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Diary Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sentiment indicator
                            if (_currentEntry != null &&
                                _currentEntry!.dominantEmotion !=
                                    'undefined') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEmotionColor(
                                    _currentEntry!.dominantEmotion,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getEmotionIcon(
                                        _currentEntry!.dominantEmotion,
                                      ),
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _currentEntry!.dominantEmotion
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(_currentEntry!.confidenceScore * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else if (_currentEntry != null &&
                                _currentEntry!.dominantEmotion ==
                                    'undefined') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'ANALYZING...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Title Field
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Title (optional)',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                            Divider(color: Colors.grey.shade200),

                            // Content Field
                            Expanded(
                              child: TextFormField(
                                controller: _contentController,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Write here...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        text: _isSaving ? 'Saving...' : _getSaveButtonText(),
                        onPressed: _isSaving ? null : _saveEntry,
                        gradient: AppTheme.primaryGradient,
                        height: 50,
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

  String _getSaveButtonText() {
    final hasContent =
        _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;

    if (_currentEntry != null && !hasContent) {
      return 'Delete';
    }
    return 'Save';
  }

  Future<void> _changeDate(int days) async {
    if (_hasUnsavedChanges) {
      final shouldContinue = await _showUnsavedChangesDialog();
      if (!shouldContinue) return;
    }

    if (mounted) {
      setState(() {
        _selectedDate = _selectedDate.add(Duration(days: days));
      });
      await _loadDiaryEntry();
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'happiness':
        return Colors.amber;
      case 'sadness':
        return Colors.blue;
      case 'anger':
        return Colors.red;
      case 'fear':
      case 'anxiety':
        return Colors.orange;
      case 'neutral':
        return Colors.grey;
      case 'undefined':
        return Colors.grey.shade400;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'happiness':
        return Icons.sentiment_very_satisfied;
      case 'sadness':
        return Icons.sentiment_very_dissatisfied;
      case 'anger':
        return Icons.sentiment_dissatisfied;
      case 'fear':
      case 'anxiety':
        return Icons.sentiment_neutral;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'undefined':
        return Icons.help_outline;
      default:
        return Icons.sentiment_neutral;
    }
  }

  String _getDateTitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selected == today) {
      return 'Today';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    }
  }

  String _getDateSubtitle() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}';
  }

  void _clearEntry() {
    if (mounted) {
      setState(() {
        _titleController.clear();
        _contentController.clear();
        _hasUnsavedChanges = false;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!mounted) return;

    final hasContent =
        _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;

    // If no content and entry exists, delete it
    if (!hasContent && _currentEntry != null) {
      final shouldDelete = await _showDeleteConfirmationDialog();
      if (!shouldDelete || !mounted) return;

      setState(() {
        _isSaving = true;
      });

      try {
        await DiaryService.deleteDiaryEntry(_currentEntry!.id);

        if (mounted) {
          setState(() {
            _currentEntry = null;
            _isSaving = false;
            _hasUnsavedChanges = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Diary entry deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting entry: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // If no content and no existing entry, show message
    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      print('Saving entry for date: $_selectedDate');

      final savedEntry = await DiaryService.saveDiaryEntry(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _selectedDate,
      );

      if (savedEntry != null && mounted) {
        setState(() {
          _currentEntry = savedEntry;
          _isSaving = false;
          _hasUnsavedChanges = false;
          _isFirstSave = false; // No longer first save
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Entry saved successfully! Mood analysis in progress...',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Only navigate to tips if it's NOT the first save and sentiment is analyzed
        if (!_isFirstSave && savedEntry.dominantEmotion != 'undefined') {
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TipsRecommendationsScreen(
                  riskLevel: _analyzeRiskLevel(savedEntry.dominantEmotion),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _analyzeRiskLevel(String dominantEmotion) {
    switch (dominantEmotion.toLowerCase()) {
      case 'sadness':
      case 'anger':
      case 'fear':
        return 'high';
      case 'neutral':
        return 'moderate';
      case 'joy':
      case 'happiness':
        return 'low';
      case 'undefined':
      default:
        return 'moderate';
    }
  }

  void _navigateToStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
    );
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _animationController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
