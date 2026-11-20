import 'package:flutter_test/flutter_test.dart';
import 'package:punto_venta_dolores/dominio/carrito.dart';
import 'package:punto_venta_dolores/dominio/dinero.dart';
import 'package:punto_venta_dolores/dominio/excepciones.dart';
import 'package:punto_venta_dolores/dominio/producto.dart';

Producto nieve([int existencias = 10]) => Producto(
      codigo: 'NV-001',
      nombre: 'Nieve',
      precioCentavos: 2500,
      existencias: existencias,
    );

void main() {
  group('Dinero', () {
    test('formatea centavos', () {
      expect(formatearPesos(0), '\$0.00');
      expect(formatearPesos(5), '\$0.05');
      expect(formatearPesos(123456), '\$1,234.56');
    });

    test('convierte texto a centavos', () {
      expect(pesosACentavos('12.5'), 1250);
      expect(pesosACentavos('\$1,200'), 120000);
      expect(pesosACentavos('0.07'), 7);
      expect(pesosACentavos('.5'), 50);
    });

    test('rechaza texto inválido', () {
      expect(() => pesosACentavos(''), throwsFormatException);
      expect(() => pesosACentavos('1.2.3'), throwsFormatException);
    });

    test('formatea cantidades negativas', () {
      expect(formatearPesos(-250), '-\$2.50');
    });
  });

  group('Producto', () {
    test('ida y vuelta a mapa conserva los datos', () {
      const original = Producto(
        codigo: 'NV-001',
        nombre: 'Nieve de limón',
        precioCentavos: 2500,
        existencias: 10,
      );
      final copia = Producto.desdeMapa(original.aMapa());

      expect(copia.codigo, 'NV-001');
      expect(copia.precioCentavos, 2500);
    });

    test('copiarCon cambia solo lo indicado', () {
      const producto = Producto(
        codigo: 'A',
        nombre: 'X',
        precioCentavos: 100,
        existencias: 5,
      );
      final copia = producto.copiarCon(existencias: 4);

      expect(copia.existencias, 4);
      expect(copia.precioCentavos, 100);
    });
  });

  group('Carrito', () {
    test('suma cantidades del mismo producto', () {
      final carrito = Carrito()
        ..agregar(nieve())
        ..agregar(nieve());

      expect(carrito.lineas.single.cantidad, 2);
      expect(carrito.totalCentavos, 5000);
    });

    test('no excede existencias', () {
      final carrito = Carrito()..agregar(nieve(1));

      expect(
        () => carrito.agregar(nieve(1)),
        throwsA(isA<ExistenciasInsuficientesException>()),
      );
    });

    test('desglosa IVA 16% del total', () {
      final carrito = Carrito()..agregar(nieve(), cantidad: 4);

      expect(carrito.ivaCentavos, 1379);
      expect(
        carrito.subtotalCentavos + carrito.ivaCentavos,
        carrito.totalCentavos,
      );
    });

    test('calcula cambio', () {
      final carrito = Carrito()..agregar(nieve());
      expect(carrito.cambio(5000), 2500);
    });

    test('pago insuficiente lanza', () {
      final carrito = Carrito()..agregar(nieve());
      expect(
        () => carrito.cambio(1000),
        throwsA(isA<PagoInsuficienteException>()),
      );
    });

    test('carrito vacío no cobra', () {
      expect(
        () => Carrito().cambio(100),
        throwsA(isA<CarritoVacioException>()),
      );
    });
  });
}
