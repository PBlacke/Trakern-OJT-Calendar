import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/record_provider.dart';
import '../providers/settings_provider.dart';

class OverallProgress extends StatelessWidget {
  const OverallProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;
    final records = Provider.of<RecordProvider>(context).records;
    
    double completedHours = records.fold(0.0, (sum, record) => sum + record.totalHours);
    double target = settings.totalRequiredHours ?? 500.0;  // fallback if null
    double percentage = target > 0 ? (completedHours / target).clamp(0.0, 1.0) : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Overall OJT Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('${(percentage * 100).toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green,
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Completed: ${completedHours.toStringAsFixed(1)} hrs'),
                Text('Target: ${target.toStringAsFixed(1)} hrs'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}