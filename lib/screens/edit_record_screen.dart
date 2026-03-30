import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ojt_record.dart';
import '../providers/record_provider.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class EditRecordScreen extends StatefulWidget {
  final OJTRecord record;
  final bool isNew;

  const EditRecordScreen({super.key, required this.record, required this.isNew});

  @override
  State<EditRecordScreen> createState() => _EditRecordScreenState();
}

class _EditRecordScreenState extends State<EditRecordScreen> {
  late TimeOfDay? _timeIn1;
  late TimeOfDay? _timeOut1;
  late TimeOfDay? _timeIn2;
  late TimeOfDay? _timeOut2;
  late bool _isAbsent;

  @override
  void initState() {
    super.initState();
    _timeIn1 = _parseTime(widget.record.timeIn1);
    _timeOut1 = _parseTime(widget.record.timeOut1);
    _timeIn2 = _parseTime(widget.record.timeIn2);
    _timeOut2 = _parseTime(widget.record.timeOut2);
    _isAbsent = widget.record.isAbsent;
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  double _calculateTotalHours() {
    double total = 0;
    if (_timeIn1 != null && _timeOut1 != null) {
      total += (_timeOut1!.hour - _timeIn1!.hour) +
          (_timeOut1!.minute - _timeIn1!.minute) / 60;
    }
    if (_timeIn2 != null && _timeOut2 != null) {
      total += (_timeOut2!.hour - _timeIn2!.hour) +
          (_timeOut2!.minute - _timeIn2!.minute) / 60;
    }
    return total;
  }

  double _calculateAllowance(double totalHours, double allowancePerDay) {
    return (totalHours / 8).clamp(0.0, 1.0) * allowancePerDay;
  }

  Future<void> _save() async {
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    double totalHours = _isAbsent ? 0.0 : _calculateTotalHours();
    double allowance = 0.0;
    if (!_isAbsent && settingsProvider.settings.allowancePerDay != null) {
      allowance = _calculateAllowance(totalHours, settingsProvider.settings.allowancePerDay!);
    }

    final updatedRecord = OJTRecord(
      id: widget.record.id,
      date: widget.record.date,
      timeIn1: _formatTime(_timeIn1),
      timeOut1: _formatTime(_timeOut1),
      timeIn2: _formatTime(_timeIn2),
      timeOut2: _formatTime(_timeOut2),
      isAbsent: _isAbsent,
      totalHours: totalHours,
      allowanceEarned: allowance,
    );

    await recordProvider.saveOrUpdateRecord(updatedRecord);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Add Record' : 'Edit Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(widget.record.date),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isAbsent,
                  onChanged: (val) {
                    setState(() {
                      _isAbsent = val ?? false;
                      if (_isAbsent) {
                        _timeIn1 = null;
                        _timeOut1 = null;
                        _timeIn2 = null;
                        _timeOut2 = null;
                      }
                    });
                  },
                ),
                const Text('Mark as Absent'),
              ],
            ),
            const Divider(),
            if (!_isAbsent) ...[
              const Text('Morning Session', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Time In'),
                      subtitle: Text(_formatTime(_timeIn1).isEmpty ? 'Not set' : _formatTime(_timeIn1)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _timeIn1 ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _timeIn1 = time);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Time Out'),
                      subtitle: Text(_formatTime(_timeOut1).isEmpty ? 'Not set' : _formatTime(_timeOut1)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _timeOut1 ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _timeOut1 = time);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Afternoon Session', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Time In'),
                      subtitle: Text(_formatTime(_timeIn2).isEmpty ? 'Not set' : _formatTime(_timeIn2)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _timeIn2 ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _timeIn2 = time);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Time Out'),
                      subtitle: Text(_formatTime(_timeOut2).isEmpty ? 'Not set' : _formatTime(_timeOut2)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _timeOut2 ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _timeOut2 = time);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const Divider(),
              Text('Total hours: ${_calculateTotalHours().toStringAsFixed(2)}'),
              if (settings.allowancePerDay != null)
                Text('Allowance: ₱${_calculateAllowance(_calculateTotalHours(), settings.allowancePerDay!).toStringAsFixed(2)}'),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}