import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/mood_transformation_card.dart';

/// Resistance training summary screen - placeholder
/// TODO: Implement full summary with mood transformation, exercise breakdown, volume
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.6, 11.7
class ResistanceSummaryScreen extends ConsumerWidget {
  const ResistanceSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Complete'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const MoodTransformationCard(),
            const SizedBox(height: 24),
            Text(
              'Resistance Training Summary',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Text('Duration: 52:30'),
            const Text('Exercises: 6/6 completed'),
            const Text('Total Volume: 2,450 kg'),
            const Text('Calories: 420'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Save to history
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Save to History'),
            ),
          ],
        ),
      ),
    );
  }
}
