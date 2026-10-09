import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob: reserva da barra de anúncio quando não há campanha local.
/// Só no Android/iOS. Em modo debug usa os blocos de teste do Google (usar
/// os reais em desenvolvimento viola as políticas do AdMob).
abstract final class AdMob {
  /// Ligado só depois de [initialize] (testes e web ficam sem AdMob).
  static bool enabled = false;

  static bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Blocos "Barra inferior" criados no AdMob (IDs públicos, não são segredo).
  static String get bannerUnitId => switch (defaultTargetPlatform) {
    TargetPlatform.iOS =>
      kDebugMode ? 'ca-app-pub-3940256099942544/2934735716' : 'ca-app-pub-8949237085831318/2952876010',
    _ => kDebugMode ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-8949237085831318/9413150610',
  };

  static Future<void> initialize() async {
    if (!supported) return;
    try {
      await MobileAds.instance.initialize();
      enabled = true;
    } catch (_) {
      // Sem AdMob o app segue normal.
    }
  }
}

/// Banner padrão (320x50) do AdMob. Some se não carregar.
class AdMobBanner extends StatefulWidget {
  const AdMobBanner({super.key});

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: AdMob.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
