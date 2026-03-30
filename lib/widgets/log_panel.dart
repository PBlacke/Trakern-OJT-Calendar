import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ojt_record.dart';
import '../providers/record_provider.dart';
import '../providers/settings_provider.dart';

class LogPanel extends StatefulWidget {
  final DateTime selectedDate;
  final OJTRecord? existingRecord;

  const LogPanel({
    super.key,
    required this.selectedDate,
    this.existingRecord,
  });

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  // Time pickers for AM and PM slots
  TimeOfDay? _timeIn1;
  TimeOfDay? _timeOut1;
  TimeOfDay? _timeIn2;
  TimeOfDay? _timeOut2;
  bool _isAbsent = false;
  bool _isHoliday = false;   // new

  @override
  void initState() {
    super.initState();
    _loadFromRecord(widget.existingRecord);
  }

  @override
  void didUpdateWidget(LogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.existingRecord != widget.existingRecord) {
      _loadFromRecord(widget.existingRecord);
    }
  }

  void _loadFromRecord(OJTRecord? record) {
    if (record != null) {
      _timeIn1 = _parseTime(record.timeIn1);
      _timeOut1 = _parseTime(record.timeOut1);
      _timeIn2 = _parseTime(record.timeIn2);
      _timeOut2 = _parseTime(record.timeOut2);
      _isAbsent = record.isAbsent;
      _isHoliday = record.isHoliday;
    } else {
      _timeIn1 = null;
      _timeOut1 = null;
      _timeIn2 = null;
      _timeOut2 = null;
      _isAbsent = false;
      _isHoliday = false;
    }
    setState(() {});
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
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
    if (_isAbsent || _isHoliday) return 0.0;
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

  Future<void> _saveRecord() async {
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    double totalHours = _calculateTotalHours();
    double allowance = 0.0;
    if (!_isAbsent && !_isHoliday && settingsProvider.settings.allowancePerDay != null) {
      allowance = _calculateAllowance(totalHours, settingsProvider.settings.allowancePerDay!);
    }

    final record = OJTRecord(
      id: widget.existingRecord?.id,
      date: widget.selectedDate,
      timeIn1: _formatTime(_timeIn1),
      timeOut1: _formatTime(_timeOut1),
      timeIn2: _formatTime(_timeIn2),
      timeOut2: _formatTime(_timeOut2),
      isAbsent: _isAbsent,
      isHoliday: _isHoliday,
      totalHours: totalHours,
      allowanceEarned: allowance,
    );

    await recordProvider.saveOrUpdateRecord(record);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDate),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        // Checkboxes row
        Wrap(
          spacing: 16,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _isAbsent,
                  onChanged: (val) {
                    setState(() {
                      _isAbsent = val ?? false;
                      if (_isAbsent) {
                        _isHoliday = false;
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _isHoliday,
                  onChanged: (val) {
                    setState(() {
                      _isHoliday = val ?? false;
                      if (_isHoliday) {
                        _isAbsent = false;
                        _timeIn1 = null;
                        _timeOut1 = null;
                        _timeIn2 = null;
                        _timeOut2 = null;
                      }
                    });
                  },
                ),
                const Text('Mark as Holiday'),
              ],
            ),
          ],
        ),
        const Divider(),
        // AM Slot (only shown if not absent and not holiday)
        if (!_isAbsent && !_isHoliday) ...[
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
          // Preview total hours and allowance
          Text('Total hours: ${_calculateTotalHours().toStringAsFixed(2)}'),
          if (settings.allowancePerDay != null)
            Text('Allowance: ₱${_calculateAllowance(_calculateTotalHours(), settings.allowancePerDay!).toStringAsFixed(2)}'),
          const SizedBox(height: 8),
        ],
        ElevatedButton(
          onPressed: _saveRecord,
          child: const Text('Save'),
        ),
      ],
    );
  }
}