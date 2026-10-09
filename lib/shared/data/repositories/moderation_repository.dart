import '../models/models.dart';

/// Denúncias, bloqueios, verificação de contas, painel da equipe e
/// transparência. Implementações: [MockModerationRepository] e
/// [SupabaseModerationRepository].
abstract interface class ModerationRepository {
  Future<void> report(ReportTarget target, String targetId, ReportReason reason, {String details = ''});

  /// Bloqueia/desbloqueia. Retorna se ficou bloqueado e o usuário logado.
  Future<(bool, AppUser)> toggleBlock(String profileId);

  Future<List<AppUser>> blocked();

  /// [documentPath] vem do upload no bucket privado de documentos.
  Future<AppUser> requestVerification({
    required String legalName,
    required String documentNumber,
    required String documentPath,
    String notes = '',
  });

  /// Último pedido (status e motivo de recusa), se houver.
  Future<({String status, String? reviewNote})> myVerification();

  Future<Transparency> transparency();

  // Equipe ------------------------------------------------------------------

  Future<AdminDashboard> dashboard();

  Future<List<AdminReport>> reports();

  Future<void> resolve(String reportId, ModerationAction action, {String note = '', int days = 7});

  Future<List<VerificationRequest>> verifications();

  Future<void> reviewVerification(String requestId, {required bool approve, String note = ''});

  /// Link temporário para a equipe abrir o documento enviado.
  Future<String> documentUrl(String path);

  Future<List<AdCampaign>> adsInReview();

  Future<void> reviewAd(String campaignId, {required bool approve, String note = ''});

  Future<List<PayoutRequest>> payouts();

  Future<void> setPayout(String payoutId, {required bool paid, String note = ''});
}
