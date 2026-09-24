import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../data/models/models.dart';
import 'app_back_button.dart';
import 'coin_chip.dart';
import 'progress_bar.dart';

/// Tela de sucesso com as recompensas ganhas
/// (Doar 3/4, Evento Confirmado 1/2, Enviar Moedas 2).
class RewardSuccessView extends StatelessWidget {
  const RewardSuccessView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.user,
    required this.actions,
    this.coins = 0,
    this.xp = 0,
    this.highlight,
  });

  final IconData icon;
  final String title;
  final String message;
  final AppUser user;
  final int coins;
  final int xp;
  final String? highlight;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(icon, size: 72, color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 24),
                Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                if (highlight != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    highlight!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('Você ganhou', style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (coins > 0) CoinChip(coins: coins, prefix: '+'),
                          if (coins > 0 && xp > 0) const SizedBox(width: 12),
                          if (xp > 0)
                            Text(
                              '+$xp XP',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _LevelBadge(level: user.level),
                          const SizedBox(width: 8),
                          Expanded(child: ProgressBar(value: user.levelProgress, height: 10)),
                          const SizedBox(width: 8),
                          _LevelBadge(level: user.level + 1, muted: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ...actions,
              ],
            ),
          ),
          const Positioned(left: 4, top: 4, child: AppBackButton(close: true)),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, this.muted = false});

  final int level;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: muted ? AppColors.border : AppColors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'LV $level',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted ? AppColors.textMuted : Colors.white),
      ),
    );
  }
}
