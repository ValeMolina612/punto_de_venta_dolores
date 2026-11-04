import 'package:sqflite/sqflite.dart';

import '../dominio/excepciones.dart';
import '../dominio/producto.dart';

class RepositorioProductos {
  final Database db;

  RepositorioProductos(this.db);

  Future<Producto> agregar(Producto producto) async {
    try {
      final id = await db.insert('productos', producto.aMapa());
      return producto.copiarCon(id: id);
    } on DatabaseException {
      final existentes = await db.query(
        'productos',
        columns: ['codigo'],
        where: 'codigo = ?',
        whereArgs: [producto.codigo],
      );
      if (existentes.isNotEmpty) {
        throw CodigoDuplicadoException(producto.codigo);
      }
      rethrow;
    }
  }

  Future<List<Producto>> listar({String filtro = ''}) async {
    final productos = await db.query(
      'productos',
      where: filtro.isEmpty ? null : 'codigo LIKE ? OR nombre LIKE ?',
      whereArgs: filtro.isEmpty ? null : ['%$filtro%', '%$filtro%'],
      orderBy: 'nombre COLLATE NOCASE',
    );
    return productos.map((producto) => Producto.desdeMapa(producto)).toList();
  }
}
