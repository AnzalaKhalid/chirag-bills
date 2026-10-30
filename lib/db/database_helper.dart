import 'package:bills/models/bills_model.dart';
import 'package:bills/models/transporter_model.dart';
import 'package:bills/models/bowser_bill_model.dart'; // <-- NEW IMPORT
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bills.db');
    debugPrint('📂 DB path: $path');
    return await openDatabase(
      path,
      version: 3, // <-- UPGRADED TO 3
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Transporters
    await db.execute('''
      CREATE TABLE transporters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        createdAt TEXT
      );
    ''');

    // 2. Normal Bills
    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transporterId INTEGER,
        vehicleNo TEXT,
        loadingDate TEXT,
        unloadingDate TEXT,
        loadingWeight REAL,
        loadingStation TEXT,
        ratePerMt REAL,
        unloadingWeight REAL,
        unloadingStation TEXT,
        gainLoss REAL,
        gainLossRate REAL,
        tripAmount REAL,
        remainingAmount REAL,
        toPay REAL
      );
    ''');

    // 3. Bowser Bills
    await _createBowserTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transporters (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          createdAt TEXT
        );
      ''');
      try {
        await db.execute('ALTER TABLE bills ADD COLUMN transporterId INTEGER;');
      } catch (e) {
        debugPrint('Column already exists: $e');
      }
    }
    
    if (oldVersion < 3) {
      await _createBowserTable(db);
    }
  }

  Future<void> _createBowserTable(Database db) async {
    await db.execute('''
      CREATE TABLE bowser_bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transporterId INTEGER,
        vehicleNo TEXT,
        loadWeight REAL,
        unloadWeight REAL,
        rent REAL,
        carRent REAL,
        totalRent REAL,
        primeMoverRent REAL,
        bowzerRent REAL,
        createdAt TEXT
      );
    ''');
  }

  // --- TRANSPORTER METHODS ---
  Future<int> insertTransporter(TransporterModel transporter) async {
    final db = await database;
    return await db.insert('transporters', transporter.toMap());
  }

  Future<List<TransporterModel>> getTransporters() async {
    final db = await database;
    final maps = await db.query('transporters', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => TransporterModel.fromMap(maps[i]));
  }

  Future<void> deleteTransporter(int id) async {
    final db = await database;
    await db.delete('transporters', where: 'id = ?', whereArgs: [id]);
  }

  // --- NORMAL BILL METHODS ---
  Future<int> insertBill(BillModel bill) async {
    final db = await database;
    return await db.insert('bills', bill.toMap());
  }

  Future<void> deleteBill(int id) async {
    final db = await database;
    await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBill(BillModel bill) async {
    final db = await database;
    await db.update('bills', bill.toMap(), where: 'id = ?', whereArgs: [bill.id]);
  }

  Future<List<BillModel>> getBills() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT b.*, t.name as transporterName 
      FROM bills b 
      LEFT JOIN transporters t ON b.transporterId = t.id 
      ORDER BY b.id DESC
    ''');
    return List.generate(maps.length, (i) => BillModel.fromMap(maps[i]));
  }

  Future<List<BillModel>> getBillsByTransporter(int transporterId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT b.*, t.name as transporterName 
      FROM bills b 
      LEFT JOIN transporters t ON b.transporterId = t.id 
      WHERE b.transporterId = ? 
      ORDER BY b.id DESC
    ''', [transporterId]);
    return List.generate(maps.length, (i) => BillModel.fromMap(maps[i]));
  }

  // --- BOWSER BILL METHODS ---
  Future<int> insertBowserBill(BowserBillModel bill) async {
    final db = await database;
    return await db.insert('bowser_bills', bill.toMap());
  }

  Future<void> updateBowserBill(BowserBillModel bill) async {
    final db = await database;
    await db.update(
      'bowser_bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }
  
  Future<void> deleteBowserBill(int id) async {
    final db = await database;
    await db.delete('bowser_bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BowserBillModel>> getBowserBills() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT b.*, t.name as transporterName 
      FROM bowser_bills b 
      LEFT JOIN transporters t ON b.transporterId = t.id 
      ORDER BY b.id DESC
    ''');
    return List.generate(maps.length, (i) => BowserBillModel.fromMap(maps[i]));
  }

  Future<List<BowserBillModel>> getBowserBillsByTransporter(int transporterId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT b.*, t.name as transporterName 
      FROM bowser_bills b 
      LEFT JOIN transporters t ON b.transporterId = t.id 
      WHERE b.transporterId = ? 
      ORDER BY b.id DESC
    ''', [transporterId]);
    return List.generate(maps.length, (i) => BowserBillModel.fromMap(maps[i]));
  }
}