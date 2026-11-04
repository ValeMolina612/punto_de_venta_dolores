import 'package:sqflite/sqflite.dart';

import '../dominio/carrito.dart';
import '../dominio/excepciones.dart';
import '../dominio/venta.dart';

class RepositorioVentas {
  final Database db;

  RepositorioVentas(this.db);

  /// Cobra, guarda la venta y sus líneas, y descuenta el inventario.
  /// Todo sucede en una transacción.
  Future<Venta> cobrar(
    Carrito carrito,
    int pagoCentavos, {
    DateTime? fecha,
  }) async {
    carrito.cambio(pagoCentavos);
    final momento = fecha ?? DateTime.now();
    late int ventaId;

    await db.transaction((txn) async {
      for (final linea in carrito.lineas) {
        final filas = await txn.query(
          'productos',
          columns: ['existencias'],
          where: 'codigo = ?',
          whereArgs: [linea.producto.codigo],
        );
        final disponibles =
            filas.isEmpty ? 0 : filas.first['existencias'] as int;
        if (disponibles < linea.cantidad) {
          throw ExistenciasInsuficientesException(
            linea.producto.nombre,
            disponibles,
          );
        }
      }

      ventaId = await txn.insert('ventas', {
        'fecha': momento.toIso8601String(),
        'total_centavos': carrito.totalCentavos,
        'iva_centavos': carrito.ivaCentavos,
        'pago_centavos': pagoCentavos,
      });

      for (final linea in carrito.lineas) {
        await txn.insert('lineas_venta', {
          'venta_id': ventaId,
          'codigo': linea.producto.codigo,
          'nombre': linea.producto.nombre,
          'cantidad': linea.cantidad,
          'precio_centavos': linea.producto.precioCentavos,
        });
        await txn.rawUpdate(
          'UPDATE productos SET existencias = existencias - ? '
          'WHERE codigo = ?',
          [linea.cantidad, linea.producto.codigo],
        );
      }
    });

    return Venta(
      id: ventaId,
      fecha: momento,
      totalCentavos: carrito.totalCentavos,
      ivaCentavos: carrito.ivaCentavos,
      pagoCentavos: pagoCentavos,
      lineas: carrito.lineas
          .map(
            (linea) => LineaVenta(
              linea.producto.codigo,
              linea.producto.nombre,
              linea.cantidad,
              linea.producto.precioCentavos,
            ),
          )
          .toList(),
    );
  }

  /// Devuelve las ventas, el total y el IVA del día indicado.
  Future<ResumenDia> corteDelDia(DateTime dia) async {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fin = inicio.add(const Duration(days: 1));
    final filas = await db.rawQuery(
      '''
      SELECT COUNT(*) AS n,
             COALESCE(SUM(total_centavos), 0) AS total,
             COALESCE(SUM(iva_centavos), 0) AS iva
      FROM ventas
      WHERE fecha >= ? AND fecha < ?
      ''',
      [inicio.toIso8601String(), fin.toIso8601String()],
    );
    final resumen = filas.first;
    return ResumenDia(
      resumen['n'] as int,
      resumen['total'] as int,
      resumen['iva'] as int,
    );
  }

  /// Devuelve los productos más vendidos para ayudar a planear resurtidos.
  Future<List<Map<String, Object?>>> masVendidos({int limite = 5}) =>
      db.rawQuery(
        '''
        SELECT nombre, SUM(cantidad) AS unidades
        FROM lineas_venta
        GROUP BY codigo
        ORDER BY unidades DESC
        LIMIT ?
        ''',
        [limite],
      );
}
