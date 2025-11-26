import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active walking screen - placeholder
/// TODO: Implement full active walking with GPS tracking, metrics, map, mission tracking
/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7
class ActiveWalkingScreen extends ConsumerWidget {
  const ActiveWalkingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walking'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Active Walking Screen',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Text('00:00'),
            const Text('0.00 km'),
            const Text('0 steps'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: End walking session
                Navigator.of(context).pushNamed('/workout/walking/summary');
              },
              child: const Text('End Workout'),
            ),
          ],
        ),
      ),
    );
  }
}
