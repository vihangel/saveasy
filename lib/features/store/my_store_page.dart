import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import 'store_cubit.dart';
import 'store_page.dart';

/// Gestão da loja (comunidade/empresa): produtos ativos e inativos.
class MyStorePage extends StatefulWidget {
  const MyStorePage({super.key});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  late Future<List<Product>> _products = _load();

  Future<List<Product>> _load() => context.read<StoreRepository>().products(sellerId: context.currentUser.id);

  Future<void> _open(String route) async {
    await context.push(route);
    if (!mounted) return;
    setState(() => _products = _load());
    context.read<StoreCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.store),
        title: const Text('Minha loja'),
        actions: [
          IconButton(
            tooltip: 'Vendas',
            onPressed: () => context.push(AppRoutes.orders),
            icon: const Icon(Icons.receipt_long_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(AppRoutes.newProduct),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Produto'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.hasError) return EmptyState(message: snapshot.error.toString(), icon: Icons.cloud_off);
          final products = snapshot.data;
          if (products == null) return const Center(child: CircularProgressIndicator());
          if (products.isEmpty) {
            return const EmptyState(
              message: 'Cadastre produtos para arrecadar fundos para a sua causa.',
              icon: Icons.storefront_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: products.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = products[i];
              return ListTile(
                leading: SizedBox(width: 56, child: ProductImage(product: p, height: 56)),
                title: Text(p.name),
                subtitle: Text(
                  '${Formatters.currency(p.price)} · ${p.stock == null ? 'sem controle de estoque' : '${p.stock} em estoque'}'
                  ' · ${p.salesCount} vendido(s)${p.active ? '' : ' · inativo'}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _open(AppRoutes.editProduct(p.id)),
              );
            },
          );
        },
      ),
    );
  }
}

/// Criar ou editar produto.
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  String? _image;
  bool _active = true;
  bool _saving = false;
  bool _loading = false;
  Product? _editing;

  StoreRepository get _store => context.read<StoreRepository>();

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = (await _store.detail(widget.productId!)).product;
      _editing = p;
      _name.text = p.name;
      _description.text = p.description;
      _price.text = p.price.toStringAsFixed(2).replaceAll('.', ',');
      _stock.text = p.stock?.toString() ?? '';
      _image = p.imageUrl;
      _active = p.active;
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final price = double.tryParse(_price.text.replaceAll(',', '.'));
    if (_name.text.trim().length < 2 || price == null || price <= 0) {
      return context.showMessage('Informe nome e preço.', error: true);
    }
    setState(() => _saving = true);
    final user = context.currentUser;
    try {
      await _store.save(
        (_editing ??
                Product(
                  id: '',
                  name: '',
                  description: '',
                  price: 0,
                  communityId: user.id,
                  communityName: user.name,
                  section: StoreSection.popular,
                ))
            .copyWith(
              name: _name.text.trim(),
              description: _description.text.trim(),
              price: price,
              stock: int.tryParse(_stock.text),
              imageUrl: _image,
              active: _active,
            ),
      );
      if (!mounted) return;
      context.showMessage('Produto salvo!');
      context.pop();
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.showMessage(e.message, error: true);
      }
    }
  }

  Future<void> _delete() async {
    try {
      await _store.delete(_editing!.id);
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) context.showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.myStore),
        title: Text(widget.productId == null ? 'Novo produto' : 'Editar produto'),
        actions: [
          if (_editing != null)
            IconButton(tooltip: 'Remover da loja', onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                InkWell(
                  onTap: () async {
                    final result = await showImagePickerSheet(
                      context,
                      title: 'Foto do produto',
                      canRemove: _image != null,
                    );
                    switch (result) {
                      case ImagePicked(:final reference):
                        setState(() => _image = reference);
                      case ImageRemoved():
                        setState(() => _image = null);
                      case null:
                        break;
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: _image == null
                        ? const Center(child: Icon(Icons.add_a_photo_rounded, size: 40, color: AppColors.primary))
                        : AppImage(reference: _image!, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(label: 'Nome', controller: _name),
                AppTextField(label: 'Descrição', controller: _description, maxLines: 4),
                AppTextField(
                  label: 'Preço (R\$)',
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                ),
                AppTextField(
                  label: 'Estoque (vazio = sem controle)',
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: const Text('À venda'),
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Salvar', loading: _saving, onPressed: _save),
              ],
            ),
    );
  }
}
