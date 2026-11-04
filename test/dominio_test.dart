import 'package:flutter_test/flutter_test.dart';
import 'package:punto_venta_dolores/dominio/carrito.dart';
import 'package:punto_venta_dolores/dominio/dinero.dart';
import 'package:punto_venta_dolores/dominio/excepciones.dart';
import 'package:punto_venta_dolores/dominio/producto.dart';

Producto nieve({int existencias = 10}) => Producto(
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

    test('convierte pesos a centavos', () {
      expect(pesosACentavos('12.5'), 1250);
      expect(pesosACentavos('\$1,234.56'), 123456);
    });
  });

  group('Carrito', () {
    test('calcula total, IVA y cambio', () {
      final carrito = Carrito()..agregar(nieve());

      expect(carrito.totalCentavos, 2500);
      expect(carrito.ivaCentavos, 345);
      expect(carrito.subtotalCentavos, 2155);
      expect(carrito.cambio(3000), 500);
    });

    test('rechaza pago insuficiente y carrito vacío', () {
      final carrito = Carrito();
      expect(() => carrito.cambio(0), throwsA(isA<CarritoVacioException>()));

      carrito.agregar(nieve());
      expect(
        () => carrito.cambio(1000),
        throwsA(isA<PagoInsuficienteException>()),
      );
    });

    test('no permite agregar más unidades que las existencias', () {
      final carrito = Carrito();
      carrito.agregar(nieve(existencias: 1));

      expect(
        () => carrito.agregar(nieve(existencias: 1)),
        throwsA(isA<ExistenciasInsuficientesException>()),
      );
    });
  });
}
