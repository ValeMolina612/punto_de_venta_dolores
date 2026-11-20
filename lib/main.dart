import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'datos/base_datos.dart';
import 'datos/repositorio_productos.dart';
import 'datos/repositorio_ventas.dart';
import 'presentacion/caja_viewmodel.dart';
import 'presentacion/pantalla_caja.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      {
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final db = await BaseDatos.abrir();
  final productos = RepositorioProductos(db);
  await productos.sembrarEjemplos();

  runApp(
    PuntoDeVentaApp(
      viewModel: CajaViewModel(productos, RepositorioVentas(db)),
    ),
  );
}

class PuntoDeVentaApp extends StatelessWidget {
  final CajaViewModel viewModel;

  const PuntoDeVentaApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Punto de Venta Dolores',
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: PantallaCaja(vm: viewModel),
      );
}
