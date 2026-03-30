class OJTRecord {
  int? id;
  DateTime date;
  String? timeIn1;
  String? timeOut1;
  String? timeIn2;
  String? timeOut2;
  bool isAbsent;
  bool isHoliday;
  double totalHours;
  double allowanceEarned;

  OJTRecord({
    this.id,
    required this.date,
    this.timeIn1,
    this.timeOut1,
    this.timeIn2,
    this.timeOut2,
    this.isAbsent = false,
    this.isHoliday = false,   // default false
    this.totalHours = 0.0,
    this.allowanceEarned = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'timeIn1': timeIn1,
      'timeOut1': timeOut1,
      'timeIn2': timeIn2,
      'timeOut2': timeOut2,
      'isAbsent': isAbsent ? 1 : 0,
      'isHoliday': isHoliday ? 1 : 0,
      'totalHours': totalHours,
      'allowanceEarned': allowanceEarned,
    };
  }

  factory OJTRecord.fromMap(Map<String, dynamic> map) {
    return OJTRecord(
      id: map['id'],
      date: DateTime.parse(map['date']),
      timeIn1: map['timeIn1'],
      timeOut1: map['timeOut1'],
      timeIn2: map['timeIn2'],
      timeOut2: map['timeOut2'],
      isAbsent: (map['isAbsent'] as int?) == 1,
      isHoliday: (map['isHoliday'] as int?) == 1,   // safe with null
      totalHours: (map['totalHours'] as num?)?.toDouble() ?? 0.0,
      allowanceEarned: (map['allowanceEarned'] as num?)?.toDouble() ?? 0.0,
    );
  }
}