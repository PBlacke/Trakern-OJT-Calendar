import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ojt_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'ojt_calendar.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

    Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE records ADD COLUMN isHoliday INTEGER DEFAULT 0');
    } 
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE,
        timeIn1 TEXT,
        timeOut1 TEXT,
        timeIn2 TEXT,
        timeOut2 TEXT,
        isAbsent INTEGER,
        isHoliday INTEGER,
        totalHours REAL,
        allowanceEarned REAL
      )
    ''');
  }



  Future<void> upsertRecord(OJTRecord record) async {
    final db = await database;
    await db.insert(
      'records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<OJTRecord?> getRecordByDate(DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: 'date = ?',
      whereArgs: [date.toIso8601String()],
    );
    if (maps.isNotEmpty) return OJTRecord.fromMap(maps.first);
    return null;
  }

  Future<List<OJTRecord>> getAllRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('records', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => OJTRecord.fromMap(maps[i]));
  }

  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateRecord(OJTRecord record) async {
    final db = await database;
    await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }
}