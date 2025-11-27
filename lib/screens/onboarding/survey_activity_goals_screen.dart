import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../widgets/survey_app_bar.dart';

class SurveyActivityGoalsScreen extends ConsumerStatefulWidget {
  const SurveyActivityGoalsScreen({super.key});

  @override
  ConsumerState<SurveyActivityGoalsScreen> createState() =>
      _SurveyActivityGoalsScreenState();
}

class _SurveyActivityGoalsScreenState
    extends ConsumerState<SurveyActivityGoalsScreen> {
  String? _selectedActivityLevel;
  Set<String> _selectedGoals = {};

  final List<Map<String, dynamic>> _activityLevels = [
    {
      'id': 'sedentary',
      'title': 'Sedentary',
      'icon': SolarIconsBold.smartphone,
      'description': 'Desk job, little exercise',
      'multiplier': '1.2×',
    },
    {
      'id': 'moderately_active',
      'title': 'Moderately Active',
      'icon': SolarIconsBold.bicycling,
      'description': 'Exercise 3-5 times/week',
      'multiplier': '1.55×',
    },
    {
      'id': 'very_active',
      'title': 'Very Active',
      'icon': SolarIconsBold.dumbbellSmall,
      'description': 'Daily intense exercise',
      'multiplier': '1.725×',
    },
  ];

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'lose_weight',
      'title': 'Lose Weight',
      'icon': SolarIconsBold.fire,
      'description': 'Safe deficit: -500 cal/day',
      'color': Colors.orange,
    },
    {
      'id': 'maintain_weight',
      'title': 'Maintain Weight',
      'icon': SolarIconsBold.scale,
      'description': 'Stay at current weight',
      'color': Colors.green,
    },
    {
      'id': 'build_muscle',
      'title': 'Build Muscle',
      'icon': SolarIconsBold.dumbbellSmall,
      'description': 'Surplus: +300 cal/day',
      'color': Colors.purple,
    },
    {
      'id': 'improve_cardio',
      'title': 'Improve Cardio',
      'icon': SolarIconsBold.heartPulse,
      'description': 'Focus on heart health',
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Load existing data if available
    final surveyState = ref.read(surveyNotifierProvider);
    _selectedActivityLevel = surveyState.surveyData['activityLevel'] as String?;
    final goals = surveyState.surveyData['goals'] as List<dynamic>?;
    if (goals != null) {
      _selectedGoals = goals.map((e) => e.toString()).toSet();
    }
  }

  bool get _canContinue =>
      _selectedActivityLevel != null && _selectedGoals.isNotEmpty;

  Future<void> _handleNext() async {
    // Validate selections
    if (_selectedActivityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your activity level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one fitness goal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save data to survey notifier
    final surveyNotifier = ref.read(surveyNotifierProvider.notifier);
    await surveyNotifier.updateSurveyData(
      'activityLevel',
      _selectedActivityLevel,
    );
    await surveyNotifier.updateSurveyData('goals', _selectedGoals.toList());

    // Validate using the notifier's validation method
    final validationError = surveyNotifier.validateActivityGoals();
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationError), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Navigate to next screen
    if (mounted) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      Navigator.pushReplacementNamed(
        context,
        '/survey_daily_targets',
        arguments: args,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity & Goals',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '3/4',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Activity Level Section
              const Row(
                children: [
                  Icon(
                    SolarIconsBold.running,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Current Activity Level',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ..._activityLevels.map(
                (level) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActivityCard(level),
                ),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 32),

              // Goals Section
              const Row(
                children: [
                  Icon(
                    SolarIconsBold.target,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Primary Fitness Goal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ..._goals.map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildGoalCard(goal),
                ),
              ),

              const SizedBox(height: 48),

              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _canContinue ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> level) {
    final isSelected = _selectedActivityLevel == level['id'];

    return GestureDetector(
      onTap: () => setState(() => _selectedActivityLevel = level['id']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Icon(
              level['icon'],
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level['description'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(${level['multiplier']} multiplier)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final isSelected = _selectedGoals.contains(goal['id']);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedGoals.remove(goal['id']);
          } else {
            if (_selectedGoals.length < 5) {
              _selectedGoals.add(goal['id'] as String);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum 5 goals can be selected'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (goal['color'] as Color).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? goal['color'] : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? goal['color'] : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Icon(
              goal['icon'],
              color: isSelected ? goal['color'] : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? goal['color'] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal['description'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
