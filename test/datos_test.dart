import 'package:flutter_test/flutter_test.dart';
import 'package:punto_venta_dolores/datos/base_datos.dart';
import 'package:punto_venta_dolores/datos/repositorio_productos.dart';
import 'package:punto_venta_dolores/datos/repositorio_ventas.dart';
import 'package:punto_venta_dolores/dominio/carrito.dart';
import 'package:punto_venta_dolores/dominio/excepciones.dart';
import 'package:punto_venta_dolores/dominio/producto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late RepositorioProductos productos;
  late RepositorioVentas ventas;
  late Database database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await BaseDatos.abrir(ruta: inMemoryDatabasePath);
    productos = RepositorioProductos(database);
    ventas = RepositorioVentas(database);
    await productos.agregar(
      const Producto(
        codigo: 'NV-001',
        nombre: 'Nieve de limón',
        precioCentavos: 2500,
        existencias: 5,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('agrega productos y permite filtrarlos', () async {
    final resultado = await productos.listar(filtro: 'limón');

    expect(resultado, hasLength(1));
    expect(resultado.single.codigo, 'NV-001');
  });

  test('rechaza códigos duplicados', () async {
    await expectLater(
      productos.agregar(
        const Producto(
          codigo: 'NV-001',
          nombre: 'Otra nieve',
          precioCentavos: 1000,
          existencias: 2,
        ),
      ),
      throwsA(isA<CodigoDuplicadoException>()),
    );
  });

  test('cobra una venta y descuenta inventario', () async {
    final producto = (await productos.listar()).single;
    final carrito = Carrito()..agregar(producto, cantidad: 2);
    final venta = await ventas.cobrar(
      carrito,
      5000,
      fecha: DateTime(2026, 11, 4, 12),
    );

    expect(venta.totalCentavos, 5000);
    expect(venta.cambioCentavos, 0);
    expect((await productos.listar()).single.existencias, 3);

    final corte = await ventas.corteDelDia(DateTime(2026, 11, 4));
    expect(corte.numeroVentas, 1);
    expect(corte.totalCentavos, 5000);
  });

  test('no guarda la venta si el inventario cambió', () async {
    final producto = (await productos.listar()).single;
    final carrito = Carrito()..agregar(producto, cantidad: 5);
    await database.update(
      'productos',
      {'existencias': 2},
      where: 'codigo = ?',
      whereArgs: ['NV-001'],
    );

    await expectLater(
      ventas.cobrar(carrito, 12500),
      throwsA(isA<ExistenciasInsuficientesException>()),
    );
    expect((await ventas.corteDelDia(DateTime.now())).numeroVentas, 0);
  });
}
