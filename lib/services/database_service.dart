import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_result.dart';
import '../models/risk_analysis_result.dart';
import 'risk_engine.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'scan_history';
  static const int _databaseVersion = 2; // Upgraded from 1 to 2

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qrshield.db');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTable,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE $_tableName ADD COLUMN risk_analysis TEXT');
          } catch (e) {
            // Drop and recreate table if schema migration fails
            await db.execute('DROP TABLE IF EXISTS $_tableName');
            await _createTable(db, newVersion);
          }
        }
      },
    );
  }

  static Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        status TEXT NOT NULL,
        score INTEGER NOT NULL,
        confidence REAL NOT NULL,
        reasons TEXT NOT NULL,
        features TEXT NOT NULL,
        risk_analysis TEXT,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  static Future<int> insertScanResult(ScanResult result) async {
    print("SAVE HISTORY CALLED");
    final db = await database;

    // Check for duplicate saved within the last 5 seconds
    try {
      final List<Map<String, dynamic>> existing = await db.query(
        _tableName,
        where: 'url = ?',
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final lastTimestamp = DateTime.parse(existing[0]['timestamp']);
        final difference = DateTime.now().difference(lastTimestamp);
        if (difference.inSeconds < 5) {
          print("DATABASE INSERT SKIPPED: Duplicate URL scanned within last 5 seconds.");
          return -1;
        }
      }
    } catch (e) {
      print("Error checking duplicates in database: $e");
    }

    print("DATABASE INSERT EXECUTED");
    return await db.insert(
      _tableName,
      {
        'url': result.url,
        'status': result.status,
        'score': result.score,
        'confidence': result.confidence,
        'reasons': result.reasons.join('|'),
        'features': jsonEncode(result.features.toJson()),
        'risk_analysis': result.riskAnalysis != null ? jsonEncode(result.riskAnalysis!.toJson()) : null,
        'timestamp': result.timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ScanResult>> getAllScanResults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      final reasons = maps[i]['reasons'].toString().split('|').where((r) => r.isNotEmpty).toList();
      final featuresJson = maps[i]['features'].toString();
      
      Map<String, dynamic> featuresMap = {};
      try {
        featuresMap = jsonDecode(featuresJson);
      } catch (e) {
        // Fallback for old database formats
        try {
          var mutableFeaturesJson = featuresJson.replaceAll('{', '').replaceAll('}', '');
          final pairs = mutableFeaturesJson.split(',');
          for (final pair in pairs) {
            final keyValue = pair.split(':');
            if (keyValue.length == 2) {
              final key = keyValue[0].trim().replaceAll(' ', '_');
              final value = keyValue[1].trim().toLowerCase() == 'true';
              featuresMap[key] = value;
            }
          }
        } catch (_) {
          featuresMap = {
            'has_https': false,
            'has_ip': false,
            'long_url': false,
            'suspicious_keyword': false,
          };
        }
      }

      RiskAnalysisResult? riskAnalysis;
      if (maps[i]['risk_analysis'] != null) {
        try {
          riskAnalysis = RiskAnalysisResult.fromJson(jsonDecode(maps[i]['risk_analysis'].toString()));
        } catch (e) {
          // silent fail
        }
      }

      return ScanResult(
        url: maps[i]['url'],
        status: maps[i]['status'],
        score: maps[i]['score'],
        confidence: maps[i]['confidence'],
        reasons: reasons,
        recommendation: '',
        features: SecurityFeatures.fromJson(featuresMap),
        riskAnalysis: riskAnalysis,
        timestamp: DateTime.parse(maps[i]['timestamp']),
      );
    });
  }

  static Future<ScanResult?> getScanResultByUrl(String url) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'url = ?',
      whereArgs: [url],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final timestampStr = maps[0]['timestamp'].toString();
    final scanTime = DateTime.parse(timestampStr);
    final now = DateTime.now();

    // Cache Expiration Validation: 24-hour expiration window
    if (now.difference(scanTime).inHours >= 24) {
      return null;
    }

    final i = 0;
    final reasons = maps[i]['reasons'].toString().split('|').where((r) => r.isNotEmpty).toList();
    final featuresJson = maps[i]['features'].toString();
    
    Map<String, dynamic> featuresMap = {};
    try {
      featuresMap = jsonDecode(featuresJson);
    } catch (e) {
      // Fallback
    }

    RiskAnalysisResult? riskAnalysis;
    if (maps[i]['risk_analysis'] != null) {
      try {
        riskAnalysis = RiskAnalysisResult.fromJson(jsonDecode(maps[i]['risk_analysis'].toString()));
      } catch (e) {
        // silent fail
      }
    }

    // Engine version validation: invalidate cache if saved version is outdated
    if (riskAnalysis != null && riskAnalysis.engineVersion != RiskEngine.currentVersion) {
      return null;
    }

    return ScanResult(
      url: maps[i]['url'],
      status: maps[i]['status'],
      score: maps[i]['score'],
      confidence: maps[i]['confidence'],
      reasons: reasons,
      recommendation: '',
      features: SecurityFeatures.fromJson(featuresMap),
      riskAnalysis: riskAnalysis,
      timestamp: scanTime,
    );
  }

  static Future<int> deleteScanResult(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete(_tableName);
  }

  static Future<int> getHistoryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<Map<String, int>> getScanStats() async {
    final db = await database;
    final totalResult = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    final safeResult = await db.rawQuery("SELECT COUNT(*) FROM $_tableName WHERE UPPER(status) = 'SAFE'");
    final blockedResult = await db.rawQuery("SELECT COUNT(*) FROM $_tableName WHERE UPPER(status) = 'SUSPICIOUS' OR UPPER(status) = 'PHISHING' OR UPPER(status) = 'DANGEROUS' OR UPPER(status) = 'LOW_RISK'");
    
    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'safe': Sqflite.firstIntValue(safeResult) ?? 0,
      'blocked': Sqflite.firstIntValue(blockedResult) ?? 0,
    };
  }

  static Future<ScanResult?> getLastScanResult() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    
    final i = 0;
    final reasons = maps[i]['reasons'].toString().split('|').where((r) => r.isNotEmpty).toList();
    final featuresJson = maps[i]['features'].toString();
    
    Map<String, dynamic> featuresMap = {};
    try {
      featuresMap = jsonDecode(featuresJson);
    } catch (e) {
      // fallback
    }

    RiskAnalysisResult? riskAnalysis;
    if (maps[i]['risk_analysis'] != null) {
      try {
        riskAnalysis = RiskAnalysisResult.fromJson(jsonDecode(maps[i]['risk_analysis'].toString()));
      } catch (e) {
        // silent fail
      }
    }

    return ScanResult(
      url: maps[i]['url'],
      status: maps[i]['status'],
      score: maps[i]['score'],
      confidence: maps[i]['confidence'],
      reasons: reasons,
      recommendation: '',
      features: SecurityFeatures.fromJson(featuresMap),
      riskAnalysis: riskAnalysis,
      timestamp: DateTime.parse(maps[i]['timestamp']),
    );
  }
}
