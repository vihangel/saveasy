import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../moderation_repository.dart';
import 'supabase_guard.dart';

/// Moderação e painel da equipe via RPC (supabase/migrations/*_moderation_admin.sql).
class SupabaseModerationRepository implements ModerationRepository {
  SupabaseModerationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> report(ReportTarget target, String targetId, ReportReason reason, {String details = ''}) =>
      supabaseGuard(
        () => _client.rpc<void>(
          'report_content',
          params: {'p_target': target.name, 'p_target_id': targetId, 'p_reason': reason.json, 'p_details': details},
        ),
      );

  @override
  Future<(bool, AppUser)> toggleBlock(String profileId) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('toggle_block', params: {'p_target': profileId});
    return (json['blocked'] as bool, AppUser.fromJson(json['me'] as Map<String, dynamic>));
  });

  @override
  Future<List<AppUser>> blocked() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('my_blocks');
    return list.map((u) => AppUser.fromJson(u as Map<String, dynamic>)).toList();
  });

  @override
  Future<AppUser> requestVerification({
    required String legalName,
    required String documentNumber,
    required String documentPath,
    String notes = '',
  }) => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'request_verification',
      params: {
        'p_legal_name': legalName.trim(),
        'p_document_number': documentNumber.trim(),
        'p_document_path': documentPath,
        'p_notes': notes.trim(),
      },
    );
    return AppUser.fromJson(json);
  });

  @override
  Future<({String status, String? reviewNote})> myVerification() => supabaseGuard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('my_verification');
    final last = json['lastRequest'] as Map<String, dynamic>?;
    return (status: json['status'] as String, reviewNote: last?['reviewNote'] as String?);
  });

  @override
  Future<Transparency> transparency() => supabaseGuard(() async {
    return Transparency.fromJson(await _client.rpc<Map<String, dynamic>>('transparency'));
  });

  @override
  Future<AdminDashboard> dashboard() => supabaseGuard(() async {
    return AdminDashboard.fromJson(await _client.rpc<Map<String, dynamic>>('admin_dashboard'));
  });

  @override
  Future<List<AdminReport>> reports() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('admin_reports');
    return list.map((r) => AdminReport.fromJson(r as Map<String, dynamic>)).toList();
  });

  @override
  Future<void> resolve(String reportId, ModerationAction action, {String note = '', int days = 7}) => supabaseGuard(
    () => _client.rpc<void>(
      'resolve_report',
      params: {'p_report_id': int.parse(reportId), 'p_action': action.name, 'p_note': note, 'p_days': days},
    ),
  );

  @override
  Future<List<VerificationRequest>> verifications() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('admin_verifications');
    return list.map((v) => VerificationRequest.fromJson(v as Map<String, dynamic>)).toList();
  });

  @override
  Future<void> reviewVerification(String requestId, {required bool approve, String note = ''}) => supabaseGuard(
    () => _client.rpc<void>(
      'review_verification',
      params: {'p_request_id': int.parse(requestId), 'p_approve': approve, 'p_note': note},
    ),
  );

  @override
  Future<String> documentUrl(String path) =>
      supabaseGuard(() => _client.storage.from('verification-docs').createSignedUrl(path, 600));

  @override
  Future<List<AdCampaign>> adsInReview() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('admin_ads_in_review');
    return list.map((c) => AdCampaign.fromJson(c as Map<String, dynamic>)).toList();
  });

  @override
  Future<void> reviewAd(String campaignId, {required bool approve, String note = ''}) => supabaseGuard(
    () => _client.rpc<void>(
      'review_ad',
      params: {'p_campaign_id': int.parse(campaignId), 'p_approve': approve, 'p_note': note},
    ),
  );

  @override
  Future<List<PayoutRequest>> payouts() => supabaseGuard(() async {
    final list = await _client.rpc<List<dynamic>>('admin_payouts');
    return list.map((p) => PayoutRequest.fromJson(p as Map<String, dynamic>)).toList();
  });

  @override
  Future<void> setPayout(String payoutId, {required bool paid, String note = ''}) => supabaseGuard(
    () => _client.rpc<void>(
      'set_payout_status',
      params: {'p_payout_id': int.parse(payoutId), 'p_paid': paid, 'p_note': note},
    ),
  );
}
