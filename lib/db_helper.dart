import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> initDb() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'cadastro.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT,
            telefone TEXT,
            endereco TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE servicos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente_id INTEGER,
            descricao TEXT,
            data TEXT,
            horas REAL,
            valor_unitario REAL,
            valor_total REAL,
            FOREIGN KEY(cliente_id) REFERENCES clientes(id)
          )
        ''');
      },
    );
  }
}
