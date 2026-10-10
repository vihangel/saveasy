import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/context_x.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/utils/validators.dart';

/// Nova campanha: formato, conteúdo, plano, cidades, orçamento e pagamento.
class AdFormPage extends StatefulWidget {
  const AdFormPage({super.key});

  /// Cidades oferecidas no lançamento (Mato Grosso).
  static const cities = ['Cuiabá', 'Várzea Grande', 'Chapada dos Guimarães', 'Rondonópolis', 'Sinop'];

  @override
  State<AdFormPage> createState() => _AdFormPageState();
}

class _AdFormPageState extends State<AdFormPage> {
  AdFormat _format = AdFormat.bar;
  AdPlan _plan = AdPlan.weekly;
  final _cities = <String>{'Cuiabá'};
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _cta = TextEditingController(text: 'Saiba mais');
  final _link = TextEditingController();
  String? _image;
  String? _postId;
  AdQuote? _quote;
  bool _saving = false;
  late final Future<List<Post>> _myPosts = context.read<PostRepository>().byAuthor(context.currentUser.id);

  AdsRepository get _ads => context.read<AdsRepository>();

  @override
  void initState() {
    super.initState();
    _updateQuote();
  }

  @override
  void dispose() {
    for (final c in [_title, _body, _cta, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _updateQuote() async {
    try {
      final quote = await _ads.quote(_format, _plan, _cities.toList());
      if (mounted) setState(() => _quote = quote);
    } on AppException {
      // Orçamento aparece quando a conexão voltar.
    }
  }

  Future<void> _submit() async {
    if (_format == AdFormat.boostedPost && _postId == null) {
      return context.showMessage('Escolha a publicação para impulsionar.', error: true);
    }
    if (_title.text.trim().length < 3) return context.showMessage('Escreva um título (3 a 60 letras).', error: true);
    if (Validators.optionalUrl(_link.text) != null) return context.showMessage('O link é inválido.', error: true);
    setState(() => _saving = true);
    try {
      final campaign = await _ads.create(
        format: _format,
        plan: _plan,
        title: _title.text,
        body: _body.text,
        imageUrl: _image,
        ctaLabel: _cta.text,
        linkUrl: switch (_link.text.trim()) {
          '' => null,
          final l when l.startsWith('http') => l,
          final l => 'https://$l',
        },
        postId: _postId,
        cities: _cities.toList(),
      );
      if (!mounted) return;
      final user = await showCheckout(context, PaymentIntent.adCampaign(campaignId: campaign.id));
      if (!mounted) return;
      context.showMessage(
        user == null
            ? 'Campanha salva. Você pode pagar depois em Anúncios.'
            : user.verificationStatus == 'verified'
            ? 'Pago! Sua campanha já está no ar.'
            : 'Pago! A campanha entra no ar depois da análise (até 24 h).',
      );
      context.pop();
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.showMessage(e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.ads),
        title: const Text('Nova campanha'),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          Text('Formato', style: context.text.titleMedium),
          RadioGroup<AdFormat>(
            groupValue: _format,
            onChanged: (v) {
              setState(() => _format = v!);
              _updateQuote();
            },
            child: Column(
              children: [
                for (final f in AdFormat.values)
                  RadioListTile<AdFormat>(
                    contentPadding: EdgeInsets.zero,
                    value: f,
                    title: Text(f.label),
                    subtitle: Text(f.description),
                  ),
              ],
            ),
          ),
          if (_format == AdFormat.boostedPost)
            FutureBuilder<List<Post>>(
              future: _myPosts,
              builder: (context, snapshot) {
                final posts = snapshot.data ?? const <Post>[];
                return DropdownButtonFormField<String>(
                  initialValue: _postId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Publicação'),
                  items: [
                    for (final p in posts)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(p.title, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _postId = v),
                );
              },
            ),
          const SizedBox(height: 12),
          AppTextField(label: 'Título', controller: _title, maxLength: 60),
          const SizedBox(height: 12),
          AppTextField(label: 'Texto', controller: _body, maxLines: 2, maxLength: 140),
          if (_format != AdFormat.boostedPost) ...[
            const SizedBox(height: 12),
            AppTextField(label: 'Botão', controller: _cta, maxLength: 20),
            const SizedBox(height: 12),
            AppTextField(label: 'Link (opcional)', controller: _link, keyboardType: TextInputType.url),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await showImagePickerSheet(
                  context,
                  title: 'Imagem do anúncio',
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
              icon: Icon(_image == null ? Icons.add_photo_alternate_outlined : Icons.check_circle_rounded),
              label: Text(_image == null ? 'Adicionar imagem' : 'Imagem escolhida'),
            ),
          ],
          const SizedBox(height: 16),
          Text('Duração', style: context.text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final p in AdPlan.values)
                ChoiceChip(
                  label: Text(p.label),
                  selected: p == _plan,
                  onSelected: (_) {
                    setState(() => _plan = p);
                    _updateQuote();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Onde mostrar', style: context.text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final city in AdFormPage.cities)
                FilterChip(
                  label: Text(city),
                  selected: _cities.contains(city),
                  onSelected: (on) {
                    setState(() => on ? _cities.add(city) : (_cities.length > 1 ? _cities.remove(city) : null));
                    _updateQuote();
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: quote == null
                ? const Text('Calculando...')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Formatters.currency(quote.price), style: context.text.headlineSmall),
                      Text(
                        '${quote.days} dia(s) · ${Formatters.currency(quote.dailyPrice)}/dia'
                        '${quote.discount > 0 ? ' · ${(quote.discount * 100).round()}% de desconto' : ''}'
                        '${_cities.length > 1 ? ' · +30% por cidade extra' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(quote.fundShare * 100).round()}% (${Formatters.currency(quote.price * quote.fundShare)}) '
                        'vai para o fundo de doações.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: quote == null ? 'Continuar' : 'Pagar ${Formatters.currency(quote.price)}',
            loading: _saving,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          const Text(
            'Contas não verificadas passam por análise antes de o anúncio ir ao ar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
