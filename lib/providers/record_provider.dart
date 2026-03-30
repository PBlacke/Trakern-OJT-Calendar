import 'package:flutter/material.dart';
import '../models/ojt_record.dart';
import '../database/db_helper.dart';

class RecordProvider extends ChangeNotifier {
  List<OJTRecord> _records = [];
  List<OJTRecord> get records => _records;

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> loadRecords() async {
    _records = await _db.getAllRecords();
    notifyListeners();
  }

  Future<void> saveOrUpdateRecord(OJTRecord record) async {
    await _db.upsertRecord(record);
    await loadRecords();
  }

  Future<OJTRecord?> getRecordForDate(DateTime date) async {
    return await _db.getRecordByDate(date);
  }

  Future<void> recalculateAllowance(double allowancePerDay) async {
  for (var record in _records) {
    double newAllowance = 0.0;
    if (!record.isAbsent && record.totalHours > 0) {
      newAllowance = (record.totalHours / 8).clamp(0.0, 1.0) * allowancePerDay;
    }
    if (record.allowanceEarned != newAllowance) {
      record.allowanceEarned = newAllowance;
      await _db.updateRecord(record);
    }
  }
  await loadRecords(); // refresh the list after updates
}
}