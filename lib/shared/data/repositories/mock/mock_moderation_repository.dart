import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../app_exception.dart';
import '../moderation_repository.dart';

/// Moderação local: guarda denúncias e bloqueios em memória.
class MockModerationRepository implements ModerationRepository {
  MockModerationRepository(this._db);

  final MockDatabase _db;
  final _blocked = <String>{};
  final _reports = <AdminReport>[];

  AppUser get _me => _db.users.firstWhere((u) => u.onboardingCompleted);

  @override
  Future<void> report(ReportTarget target, String targetId, ReportReason reason, {String details = ''}) async {
    _reports.add(
      AdminReport(
        id: '${_reports.length + 1}',
        targetType: target,
        targetId: targetId,
        reason: reason,
        details: details,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<(bool, AppUser)> toggleBlock(String profileId) async {
    final blocked = !_blocked.remove(profileId);
    if (blocked) _blocked.add(profileId);
    return (blocked, _me);
  }

  @override
  Future<List<AppUser>> blocked() async => [for (final id in _blocked) _db.userById(id)];

  @override
  Future<AppUser> requestVerification({
    required String legalName,
    required String documentNumber,
    required String documentPath,
    String notes = '',
  }) async {
    final updated = _me.copyWith(verificationStatus: 'pending');
    await _db.replaceUser(updated);
    return updated;
  }

  @override
  Future<({String status, String? reviewNote})> myVerification() async =>
      (status: _me.verificationStatus ?? 'unverified', reviewNote: null);

  @override
  Future<Transparency> transparency() async => const Transparency(fund: DonationFund(balance: 500, received: 500));

  @override
  Future<AdminDashboard> dashboard() async => AdminDashboard(openReports: _reports.length);

  @override
  Future<List<AdminReport>> reports() async => _reports;

  @override
  Future<void> resolve(String reportId, ModerationAction action, {String note = '', int days = 7}) async =>
      _reports.removeWhere((r) => r.id == reportId);

  @override
  Future<List<VerificationRequest>> verifications() async => const [];

  @override
  Future<void> reviewVerification(String requestId, {required bool approve, String note = ''}) async {}

  @override
  Future<String> documentUrl(String path) async => throw const AppException('Documento indisponível no modo local.');

  @override
  Future<List<AdCampaign>> adsInReview() async => const [];

  @override
  Future<void> reviewAd(String campaignId, {required bool approve, String note = ''}) async {}

  @override
  Future<List<PayoutRequest>> payouts() async => const [];

  @override
  Future<void> setPayout(String payoutId, {required bool paid, String note = ''}) async {}
}
