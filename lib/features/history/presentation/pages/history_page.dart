import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../domain/entities/history_entry.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plannerEntries = appStorage?.loadHistoryEntries('planner_history') ?? <Map<String, dynamic>>[];
    final sqiEntries = appStorage?.loadHistoryEntries('sqi_history') ?? <Map<String, dynamic>>[];
    final entries = <HistoryEntry>[];

    for (final entry in [...plannerEntries, ...sqiEntries]) {
      entries.add(
        HistoryEntry(
          title: entry['title'] as String? ?? 'Entry',
          subtitle: entry['subtitle'] as String? ?? '',
          dateLabel: _formatDate(entry['dateLabel'] as String?),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: entries.isEmpty
          ? const Center(child: Text('No history recorded yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  child: ListTile(
                    title: Text(entry.title),
                    subtitle: Text(entry.subtitle),
                    trailing: Text(entry.dateLabel),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return 'Recent';
    }

    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      return 'Recent';
    }

    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }
}
