import 'package:flutter/material.dart';
import '../sleep_planner/presentation/pages/sleep_planner_page.dart';
import '../sqi/sqi_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Optimizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.schedule,
              title: 'Sleep Planner',
              description:
                  'Calculate your ideal bedtime based on your wake-up time',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SleepPlannerPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.bed,
              title: 'Sleep Quality Score (SQI)',
              description:
                  'Assess your sleep quality and get personalized recommendations',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SQIScreen(userId: userId),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.history,
              title: 'History',
              description: 'View your past sleep plans and SQI results',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(userId: userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
