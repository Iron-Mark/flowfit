import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active resistance training screen - placeholder
/// TODO: Implement full active resistance with exercise tracking, set completion, rest timers
/// Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8
class ActiveResistanceScreen extends ConsumerWidget {
  const ActiveResistanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resistance Training'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Active Resistance Screen',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Text('Exercise 1/6'),
            const Text('Bench Press'),
            const Text('Set 1 of 3'),
            const Text('12 reps'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Complete set
              },
              child: const Text('Complete Set'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // TODO: End workout
                Navigator.of(context).pushNamed('/workout/resistance/summary');
              },
              child: const Text('End Workout'),
            ),
          ],
        ),
      ),
    );
  }
}
