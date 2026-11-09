import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/election/domain/entities/election.dart';
import 'package:legal_unity_network/features/election/domain/repositories/election_repository.dart';
import 'package:legal_unity_network/features/election/presentation/providers/election_provider.dart';
import 'package:legal_unity_network/features/election/presentation/screens/elections_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeElectionRepository implements ElectionRepository {
  Election _activeElection = Election(
    id: 'elec-2026',
    title: 'Bar Council Executive Committee Election 2026',
    description: 'Annual democratic election for community moderators and officers.',
    status: 'voting_open',
    candidates: [
      const ElectionCandidate(
        id: 'cand-1',
        candidateId: 'u-101',
        candidateName: 'Adv. Priya Sharma',
        manifesto: 'Transparent digital referrals & mentorship for junior counsel.',
        voteCount: 14,
      ),
      const ElectionCandidate(
        id: 'cand-2',
        candidateId: 'u-102',
        candidateName: 'Adv. Rajesh Verma',
        manifesto: 'Stronger state bar coordination and pro-bono legal aid cells.',
        voteCount: 11,
      ),
    ],
    votedCandidateId: null,
  );

  @override
  Future<Election?> getActiveElection(String currentUserId) async {
    return _activeElection;
  }

  @override
  Future<void> nominateSelf({
    required String electionId,
    required String candidateId,
    required String candidateName,
    required String manifesto,
  }) async {
    final updated = [
      ..._activeElection.candidates,
      ElectionCandidate(
        id: 'cand-${_activeElection.candidates.length + 1}',
        candidateId: candidateId,
        candidateName: candidateName,
        manifesto: manifesto,
        voteCount: 0,
      ),
    ];
    _activeElection = _activeElection.copyWith(candidates: updated);
  }

  @override
  Future<void> castVote({
    required String electionId,
    required String voterId,
    required String candidateId,
  }) async {
    if (_activeElection.votedCandidateId != null) return;
    final updated = _activeElection.candidates.map((c) {
      if (c.id == candidateId) {
        return c.copyWith(voteCount: c.voteCount + 1);
      }
      return c;
    }).toList();
    _activeElection = _activeElection.copyWith(
      candidates: updated,
      votedCandidateId: candidateId,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'ElectionsScreen displays candidates, allows nominating self, and casting a single vote',
    (WidgetTester tester) async {
      final fakeRepo = FakeElectionRepository();
      final memberUser = AuthUser(
        uid: 'u-200',
        email: 'arjun@legalunity.org',
        firstName: 'Arjun',
        lastName: 'Mehta',
        role: UserRole.member,
        status: UserStatus.approved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            electionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: ElectionsScreen(currentUser: memberUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify election title & initial candidates
      expect(
        find.text('Bar Council Executive Committee Election 2026'),
        findsOneWidget,
      );
      expect(find.text('Adv. Priya Sharma'), findsOneWidget);
      expect(find.text('14 votes'), findsOneWidget);

      // Nominate self
      await tester.tap(find.byKey(const Key('nominate_self_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('manifesto_input')),
        'Modernizing court diary alerts for all members.',
      );
      await tester.tap(find.byKey(const Key('submit_nomination_button')));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Arjun Mehta'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Arjun Mehta'), findsOneWidget);
      expect(
        find.text('Modernizing court diary alerts for all members.'),
        findsOneWidget,
      );

      // Cast vote for Adv. Priya Sharma (cand-1)
      await tester.scrollUntilVisible(
        find.byKey(const Key('vote_button_cand-1')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('vote_button_cand-1')));
      await tester.pumpAndSettle();

      expect(find.text('15 votes'), findsOneWidget);
      expect(find.text('Voted'), findsOneWidget);
    },
  );
}
