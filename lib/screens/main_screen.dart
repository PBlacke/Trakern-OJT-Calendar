import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/ojt_calendar.dart';
import '../widgets/overall_progress.dart';
import '../widgets/log_panel.dart';
import '../providers/record_provider.dart';
import '../models/ojt_record.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final records = Provider.of<RecordProvider>(context).records;

    final existingRecord = records.firstWhere(
      (r) => r.date.year == _selectedDate.year &&
          r.date.month == _selectedDate.month &&
          r.date.day == _selectedDate.day,
      orElse: () => OJTRecord(date: _selectedDate),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('OJT Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/about');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () {
              Navigator.pushNamed(context, '/dtr');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            const OverallProgress(),
            const SizedBox(height: 8),
            OJTCalendar(
              onDaySelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              records: records,
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: LogPanel(
                  selectedDate: _selectedDate,
                  existingRecord: existingRecord,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}