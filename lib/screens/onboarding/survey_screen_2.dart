import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';

class SurveyScreen2 extends StatefulWidget {
  const SurveyScreen2({super.key});

  @override
  State<SurveyScreen2> createState() => _SurveyScreen2State();
}

class _SurveyScreen2State extends State<SurveyScreen2> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _heightController.text.isNotEmpty && _weightController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Your measurements',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Help us calculate accurate metrics',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),

                        const SizedBox(height: 40),

                        // Height Input
                        Text(
                          'Height',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter height',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryBlue,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _heightUnit,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    dropdownColor: Colors.white,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    items: ['cm', 'ft'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Row(
                                          children: [
                                            Icon(
                                              SolarIconsBold.ruler,
                                              size: 16,
                                              color: _heightUnit == value
                                                  ? AppTheme.primaryBlue
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(value),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() => _heightUnit = newValue);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Weight Input
                        Text(
                          'Weight',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _weightController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter weight',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryBlue,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _weightUnit,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    dropdownColor: Colors.white,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    items: ['kg', 'lbs'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Row(
                                          children: [
                                            Icon(
                                              SolarIconsBold.dumbbellSmall,
                                              size: 16,
                                              color: _weightUnit == value
                                                  ? AppTheme.primaryBlue
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(value),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() => _weightUnit = newValue);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Continue Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _canContinue
                                ? () => Navigator.pushNamed(context, '/survey3')
                                : null,
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
}
