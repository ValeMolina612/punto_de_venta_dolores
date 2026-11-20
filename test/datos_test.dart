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

  test('guarda y busca producto', () async {
    final producto = await productos.buscarPorCodigo('NV-001');

    expect(producto!.nombre, 'Nieve de limón');
    expect(producto.id, isNotNull);
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

  test('permite filtrar productos', () async {
    final resultado = await productos.listar(filtro: 'limón');
    expect(resultado, hasLength(1));
  });

  test('cobrar descuenta inventario y registra venta', () async {
    final producto = (await productos.buscarPorCodigo('NV-001'))!;
    final carrito = Carrito()..agregar(producto, cantidad: 2);
    final venta = await ventas.cobrar(
      carrito,
      10000,
      fecha: DateTime(2026, 11, 4, 12),
    );

    expect(venta.totalCentavos, 5000);
    expect(venta.cambioCentavos, 5000);
    expect(
      (await productos.buscarPorCodigo('NV-001'))!.existencias,
      3,
    );

    final corte = await ventas.corteDelDia(DateTime(2026, 11, 4));
    expect(corte.numeroVentas, 1);
    expect(corte.totalCentavos, 5000);
  });

  test('si falla el cobro no se descuenta inventario', () async {
    final producto = (await productos.buscarPorCodigo('NV-001'))!;
    final carrito = Carrito()..agregar(producto, cantidad: 2);

    await expectLater(
      ventas.cobrar(carrito, 100),
      throwsA(isA<PagoInsuficienteException>()),
    );
    expect(
      (await productos.buscarPorCodigo('NV-001'))!.existencias,
      5,
    );
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

  test('corte del día suma ventas de la fecha indicada', () async {
    final producto = (await productos.buscarPorCodigo('NV-001'))!;
    final fecha = DateTime(2026, 11, 4, 12);
    await ventas.cobrar(Carrito()..agregar(producto), 2500, fecha: fecha);
    await ventas.cobrar(
      Carrito()..agregar(producto, cantidad: 2),
      5000,
      fecha: fecha,
    );

    final resumen = await ventas.corteDelDia(fecha);
    expect(resumen.numeroVentas, 2);
    expect(resumen.totalCentavos, 7500);
  });

  test('bajo inventario alerta y permite actualizar', () async {
    await productos.actualizarExistencias('NV-001', 2);

    final bajos = await productos.bajoInventario();
    expect(bajos, hasLength(1));
    expect(bajos.single.existencias, 2);
  });

  test('sembrar ejemplos solo llena una base vacía', () async {
    await productos.sembrarEjemplos();
    expect(await productos.listar(), hasLength(1));
  });
}
