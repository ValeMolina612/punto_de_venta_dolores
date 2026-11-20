import 'package:flutter/material.dart';

import '../dominio/dinero.dart';
import '../dominio/producto.dart';
import 'caja_viewmodel.dart';

class PantallaCaja extends StatefulWidget {
  final CajaViewModel vm;

  const PantallaCaja({super.key, required this.vm});

  @override
  State<PantallaCaja> createState() => _PantallaCajaState();
}

class _PantallaCajaState extends State<PantallaCaja> {
  final _filtro = TextEditingController();
  final _pago = TextEditingController();

  CajaViewModel get vm => widget.vm;

  @override
  void initState() {
    super.initState();
    vm.cargar();
  }

  @override
  void dispose() {
    _filtro.dispose();
    _pago.dispose();
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: vm,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Caja · Dolores Hidalgo')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _mostrarFormularioProducto,
            icon: const Icon(Icons.add),
            label: const Text('Producto'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _filtro,
                  decoration: InputDecoration(
                    labelText: 'Buscar producto',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _filtro.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _filtro.clear();
                              vm.cargar();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (texto) {
                    setState(() {});
                    vm.cargar(filtro: texto);
                  },
                ),
              ),
              Expanded(
                child: vm.catalogo.isEmpty
                    ? const Center(
                        child: Text('No hay productos para mostrar.'))
                    : ListView.builder(
                        itemCount: vm.catalogo.length,
                        itemBuilder: (context, index) {
                          final producto = vm.catalogo[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.inventory_2_outlined),
                            ),
                            title: Text(producto.nombre),
                            subtitle: Text(
                              '${producto.codigo} · ${producto.existencias} disponibles',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatearPesos(producto.precioCentavos)),
                                IconButton(
                                  tooltip: 'Agregar al carrito',
                                  onPressed: producto.existencias == 0
                                      ? null
                                      : () => vm.agregar(producto),
                                  icon: const Icon(Icons.add_shopping_cart),
                                ),
                              ],
                            ),
                            onTap: producto.existencias == 0
                                ? null
                                : () => vm.agregar(producto),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 190),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final linea in vm.carrito.lineas)
                      ListTile(
                        dense: true,
                        title: Text(
                          '${linea.cantidad} × ${linea.producto.nombre}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatearPesos(linea.importeCentavos)),
                            IconButton(
                              tooltip: 'Quitar',
                              onPressed: () => vm.quitar(linea.producto.codigo),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'IVA incluido: ${formatearPesos(vm.carrito.ivaCentavos)}',
                      ),
                      Text(
                        'TOTAL ${formatearPesos(vm.carrito.totalCentavos)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pago,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Paga con \$',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: vm.carrito.estaVacio ? null : _cobrar,
                            child: const Text('Cobrar'),
                          ),
                        ],
                      ),
                      if (vm.mensaje != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(vm.mensaje!),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _cobrar() async {
    if (await vm.cobrar(_pago.text)) {
      _pago.clear();
      _filtro.clear();
    }
  }

  Future<void> _mostrarFormularioProducto() async {
    final codigo = TextEditingController();
    final nombre = TextEditingController();
    final precio = TextEditingController();
    final existencias = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final producto = await showDialog<Producto>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo producto'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(codigo, 'Código'),
                _campo(nombre, 'Nombre'),
                _campo(precio, 'Precio (pesos)', numerico: true),
                _campo(existencias, 'Existencias', numerico: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              try {
                final precioCentavos = pesosACentavos(precio.text);
                final cantidad = int.parse(existencias.text.trim());
                if (precioCentavos <= 0 || cantidad < 0) {
                  throw const FormatException();
                }
                Navigator.pop(
                  context,
                  Producto(
                    codigo: codigo.text.trim(),
                    nombre: nombre.text.trim(),
                    precioCentavos: precioCentavos,
                    existencias: cantidad,
                  ),
                );
              } on FormatException {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Revisa el precio y las existencias.'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    codigo.dispose();
    nombre.dispose();
    precio.dispose();
    existencias.dispose();

    if (producto == null || !mounted) return;
    await vm.agregarProducto(producto, filtro: _filtro.text);
  }

  Widget _campo(
    TextEditingController controller,
    String etiqueta, {
    bool numerico = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller,
          keyboardType: numerico
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: etiqueta,
            border: const OutlineInputBorder(),
          ),
          validator: (valor) =>
              valor == null || valor.trim().isEmpty ? 'Campo requerido' : null,
        ),
      );
}
