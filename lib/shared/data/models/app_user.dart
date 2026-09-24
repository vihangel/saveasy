import 'package:freezed_annotation/freezed_annotation.dart';

import 'account_type.dart';
import 'address.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String id,
    required String name,
    required String username,
    required String email,
    required AccountType accountType,
    @Default('') String pronouns,

    /// Referência do [ImageStorage] (arquivo local ou data URI).
    String? avatarUrl,
    DateTime? birthDate,
    Address? address,
    @Default('') String bio,
    @Default(1) int level,
    @Default(0) int xp,
    @Default(0) int coins,
    @Default(0) double balance,
    @Default(0) int followers,
    @Default(0) int following,
    @Default(0) int postsCount,
    @Default(0.0) double rating,
    @Default(<String>[]) List<String> badgeIds,
    String? titleId,
    @Default(false) bool emailNews,
    @Default(<String>[]) List<String> followingIds,
    @Default(<String>[]) List<String> subscribedCommunityIds,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

  /// XP necessário para passar de nível (regra mockada).
  static const xpPerLevel = 300;

  double get levelProgress => (xp % xpPerLevel) / xpPerLevel;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
