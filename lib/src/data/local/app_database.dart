import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _dbName = 'debt_tracker.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE plans (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            notes TEXT NOT NULL,
            category TEXT NOT NULL,
            amount_cents INTEGER NOT NULL,
            start_date TEXT NOT NULL,
            due_day INTEGER NOT NULL,
            kind TEXT NOT NULL,
            recurrence_type TEXT NOT NULL,
            custom_interval_days INTEGER,
            custom_interval_months INTEGER,
            duration_type TEXT NOT NULL,
            duration_value INTEGER,
            end_date TEXT,
            affects_salary INTEGER NOT NULL,
            manual_closed INTEGER NOT NULL,
            archived INTEGER NOT NULL,
            retention_until TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await database.execute('''
          CREATE TABLE reminders (
            id TEXT PRIMARY KEY,
            plan_id TEXT NOT NULL,
            type TEXT NOT NULL,
            offset_days INTEGER,
            hour INTEGER NOT NULL DEFAULT 9,
            minute INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY(plan_id) REFERENCES plans(id) ON DELETE CASCADE
          )
        ''');

        await database.execute('''
          CREATE TABLE occurrences (
            id TEXT PRIMARY KEY,
            plan_id TEXT NOT NULL,
            sequence_index INTEGER NOT NULL,
            due_date TEXT NOT NULL,
            amount_cents INTEGER NOT NULL,
            paid_amount_cents INTEGER NOT NULL,
            status TEXT NOT NULL,
            UNIQUE(plan_id, sequence_index),
            FOREIGN KEY(plan_id) REFERENCES plans(id) ON DELETE CASCADE
          )
        ''');

        await database.execute('''
          CREATE TABLE payments (
            id TEXT PRIMARY KEY,
            plan_id TEXT NOT NULL,
            occurrence_id TEXT NOT NULL,
            amount_cents INTEGER NOT NULL,
            paid_at TEXT NOT NULL,
            note TEXT NOT NULL,
            FOREIGN KEY(plan_id) REFERENCES plans(id) ON DELETE CASCADE,
            FOREIGN KEY(occurrence_id) REFERENCES occurrences(id) ON DELETE CASCADE
          )
        ''');

        await database.execute('''
          CREATE TABLE salary_configs (
            id TEXT PRIMARY KEY,
            month_key TEXT NOT NULL UNIQUE,
            amount_cents INTEGER NOT NULL,
            salary_day INTEGER NOT NULL
          )
        ''');

        await database.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            currency_code TEXT NOT NULL,
            theme_mode TEXT NOT NULL,
            notifications_enabled INTEGER NOT NULL,
            accent_theme TEXT NOT NULL
          )
        ''');

        await database.insert('settings', {
          'id': 1,
          'currency_code': 'EUR',
          'theme_mode': 'system',
          'notifications_enabled': 1,
          'accent_theme': 'ocean',
        });
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE plans ADD COLUMN custom_interval_months INTEGER',
          );
          await database.execute(
            'ALTER TABLE plans ADD COLUMN retention_until TEXT',
          );
          await database.execute(
            'ALTER TABLE reminders ADD COLUMN hour INTEGER NOT NULL DEFAULT 9',
          );
          await database.execute(
            'ALTER TABLE reminders ADD COLUMN minute INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await database.execute(
            "ALTER TABLE settings ADD COLUMN accent_theme TEXT NOT NULL DEFAULT 'ocean'",
          );
        }
      },
    );

    return _db!;
  }
}
