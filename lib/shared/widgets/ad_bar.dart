import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../notifiers/session_cubit.dart';
import '../services/admob.dart';
import '../utils/links.dart';
import 'user_avatar.dart';

/// Barra de anúncio acima do menu inferior. Troca de anúncio a cada 45 s;
/// pode ser fechada até a próxima abertura do app. Sem anúncio na região,
/// quem pode anunciar vê o convite "Anuncie aqui".
class AdBar extends StatefulWidget {
  const AdBar({super.key});

  @override
  State<AdBar> createState() => _AdBarState();
}

class _AdBarState extends State<AdBar> {
  static bool _dismissed = false;
  AdCampaign? _ad;
  bool _loaded = false;
  Timer? _rotate;

  AdsRepository get _ads => context.read<AdsRepository>();

  @override
  void initState() {
    super.initState();
    if (_dismissed) return;
    _load();
    _rotate = Timer.periodic(const Duration(seconds: 45), (_) => _load());
  }

  @override
  void dispose() {
    _rotate?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ads = await _ads.next(AdFormat.bar);
      if (!mounted) return;
      setState(() {
        _ad = ads.firstOrNull;
        _loaded = true;
      });
      if (_ad != null) await _ads.trackImpression(_ad!.id);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _open(AdCampaign ad) async {
    await _ads.trackClick(ad.id);
    if (!mounted) return;
    if (ad.linkUrl != null && await openExternalLink(ad.linkUrl)) return;
    if (!mounted) return;
    if (ad.postId != null) {
      context.push(AppRoutes.post(ad.postId!));
    } else if (ad.ownerId != null) {
      context.push(AppRoutes.user(ad.ownerId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !_loaded) return const SizedBox.shrink();
    final ad = _ad;
    final user = context.select((SessionCubit c) => c.state.userOrNull);
    final canAdvertise = user != null && user.accountType != AccountType.personal;
    // Sem campanha local no celular: anúncio do AdMob como reserva.
    if (ad == null && AdMob.enabled) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 30),
        child: Center(child: AdMobBanner()),
      );
    }
    if (ad == null && !canAdvertise) return const SizedBox.shrink();
    // Espaço embaixo para o botão "+" do menu não cobrir o anúncio.
    return Padding(padding: const EdgeInsets.only(bottom: 30), child: _content(ad));
  }

  Widget _content(AdCampaign? ad) {
    return Material(
      color: AppColors.primaryLight,
      child: InkWell(
        onTap: ad == null ? () => context.push(AppRoutes.ads) : () => _open(ad),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            children: [
              if (ad != null)
                UserAvatar(name: ad.ownerName, imageUrl: ad.ownerAvatarUrl, size: 30)
              else
                const Icon(Icons.campaign_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ad == null ? 'Anuncie para Cuiabá aqui' : ad.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                    ),
                    Text(
                      ad == null ? '30% do valor vai para o fundo de doações' : 'Patrocinado · ${ad.body}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                ad == null ? 'Anunciar' : ad.ctaLabel,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12),
              ),
              IconButton(
                tooltip: 'Fechar anúncio',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _dismissed = true),
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
