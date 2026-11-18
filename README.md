# Punto de venta Dolores

Aplicación Flutter de punto de venta con almacenamiento local SQLite.

## Estructura

- `lib/dominio/`: modelos, reglas de negocio y manejo de dinero.
- `lib/datos/`: base de datos y repositorios.
- `lib/presentacion/`: aplicación y estado de la caja.
- `test/`: pruebas de dominio y de acceso a datos.

## Ejecutar y probar

```shell
flutter pub get
flutter run
flutter test
flutter analyze
```

## Evidencia de pruebas

La suite valida dinero en centavos, carrito, inventario, persistencia y cobro de ventas. Resultado: **9 pruebas aprobadas**.

### Ciclo TDD: rojo a verde

Ambas capturas fueron tomadas de ejecuciones reales en la terminal integrada de Visual Studio Code: la fase roja muestra `undefined_function` por código aún no implementado y la fase verde muestra la suite final aprobada.

| 🔴 Prueba que solicita código faltante | 🟢 Implementación terminada |
|---|---|
| ![Error real por código faltante en la terminal de VS Code](capturas/tdd_rojo_error.png) | ![Pruebas aprobadas en la terminal de VS Code](capturas/pruebas_vscode.png) |
