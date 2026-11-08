import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TaskDB {
  static Database? _db;

  static Future<Database> get db async => _db ??= await _init();

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'tasks.db');
    return openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, due_date TEXT, is_done INTEGER NOT NULL DEFAULT 0)');
      await db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, amount REAL NOT NULL, note TEXT, date TEXT NOT NULL)');
    });
  }

  // Tasks
  static Future<List<Map<String, dynamic>>> getTasks() async =>
      (await db).query('tasks', orderBy: 'is_done ASC, due_date ASC');

  static Future<int> addTask(String title, String? dueDate) async =>
      (await db).insert('tasks', {'title': title, 'due_date': dueDate, 'is_done': 0});

  static Future<int> toggleTask(int id, int isDone) async =>
      (await db).update('tasks', {'is_done': isDone}, where: 'id = ?', whereArgs: [id]);

  static Future<int> deleteTask(int id) async =>
      (await db).delete('tasks', where: 'id = ?', whereArgs: [id]);

  // Budget transactions
  static Future<List<Map<String, dynamic>>> getTransactions() async =>
      (await db).query('transactions', orderBy: 'id DESC');

  static Future<int> addTransaction(String type, double amount, String note) async =>
      (await db).insert('transactions',
          {'type': type, 'amount': amount, 'note': note, 'date': DateTime.now().toIso8601String()});

  static Future<int> deleteTransaction(int id) async =>
      (await db).delete('transactions', where: 'id = ?', whereArgs: [id]);
}
