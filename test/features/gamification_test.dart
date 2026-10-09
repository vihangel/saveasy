import 'package:flutter_test/flutter_test.dart';
import 'package:saveeasy2026/features/create_post/create_post_cubit.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_database.dart';
import 'package:saveeasy2026/shared/data/datasources/mock_seed.dart';
import 'package:saveeasy2026/shared/data/models/models.dart';
import 'package:saveeasy2026/shared/data/repositories/repositories.dart';
import 'package:saveeasy2026/shared/notifiers/session_cubit.dart';

import '../helpers/test_database.dart';

void main() {
  late MockDatabase db;
  late SessionCubit session;

  setUp(() async {
    final (database, storage) = await createTestDatabase();
    db = database;
    final auth = MockAuthRepository(db, storage);
    await auth.login(MockSeed.demoEmail, MockSeed.demoPassword);
    session = SessionCubit(auth);
    await session.restore();
  });

  test('equipar aceita no máximo 3 selos', () async {
    final gamification = MockGamificationRepository(db);
    final user = await gamification.equip(userId: MockSeed.demoUserId, titleId: 'r_title_green', badgeIds: ['a', 'b']);
    expect(user.titleId, 'r_title_green');
    expect(user.badgeIds, ['a', 'b']);
    expect(
      gamification.equip(userId: MockSeed.demoUserId, badgeIds: ['a', 'b', 'c', 'd']),
      throwsA(isA<AppException>()),
    );
  });

  test('pedido de item segue o fluxo pedido → aceito → entregue', () async {
    final engagement = MockEngagementRepository(db);
    final request = await engagement.requestItem('p_reciclagem', message: 'Preciso');
    expect(request.status, ItemRequestStatus.requested);
    await engagement.updateItemRequest(request.id, ItemRequestStatus.accepted);
    final delivered = await engagement.updateItemRequest(request.id, ItemRequestStatus.delivered);
    expect(delivered.status, ItemRequestStatus.delivered);
    expect((await engagement.itemRequests('p_reciclagem')).single.status, ItemRequestStatus.delivered);
  });

  test('criar publicação salva as pessoas marcadas', () async {
    final engagement = MockEngagementRepository(db);
    final cubit = CreatePostCubit(PostType.discussion, MockPostRepository(db), session, engagement: engagement);
    final friend = db.users.firstWhere((u) => u.id != MockSeed.demoUserId);
    cubit.setMentions([friend]);
    await cubit.submit(
      const CreatePostInput(title: 'Ideias para o Parque', description: 'Vamos conversar sobre o parque.'),
    );
    final postId = cubit.state.createdPostId!;
    expect((await engagement.extras(postId)).mentions.single.id, friend.id);
    await cubit.close();
  });

  test('orçamento de anúncio aplica desconto do plano e cidade extra', () async {
    final ads = MockAdsRepository();
    final week = await ads.quote(AdFormat.bar, AdPlan.weekly, ['Cuiabá']);
    expect(week.days, 7);
    expect(week.price, closeTo(9.90 * 7 * 0.85, 0.01));
    final twoCities = await ads.quote(AdFormat.bar, AdPlan.weekly, ['Cuiabá', 'Várzea Grande']);
    expect(twoCities.price, closeTo(week.price * 1.3, 0.02));
    final campaign = await ads.create(format: AdFormat.bar, plan: AdPlan.daily, title: 'Ecoponto aberto');
    expect(campaign.status, AdStatus.pendingPayment);
    expect((await ads.myCampaigns()).single.id, campaign.id);
  });
}
