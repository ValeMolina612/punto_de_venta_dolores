# Punto de venta Dolores

Aplicación de punto de venta hecha en Flutter. Permite registrar productos, usar un carrito, cobrar ventas y descontar existencias.

## Cómo ejecutarlo

```bash
flutter pub get
flutter run
```

Para ejecutar las pruebas:

```bash
flutter test
```

## Todas las pruebas

Se ejecutaron las siguientes 9 pruebas:

1. Agrega productos y permite buscarlos con un filtro.
2. El dinero se muestra correctamente usando centavos.
3. Convierte pesos a centavos.
4. El carrito calcula total, IVA y cambio.
5. El carrito rechaza un pago insuficiente o un carrito vacío.
6. No permite agregar más unidades de las disponibles.
7. Rechaza códigos de producto repetidos.
8. Cobrar una venta descuenta el inventario.
9. No guarda la venta si el inventario cambió antes del cobro.

Resultado final: **9 pruebas aprobadas**.

## Capturas reales de las pruebas

| Fase roja | Fase verde |
|---|---|
| ![Error real en la terminal de VS Code](capturas/tdd_rojo_error.png) | ![9 pruebas aprobadas en la terminal de VS Code](capturas/pruebas_vscode.png) |
