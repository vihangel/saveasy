import 'package:flutter/material.dart';

import '../data/models/models.dart';

/// Converte as chaves de ícone dos dados mockados em ícones do Material.
abstract final class AppIcons {
  static IconData byKey(String key) => switch (key) {
    'music' => Icons.headphones_rounded,
    'forest' => Icons.forest_rounded,
    'recycle' => Icons.recycling_rounded,
    'coffee' => Icons.coffee_rounded,
    'planet' => Icons.public_rounded,
    'vegan' => Icons.eco_rounded,
    'volunteer' => Icons.volunteer_activism_rounded,
    'pets' => Icons.pets_rounded,
    'school' => Icons.school_rounded,
    'eco' => Icons.energy_savings_leaf_rounded,
    'theater' => Icons.theater_comedy_rounded,
    'love' => Icons.favorite_rounded,
    'dog' => Icons.cruelty_free_rounded,
    'shiba' => Icons.pets_rounded,
    'help' => Icons.handshake_rounded,
    'checkroom' => Icons.checkroom_rounded,
    'key' => Icons.key_rounded,
    'wallet' => Icons.account_balance_wallet_rounded,
    _ => Icons.star_rounded,
  };

  static IconData postType(PostType type) => switch (type) {
    PostType.donation => Icons.volunteer_activism_rounded,
    PostType.event => Icons.event_rounded,
    PostType.socialAction => Icons.diversity_3_rounded,
    PostType.activity => Icons.recycling_rounded,
    PostType.tutorial => Icons.menu_book_rounded,
    PostType.discussion => Icons.forum_rounded,
    PostType.ad => Icons.campaign_rounded,
  };

  static IconData accountType(AccountType type) => switch (type) {
    AccountType.personal => Icons.person_rounded,
    AccountType.business => Icons.business_rounded,
    AccountType.influencer => Icons.star_rounded,
    AccountType.community => Icons.groups_rounded,
  };
}
