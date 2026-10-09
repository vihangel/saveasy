import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_user.dart';
import 'money.dart';

part 'moderation.freezed.dart';
part 'moderation.g.dart';

enum ReportTarget { post, comment, profile, message, story, product, ad }

enum ReportReason {
  spam('Spam ou propaganda enganosa'),
  scam('Golpe ou fraude'),
  hate('Ódio ou discriminação'),
  violence('Violência ou ameaça'),
  nudity('Nudez ou conteúdo sexual'),
  @JsonValue('false_info')
  falseInfo('Informação falsa'),
  other('Outro motivo');

  const ReportReason(this.label);

  final String label;

  String get json => this == falseInfo ? 'false_info' : name;
}

@freezed
abstract class ReportPreview with _$ReportPreview {
  const factory ReportPreview({
    @Default('') String title,
    @Default('') String text,
    String? authorId,
    String? authorName,
    String? postId,
  }) = _ReportPreview;

  factory ReportPreview.fromJson(Map<String, dynamic> json) => _$ReportPreviewFromJson(json);
}

@freezed
abstract class AdminReport with _$AdminReport {
  const factory AdminReport({
    required String id,
    required ReportTarget targetType,
    required String targetId,
    required ReportReason reason,
    required DateTime createdAt,
    @Default('') String details,
    @Default('open') String status,
    String? reporterName,
    @Default(1) int reportsOnTarget,
    ReportPreview? preview,
  }) = _AdminReport;

  factory AdminReport.fromJson(Map<String, dynamic> json) => _$AdminReportFromJson(json);
}

/// Ação de moderação sobre uma denúncia.
enum ModerationAction {
  dismiss('Arquivar (sem problema)'),
  remove('Remover conteúdo'),
  suspend('Remover e suspender o autor');

  const ModerationAction(this.label);

  final String label;
}

@freezed
abstract class AdminDashboard with _$AdminDashboard {
  const factory AdminDashboard({
    @Default(0) int openReports,
    @Default(0) int pendingVerifications,
    @Default(0) int adsInReview,
    @Default(0) int payoutsRequested,
    @Default(0) int users,
    @Default(0) int posts,
    @Default(0) double donations,
    @Default(DonationFund()) DonationFund fund,
  }) = _AdminDashboard;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) => _$AdminDashboardFromJson(json);
}

@freezed
abstract class VerificationRequest with _$VerificationRequest {
  const factory VerificationRequest({
    required String id,
    required String legalName,
    required String documentNumber,
    required String documentPath,
    required DateTime createdAt,
    required AppUser profile,
    @Default('') String notes,
  }) = _VerificationRequest;

  factory VerificationRequest.fromJson(Map<String, dynamic> json) => _$VerificationRequestFromJson(json);
}

@freezed
abstract class PayoutRequest with _$PayoutRequest {
  const factory PayoutRequest({
    required String id,
    required double amount,
    required DateTime createdAt,
    required AppUser profile,
    @Default('') String pixKey,
  }) = _PayoutRequest;

  factory PayoutRequest.fromJson(Map<String, dynamic> json) => _$PayoutRequestFromJson(json);
}

@freezed
abstract class FundMovement with _$FundMovement {
  const factory FundMovement({
    required double amount,
    required String kind,
    required DateTime createdAt,
    String? note,
  }) = _FundMovement;

  factory FundMovement.fromJson(Map<String, dynamic> json) => _$FundMovementFromJson(json);
}

/// Números públicos da página de transparência.
@freezed
abstract class Transparency with _$Transparency {
  const factory Transparency({
    @Default(DonationFund()) DonationFund fund,
    @Default(0) double donationsTotal,
    @Default(0) int donationsCount,
    @Default(0) int campaigns,
    @Default(0) int actions,
    @Default(0) int volunteers,
    @Default(0) double adShare,
    @Default(<FundMovement>[]) List<FundMovement> movements,
  }) = _Transparency;

  factory Transparency.fromJson(Map<String, dynamic> json) => _$TransparencyFromJson(json);
}
