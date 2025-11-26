import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/running_session.dart';

/// Running setup screen - placeholder
/// TODO: Implement full running setup with goal selection, sliders, map preview
/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6
class RunningSetupScreen extends ConsumerStatefulWidget {
  const RunningSetupScreen({super.key});

  @override
  ConsumerState<RunningSetupScreen> createState() => _RunningSetupScreenState();
}

class _RunningSetupScreenState extends ConsumerState<RunningSetupScreen> {
  GoalType _goalType = GoalType.distance;
  double _targetDistance = 5.0;
  int _targetDuration = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Setup'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Running Setup Screen',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text('Goal: ${_goalType.displayName}'),
            Text('Target: ${_targetDistance}km / ${_targetDuration}min'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Start running session
                Navigator.of(context).pushNamed('/workout/running/active');
              },
              child: const Text('Start Running'),
            ),
          ],
        ),
      ),
    );
  }
}
