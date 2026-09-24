import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../data/models/models.dart';
import 'coin_chip.dart';
import 'progress_bar.dart';
import 'user_avatar.dart';

/// Bloco "Progresso" (nome, nível, moedas e barra de XP) das telas de
/// Recompensas, Conquistas e do menu.
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF8A9BFF)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(name: user.name, imageUrl: user.avatarUrl, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text('Nível ${user.level}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              CoinChip(coins: user.coins, light: true),
            ],
          ),
          const SizedBox(height: 14),
          ProgressBar(value: user.levelProgress, color: Colors.white),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${user.xp % AppUser.xpPerLevel}/${AppUser.xpPerLevel} XP para o nível ${user.level + 1}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
