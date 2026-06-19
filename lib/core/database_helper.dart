import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../modules/map/model/alarm_history_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('alarm_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        startName TEXT NOT NULL,
        endName TEXT NOT NULL,
        totalTimeSeconds INTEGER NOT NULL,
        distanceMeters REAL NOT NULL,
        averageSpeed REAL NOT NULL,
        routeCoordinates TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertHistory(AlarmHistoryModel history) async {
    final db = await instance.database;
    return await db.insert('history', history.toMap());
  }

  Future<int> updateHistory(AlarmHistoryModel history) async {
    final db = await instance.database;
    return await db.update(
      'history',
      history.toMap(),
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }

  Future<List<AlarmHistoryModel>> getAllCompletedHistories() async {
    final db = await instance.database;
    final result = await db.query(
      'history',
      where: 'status = ?',
      whereArgs: ['COMPLETED'],
      orderBy: 'date DESC',
    );
    return result.map((json) => AlarmHistoryModel.fromMap(json)).toList();
  }

  Future<int> deleteHistory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<AlarmHistoryModel?> getActiveHistory() async {
    final db = await instance.database;
    final result = await db.query(
      'history',
      where: 'status = ?',
      whereArgs: ['IN_PROGRESS'],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return AlarmHistoryModel.fromMap(result.first);
    }
    return null;
  }
}
