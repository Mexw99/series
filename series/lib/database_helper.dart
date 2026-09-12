import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'main.dart';

class DatabaseHelper {
  static Database? _db;

  // เปิดฐานข้อมูล
  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'series_empty.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE series_items('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'title TEXT NOT NULL, '
          'content TEXT NOT NULL, '
          'date TEXT NOT NULL, '
          'rating REAL NOT NULL, '
          'image TEXT NOT NULL)',
        );
      },
    );

    return _db!;
  }

  // เพิ่มซีรีส์
  static Future<void> insert(SeriesItem item) async {
    final db = await database;
    await db.insert('series_items', item.toMap());
  }

  // อ่านซีรีส์ทั้งหมด
  static Future<List<SeriesItem>> getAll() async {
    final db = await database;
    final maps = await db.query('series_items', orderBy: 'id DESC');

    return maps.map((map) => SeriesItem.fromMap(map)).toList();
  }

  // แก้ไขซีรีส์
  static Future<void> update(SeriesItem item) async {
    final db = await database;

    await db.update(
      'series_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // ลบซีรีส์
  static Future<void> delete(int id) async {
    final db = await database;

    await db.delete('series_items', where: 'id = ?', whereArgs: [id]);
  }
}
