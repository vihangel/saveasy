import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/formatters.dart';

/// "+10 🪙" / saldo de moedas.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins, this.prefix = '', this.light = false});

  final int coins;
  final String prefix;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: 0.2) : AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, size: 16, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            '$prefix${Formatters.number(coins)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: light ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
