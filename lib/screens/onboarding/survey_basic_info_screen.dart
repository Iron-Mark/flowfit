import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../widgets/survey_app_bar.dart';

class SurveyBasicInfoScreen extends ConsumerStatefulWidget {
  const SurveyBasicInfoScreen({super.key});

  @override
  ConsumerState<SurveyBasicInfoScreen> createState() =>
      _SurveyBasicInfoScreenState();
}

class _SurveyBasicInfoScreenState extends ConsumerState<SurveyBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  String? _selectedGender;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    // Get user name from arguments (passed from signup)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final name = args?['name'] as String?;
      if (name != null && name.isNotEmpty) {
        setState(() {
          _userName = name;
        });
        // Save to survey data
        ref
            .read(surveyNotifierProvider.notifier)
            .updateSurveyData('fullName', name);
      }
    });

    // Load existing data if available or set default
    final surveyState = ref.read(surveyNotifierProvider);
    final age = surveyState.surveyData['age'];
    if (age != null) {
      _ageController.text = age.toString();
    } else {
      _ageController.text = '18'; // Default age
    }
    _selectedGender = surveyState.surveyData['gender'] as String?;
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _selectedGender != null && _ageController.text.isNotEmpty;

  void _incrementAge() {
    final currentAge = int.tryParse(_ageController.text) ?? 0;
    if (currentAge < 120) {
      _ageController.text = (currentAge + 1).toString();
      setState(() {});
    }
  }

  void _decrementAge() {
    final currentAge = int.tryParse(_ageController.text) ?? 0;
    if (currentAge > 13) {
      _ageController.text = (currentAge - 1).toString();
      setState(() {});
    }
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    if (age > 120) {
      return 'Please enter a valid age';
    }
    return null;
  }

  Future<void> _handleNext() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your gender'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save data to survey notifier
      final surveyNotifier = ref.read(surveyNotifierProvider.notifier);
      await surveyNotifier.updateSurveyData(
        'age',
        int.parse(_ageController.text),
      );
      await surveyNotifier.updateSurveyData('gender', _selectedGender);

      // Validate using the notifier's validation method
      final validationError = surveyNotifier.validateBasicInfo();
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: Colors.red,
            ),
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
          '/survey_body_measurements',
          arguments: args,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const SurveyAppBar(currentStep: 1, totalSteps: 4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Progress Indicator
                        const SurveyProgressIndicator(
                          currentStep: 1,
                          totalSteps: 4,
                        ),

                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Tell us about yourself',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'This helps us personalize your experience',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),

                        const SizedBox(height: 40),

                        // Gender Selection
                        Text(
                          'Gender',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF314158),
                              ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderCard('Male', Icons.male),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderCard('Female', Icons.female),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderCard(
                                'Other',
                                SolarIconsBold.user,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Age Input
                        Text(
                          'Age',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF314158),
                              ),
                        ),

                        const SizedBox(height: 12),

                        _buildAgeInput(),

                        const Spacer(),

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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAgeInput() {
    final currentAge = int.tryParse(_ageController.text);
    final canDecrement = currentAge != null && currentAge > 13;
    final canIncrement = currentAge != null && currentAge < 120;

    return Form(
      key: _formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Decrement Button
          _buildAdjustButton(
            icon: Icons.remove_rounded,
            onTap: canDecrement ? _decrementAge : null,
            enabled: canDecrement,
          ),

          // Age Display
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    height: 1.0,
                    letterSpacing: -3,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    errorStyle: TextStyle(fontSize: 0, height: 0),
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  validator: _validateAge,
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  'years old',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Increment Button
          _buildAdjustButton(
            icon: Icons.add_rounded,
            onTap: canIncrement ? _incrementAge : null,
            enabled: canIncrement,
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primaryBlue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildGenderCard(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;

    // Define colors based on gender
    Color selectedColor;
    Color unselectedIconColor;

    switch (gender) {
      case 'Male':
        selectedColor = AppTheme.primaryBlue;
        unselectedIconColor = AppTheme.primaryBlue.withValues(alpha: 0.4);
        break;
      case 'Female':
        selectedColor = const Color(0xFFFF69B4); // Hot pink
        unselectedIconColor = const Color(0xFFFF69B4).withValues(alpha: 0.4);
        break;
      case 'Other':
        selectedColor = Colors.grey[700]!;
        unselectedIconColor = Colors.grey[400]!;
        break;
      default:
        selectedColor = AppTheme.primaryBlue;
        unselectedIconColor = Colors.grey[400]!;
    }

    // Rainbow border for "Other" option - use same structure as other cards
    if (gender == 'Other' && isSelected) {
      return GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF6B6B), // Red
                Color(0xFFFFD93D), // Yellow
                Color(0xFF6BCF7F), // Green
                Color(0xFF4D96FF), // Blue
                Color(0xFFB565D8), // Purple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(2), // Border width
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 22,
            ), // 24 - 2 = 22 to match total height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32, color: selectedColor),
                const SizedBox(height: 12),
                Text(
                  gender,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selectedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Regular cards for Male, Female, and unselected Other
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : unselectedIconColor,
            ),
            const SizedBox(height: 12),
            Text(
              gender,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
