import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_providers.dart';
import '../../screens/home/widgets/stats_section.dart';
import '../../screens/home/widgets/cta_section.dart';
import '../../screens/home/widgets/recent_activity_section.dart';

class TrackTab extends ConsumerWidget {
  const TrackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate and refresh all providers
          ref.invalidate(dailyStatsProvider);
          ref.invalidate(recentActivitiesProvider);
          
          // Wait for providers to complete
          await Future.wait([
            ref.read(dailyStatsProvider.future),
            ref.read(recentActivitiesProvider.future),
          ]);
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              
              // Stats Section
              StatsSection(),
              SizedBox(height: 24),
              
              // CTA Section
              CTASection(),
              SizedBox(height: 24),
              
              // Recent Activity Section
              RecentActivitySection(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
