import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/config/tracking_config.dart';

/// Local-only persistence for Phase 1.
///
/// Every table carries a `sync_status` (or is reachable from one that does) so
/// the Phase 2 sync worker can push pending rows without a schema rewrite.
class AppDatabase {
  AppDatabase._()
      : _factory = null,
        _path = null;

  /// Test seam: lets widget/unit tests use an in-memory FFI database without
  /// touching path_provider or the real device database.
  AppDatabase.forTesting({DatabaseFactory? factory, String? path})
      : _factory = factory ?? databaseFactoryFfi,
        _path = path ?? inMemoryDatabasePath;

  static final AppDatabase instance = AppDatabase._();

  final DatabaseFactory? _factory;
  final String? _path;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      throw UnsupportedError('PropCare Track persistence requires a mobile or desktop build.');
    }

    if (_factory != null) {
      return _factory.openDatabase(
        _path!,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: _onCreate,
          onOpen: _onOpen,
        ),
      );
    }

    String path;
    if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dir = await getApplicationSupportDirectory();
      path = p.join(dir.path, 'propcare_track.db');
    } else {
      path = p.join(await getDatabasesPath(), 'propcare_track.db');
    }

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM employees'),
      );
      if ((count ?? 0) == 0) {
        await _seed(db);
      }
      final completedCount = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM attendance_records WHERE check_out_at IS NOT NULL"),
      );
      if ((completedCount ?? 0) == 0) {
        await _seedPastAttendance(db);
      }
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE employees (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        department TEXT,
        designation TEXT,
        joined_at TEXT,
        avatar_seed TEXT,
        password_hash TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE office_config (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE assigned_sites (
        id TEXT PRIMARY KEY,
        code TEXT,
        name TEXT NOT NULL,
        address TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE attendance_records (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        office_id TEXT NOT NULL,
        check_in_at INTEGER NOT NULL,
        check_out_at INTEGER,
        check_in_lat REAL NOT NULL,
        check_in_lng REAL NOT NULL,
        check_in_accuracy REAL NOT NULL,
        check_in_battery INTEGER NOT NULL,
        check_out_lat REAL,
        check_out_lng REAL,
        check_out_accuracy REAL,
        check_out_battery INTEGER,
        status TEXT NOT NULL DEFAULT 'active',
        total_duration_seconds INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at INTEGER NOT NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_attendance_emp ON attendance_records(employee_id, check_in_at)');
    batch.execute('CREATE INDEX idx_attendance_status ON attendance_records(employee_id, status)');

    batch.execute('''
      CREATE TABLE tracking_sessions (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        attendance_id TEXT NOT NULL,
        office_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        status TEXT NOT NULL DEFAULT 'active',
        platform TEXT NOT NULL,
        start_battery INTEGER NOT NULL,
        end_battery INTEGER,
        last_latitude REAL,
        last_longitude REAL,
        last_update_at INTEGER,
        distance_meters REAL NOT NULL DEFAULT 0,
        location_count INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at INTEGER NOT NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_sessions_emp ON tracking_sessions(employee_id, started_at)');
    batch.execute('CREATE INDEX idx_sessions_status ON tracking_sessions(employee_id, status)');

    batch.execute('''
      CREATE TABLE location_records (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL NOT NULL,
        speed REAL,
        bearing REAL,
        battery INTEGER NOT NULL,
        platform TEXT NOT NULL,
        movement_status TEXT NOT NULL DEFAULT 'unknown',
        recorded_at INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'native',
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    batch.execute('CREATE INDEX idx_locations_session ON location_records(session_id, recorded_at)');
    batch.execute('CREATE INDEX idx_locations_emp ON location_records(employee_id, recorded_at)');

    batch.execute('''
      CREATE TABLE stationary_events (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        start_at INTEGER NOT NULL,
        end_at INTEGER,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        accuracy REAL NOT NULL,
        battery INTEGER,
        status TEXT NOT NULL DEFAULT 'active',
        radius_meters REAL NOT NULL DEFAULT 30,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    batch.execute('CREATE INDEX idx_stationary_session ON stationary_events(session_id, start_at)');
    batch.execute('CREATE INDEX idx_stationary_emp ON stationary_events(employee_id, start_at)');

    batch.execute('''
      CREATE TABLE site_attendance (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        site_id TEXT NOT NULL,
        site_name TEXT NOT NULL,
        check_in_at INTEGER NOT NULL,
        check_out_at INTEGER,
        check_in_lat REAL NOT NULL,
        check_in_lng REAL NOT NULL,
        check_in_accuracy REAL NOT NULL,
        check_in_battery INTEGER NOT NULL,
        check_out_lat REAL,
        check_out_lng REAL,
        check_out_accuracy REAL,
        check_out_battery INTEGER,
        duration_seconds INTEGER,
        status TEXT NOT NULL DEFAULT 'active',
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    batch.execute('CREATE INDEX idx_site_att_session ON site_attendance(session_id, check_in_at)');
    batch.execute('CREATE INDEX idx_site_att_emp ON site_attendance(employee_id, check_in_at)');

    batch.execute('''
      CREATE TABLE battery_logs (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        session_id TEXT,
        level INTEGER NOT NULL,
        recorded_at INTEGER NOT NULL,
        context TEXT NOT NULL DEFAULT 'tracking'
      )
    ''');
    batch.execute('CREATE INDEX idx_battery_emp ON battery_logs(employee_id, recorded_at)');

    batch.execute('''
      CREATE TABLE app_meta (
        meta_key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await batch.commit(noResult: true);
    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();

    for (final employee in AppConfig.demoEmployees) {
      batch.insert(
        'employees',
        {
          'id': employee.id,
          'code': employee.code,
          'name': employee.name,
          'email': employee.email,
          'phone': employee.phone,
          'department': employee.department,
          'designation': employee.designation,
          'joined_at': employee.joinedAt,
          'avatar_seed': employee.id.hashCode.isEven ? 'mint' : 'coral',
          'password_hash': hashPassword(employee.code, AppConfig.demoPassword),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert('office_config', AppConfig.office.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);

    for (var i = 0; i < AppConfig.sites.length; i++) {
      final site = AppConfig.sites[i];
      batch.insert(
        'assigned_sites',
        {
          ...site.toMap(),
          'sort_order': i,
          'is_active': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert('app_meta', {'meta_key': 'seeded_at', 'value': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.ignore);

    await batch.commit(noResult: true);
    await _seedPastAttendance(db);
  }

  Future<void> _seedPastAttendance(Database db) async {
    try {
      final now = DateTime.now();
      final employees = await db.query('employees');
      if (employees.isEmpty) return;

      final empId = employees.first['id'] as String;
      final officeRow = (await db.query('office_config')).firstOrNull;
      final officeId = (officeRow?['id'] as String?) ?? 'chennai-hq';

      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      final batch = db.batch();

      // ── Yesterday Session 1 (Morning Shift: 09:15 AM - 01:30 PM)
      final ySess1Start = DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 15);
      final ySess1End = DateTime(yesterday.year, yesterday.month, yesterday.day, 13, 30);
      const yS1AttId = 'att_yesterday_1';
      const yS1SessId = 'sess_yesterday_1';

      batch.insert(
        'attendance_records',
        {
          'id': yS1AttId,
          'employee_id': empId,
          'session_id': yS1SessId,
          'office_id': officeId,
          'check_in_at': ySess1Start.millisecondsSinceEpoch,
          'check_out_at': ySess1End.millisecondsSinceEpoch,
          'check_in_lat': 12.9815,
          'check_in_lng': 80.2180,
          'check_in_accuracy': 8.0,
          'check_in_battery': 95,
          'check_out_lat': 12.9150,
          'check_out_lng': 80.1250,
          'check_out_accuracy': 6.0,
          'check_out_battery': 80,
          'status': 'completed',
          'total_duration_seconds': ySess1End.difference(ySess1Start).inSeconds,
          'sync_status': 'synced',
          'created_at': ySess1Start.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'tracking_sessions',
        {
          'id': yS1SessId,
          'employee_id': empId,
          'attendance_id': yS1AttId,
          'office_id': officeId,
          'started_at': ySess1Start.millisecondsSinceEpoch,
          'ended_at': ySess1End.millisecondsSinceEpoch,
          'status': 'completed',
          'platform': 'ios',
          'start_battery': 95,
          'end_battery': 80,
          'last_latitude': 12.9150,
          'last_longitude': 80.1250,
          'last_update_at': ySess1End.millisecondsSinceEpoch,
          'distance_meters': 14250.0,
          'location_count': 180,
          'sync_status': 'synced',
          'created_at': ySess1Start.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Yesterday Session 1 Site Visit (Casagrand Suncity)
      batch.insert(
        'site_attendance',
        {
          'id': 'site_att_y_1',
          'employee_id': empId,
          'session_id': yS1SessId,
          'site_id': 'casagrand-suncity',
          'site_name': 'Casagrand Suncity',
          'check_in_at': DateTime(yesterday.year, yesterday.month, yesterday.day, 10, 30).millisecondsSinceEpoch,
          'check_out_at': DateTime(yesterday.year, yesterday.month, yesterday.day, 12, 45).millisecondsSinceEpoch,
          'check_in_lat': 12.9150,
          'check_in_lng': 80.1250,
          'check_in_accuracy': 5.0,
          'check_out_lat': 12.9150,
          'check_out_lng': 80.1250,
          'check_out_accuracy': 5.0,
          'status': 'completed',
          'duration_seconds': 8100,
          'sync_status': 'synced',
          'created_at': ySess1Start.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // ── Yesterday Session 2 (Afternoon Shift: 02:45 PM - 06:45 PM)
      final ySess2Start = DateTime(yesterday.year, yesterday.month, yesterday.day, 14, 45);
      final ySess2End = DateTime(yesterday.year, yesterday.month, yesterday.day, 18, 45);
      const yS2AttId = 'att_yesterday_2';
      const yS2SessId = 'sess_yesterday_2';

      batch.insert(
        'attendance_records',
        {
          'id': yS2AttId,
          'employee_id': empId,
          'session_id': yS2SessId,
          'office_id': officeId,
          'check_in_at': ySess2Start.millisecondsSinceEpoch,
          'check_out_at': ySess2End.millisecondsSinceEpoch,
          'check_in_lat': 12.9150,
          'check_in_lng': 80.1250,
          'check_in_accuracy': 7.0,
          'check_in_battery': 78,
          'check_out_lat': 12.9815,
          'check_out_lng': 80.2180,
          'check_out_accuracy': 5.0,
          'check_out_battery': 62,
          'status': 'completed',
          'total_duration_seconds': ySess2End.difference(ySess2Start).inSeconds,
          'sync_status': 'synced',
          'created_at': ySess2Start.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'tracking_sessions',
        {
          'id': yS2SessId,
          'employee_id': empId,
          'attendance_id': yS2AttId,
          'office_id': officeId,
          'started_at': ySess2Start.millisecondsSinceEpoch,
          'ended_at': ySess2End.millisecondsSinceEpoch,
          'status': 'completed',
          'platform': 'ios',
          'start_battery': 78,
          'end_battery': 62,
          'last_latitude': 12.9815,
          'last_longitude': 80.2180,
          'last_update_at': ySess2End.millisecondsSinceEpoch,
          'distance_meters': 11800.0,
          'location_count': 150,
          'sync_status': 'synced',
          'created_at': ySess2Start.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Yesterday Session 2 Site Visit (Casagrand First City)
      batch.insert(
        'site_attendance',
        {
          'id': 'site_att_y_2',
          'employee_id': empId,
          'session_id': yS2SessId,
          'site_id': 'casagrand-firstcity',
          'site_name': 'Casagrand First City',
          'check_in_at': DateTime(yesterday.year, yesterday.month, yesterday.day, 15, 30).millisecondsSinceEpoch,
          'check_out_at': DateTime(yesterday.year, yesterday.month, yesterday.day, 17, 45).millisecondsSinceEpoch,
          'check_in_lat': 12.8900,
          'check_in_lng': 80.2000,
          'check_in_accuracy': 6.0,
          'check_out_lat': 12.8900,
          'check_out_lng': 80.2000,
          'check_out_accuracy': 6.0,
          'status': 'completed',
          'duration_seconds': 8100,
          'sync_status': 'synced',
          'created_at': ySess2Start.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // ── Two Days Ago (Full Day Shift: 09:30 AM - 06:15 PM)
      final d2Start = DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day, 9, 30);
      final d2End = DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day, 18, 15);
      const d2AttId = 'att_two_days_ago';
      const d2SessId = 'sess_two_days_ago';

      batch.insert(
        'attendance_records',
        {
          'id': d2AttId,
          'employee_id': empId,
          'session_id': d2SessId,
          'office_id': officeId,
          'check_in_at': d2Start.millisecondsSinceEpoch,
          'check_out_at': d2End.millisecondsSinceEpoch,
          'check_in_lat': 12.9815,
          'check_in_lng': 80.2180,
          'check_in_accuracy': 6.0,
          'check_in_battery': 98,
          'check_out_lat': 12.9815,
          'check_out_lng': 80.2180,
          'check_out_accuracy': 5.0,
          'check_out_battery': 55,
          'status': 'completed',
          'total_duration_seconds': d2End.difference(d2Start).inSeconds,
          'sync_status': 'synced',
          'created_at': d2Start.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'tracking_sessions',
        {
          'id': d2SessId,
          'employee_id': empId,
          'attendance_id': d2AttId,
          'office_id': officeId,
          'started_at': d2Start.millisecondsSinceEpoch,
          'ended_at': d2End.millisecondsSinceEpoch,
          'status': 'completed',
          'platform': 'ios',
          'start_battery': 98,
          'end_battery': 55,
          'last_latitude': 12.9815,
          'last_longitude': 80.2180,
          'last_update_at': d2End.millisecondsSinceEpoch,
          'distance_meters': 22400.0,
          'location_count': 260,
          'sync_status': 'synced',
          'created_at': d2Start.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await batch.commit(noResult: true);
    } catch (_) {}
  }

  static String hashPassword(String code, String password) {
    return sha256.convert(utf8.encode('propcare::${code.toLowerCase()}::$password')).toString();
  }
}
