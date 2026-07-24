import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/sleep_plan_model.dart';
import '../../models/sqi_record_model.dart';
import '../../models/recommendation_model.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;

  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<SleepPlan> _sleepPlans = [];
  List<SQIRecord> _sqiRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final sleepPlans = await _firestoreService.getSleepPlans(widget.userId);
      final sqiRecords = await _firestoreService.getSQIRecords(widget.userId);

      setState(() {
        _sleepPlans = sleepPlans;
        _sqiRecords = sqiRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sleep Plans',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _sleepPlans.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No sleep plans available'),
                          ),
                        )
                      : Column(
                          children: _sleepPlans.map((plan) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Created: ${_formatDate(plan.createdAt)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Wake-up Time: ${_formatTime(plan.wakeUpTime)}'),
                                    const SizedBox(height: 4),
                                    Text('Sleep Cycles: ${plan.sleepCycles}'),
                                    const SizedBox(height: 4),
                                    Text('Total Duration: ${plan.sleepCycles * 90} minutes'),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Suggested Bedtimes:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ...plan.suggestedBedtimes.map((bedtime) {
                                      return Text(bedtime);
                                    }).toList(),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),
                  const Text(
                    'SQI Records',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _sqiRecords.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No SQI records available'),
                          ),
                        )
                      : Column(
                          children: _sqiRecords.map((record) {
                            return FutureBuilder<List<Recommendation>>(
                              future: _firestoreService.getRecommendations(record.recordId),
                              builder: (context, snapshot) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date: ${_formatDate(record.createdAt)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Score: ${record.sqiScore}'),
                                        const SizedBox(height: 4),
                                        Text('Quality: ${record.sleepQualityLevel}'),
                                        if (snapshot.hasData && snapshot.data!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Recommendations:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          ...snapshot.data!.map((recommendation) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Text('- ${recommendation.title}'),
                                                Text('  ${recommendation.description}'),
                                              ],
                                            );
                                          }).toList(),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Back to Home',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}