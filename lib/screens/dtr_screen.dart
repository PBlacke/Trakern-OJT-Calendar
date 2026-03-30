import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/ojt_record.dart';
import '../providers/record_provider.dart';
import '../providers/settings_provider.dart';
import 'edit_record_screen.dart';

class DTRScreen extends StatelessWidget {
  const DTRScreen({super.key});

  // Helper to generate a list of days (with synthetic Sundays)
  List<MapEntry<DateTime, OJTRecord?>> _generateRowsWithSundays(List<OJTRecord> records) {
    if (records.isEmpty) return [];

    // Determine the overall date range (min date to max date)
    final firstDate = records.map((r) => r.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final lastDate = records.map((r) => r.date).reduce((a, b) => a.isAfter(b) ? a : b);

    // Build a map of existing records by date
    final existingMap = <DateTime, OJTRecord>{};
    for (var record in records) {
      final key = DateTime(record.date.year, record.date.month, record.date.day);
      existingMap[key] = record;
    }

    final result = <MapEntry<DateTime, OJTRecord?>>[];
    DateTime current = firstDate;
    while (current.isBefore(lastDate.add(const Duration(days: 1)))) {
      final key = DateTime(current.year, current.month, current.day);
      final record = existingMap[key];
      if (record != null) {
        result.add(MapEntry(key, record));
      } else if (current.weekday == DateTime.sunday) {
        // Add a synthetic Sunday row (no record)
        result.add(MapEntry(key, null));
      }
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  Widget _buildHoursCell(OJTRecord? record, DateTime date) {
    // If there's a record, use its flags
    if (record != null) {
      if (record.isHoliday) {
        return const Text('Hol', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold));
      }
      if (record.isAbsent) {
        return const Text('Abs', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
      }
      // If it's a Sunday but not a holiday/absent, we still want "Sun"
      if (date.weekday == DateTime.sunday) {
        return const Text('Sun', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold));
      }
      // Normal day with hours
      return Text(record.totalHours.toStringAsFixed(1));
    } else {
      // No record – if it's a Sunday, show "Sun", otherwise leave blank
      if (date.weekday == DateTime.sunday) {
        return const Text('Sun', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold));
      }
      return const Text('-');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DTR Records'),
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(context), 
            icon: const Icon(Icons.search),
            tooltip: 'Search records',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addPastRecord(context),
            tooltip: 'Add past record',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              Navigator.pushNamed(context, '/export');
            },
          ),
        ],
      ),
      body: Consumer<RecordProvider>(
        builder: (context, recordProvider, child) {
          final records = recordProvider.records;
          if (records.isEmpty) {
            return const Center(child: Text('No records yet. Add your first OJT day.'));
          }

          final rowsWithSundays = _generateRowsWithSundays(records);
          final reversedRows = rowsWithSundays.reversed.toList();

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                headingRowColor: MaterialStateProperty.resolveWith(
                  (states) => Colors.grey.shade200,
                ),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('AM In')),
                  DataColumn(label: Text('AM Out')),
                  DataColumn(label: Text('PM In')),
                  DataColumn(label: Text('PM Out')),
                  DataColumn(label: Text('Hours')),
                  DataColumn(label: Text('Allowance')),
                  DataColumn(label: Text('Edit')),
                ],
                rows: reversedRows.map((entry) {
                  final date = entry.key;
                  final record = entry.value;

                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('MM/dd/yyyy').format(date))),
                      DataCell(Text(record?.timeIn1 ?? '-')),
                      DataCell(Text(record?.timeOut1 ?? '-')),
                      DataCell(Text(record?.timeIn2 ?? '-')),
                      DataCell(Text(record?.timeOut2 ?? '-')),
                      DataCell(_buildHoursCell(record, date)),
                      DataCell(
                        record != null
                            ? Text(
                                '₱${record.allowanceEarned.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.green),
                              )
                            : const Text('-'),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            if (record != null) {
                              _editRecord(context, record);
                            } else {
                              // No record, we can create a new one for this date
                              _addRecordForDate(context, date);
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addPastRecord(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final newRecord = OJTRecord(date: picked);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditRecordScreen(record: newRecord, isNew: true),
        ),
      );
    }
  }

  Future<void> _addRecordForDate(BuildContext context, DateTime date) async {
    final newRecord = OJTRecord(date: date);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecordScreen(record: newRecord, isNew: true),
      ),
    );
  }

  Future<void> _editRecord(BuildContext context, OJTRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecordScreen(record: record, isNew: false),
      ),
    );
  }

  Future<void> _showSearchDialog(BuildContext context) async {
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);
    DateTime selectedDate = DateTime.now();
    OJTRecord? record;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Search Record by Date'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Select Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                          record = recordProvider.records.firstWhere(
                            (r) => r.date.year == picked.year &&
                                  r.date.month == picked.month &&
                                  r.date.day == picked.day,
                            orElse: () => OJTRecord(date: picked),
                          );
                        });
                      }
                    },
                  ),
                  const Divider(),
                  record != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                            const SizedBox(height: 8),
                            if (record!.isHoliday) ...[
                              const Text('Status: Holiday', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ] else if (record!.isAbsent) ...[
                              const Text('Status: Absent', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ] else if (selectedDate.weekday == DateTime.sunday) ...[
                              const Text('Status: Sunday (no log required)', style: TextStyle(color: Colors.orange)),
                            ] else ...[
                              Text('AM In: ${record!.timeIn1 ?? '-'}'),
                              Text('AM Out: ${record!.timeOut1 ?? '-'}'),
                              Text('PM In: ${record!.timeIn2 ?? '-'}'),
                              Text('PM Out: ${record!.timeOut2 ?? '-'}'),
                              Text('Total Hours: ${record!.totalHours.toStringAsFixed(1)}'),
                              Text('Allowance: ₱${record!.allowanceEarned.toStringAsFixed(2)}'),
                            ],
                          ],
                        )
                      : const Text('Select a date to view record'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                if (record != null && record!.date.weekday != DateTime.sunday && !record!.isHoliday)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editRecord(context, record!);
                    },
                    child: const Text('Edit'),
                  ),
              ],
            );
          },
        );
      },
    );
  }


}