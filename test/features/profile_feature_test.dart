import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_unity_network/features/profile/domain/repositories/profile_repository.dart';
import 'package:legal_unity_network/features/profile/presentation/providers/profile_provider.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/directory_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InMemoryProfileRepository implements ProfileRepository {
  final List<UserModel> _members;

  InMemoryProfileRepository(this._members);

  @override
  Future<List<UserModel>> getApprovedMembers({
    String? searchQuery,
    String? practiceArea,
    AvailabilityStatus? availability,
  }) async {
    return _members.where((m) {
      if (m.status != UserStatus.approved) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchesName = m.name.toLowerCase().contains(q);
        final matchesCity = (m.city ?? '').toLowerCase().contains(q);
        final matchesFirm =
            (m.firmOrganization ?? '').toLowerCase().contains(q);
        if (!matchesName && !matchesCity && !matchesFirm) return false;
      }
      if (practiceArea != null && practiceArea.isNotEmpty) {
        if (!(m.practiceAreas ?? []).contains(practiceArea)) return false;
      }
      if (availability != null) {
        if (m.availabilityStatus != availability) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<UserModel?> getProfile(String userId) async {
    for (final m in _members) {
      if (m.userId == userId) return m;
    }
    return null;
  }

  @override
  Future<String?> updateProfile(UserModel updatedProfile) async {
    final idx =
        _members.indexWhere((m) => m.userId == updatedProfile.userId);
    if (idx != -1) {
      _members[idx] = updatedProfile;
    } else {
      _members.add(updatedProfile);
    }
    return null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleMembers = [
    UserModel(
      userId: 'm-1',
      email: 'priya@law.in',
      phone: '+919811111111',
      name: 'Priya Nair',
      status: UserStatus.approved,
      role: UserRole.member,
      practiceAreas: const ['Family Law', 'Mediation'],
      firmOrganization: 'Nair & Associates',
      yearsOfExperience: 8,
      city: 'Bengaluru',
      state: 'Karnataka',
      bio: 'Family law specialist in Bengaluru',
      availabilityStatus: AvailabilityStatus.acceptingReferrals,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    UserModel(
      userId: 'm-2',
      email: 'rohan@corp.in',
      phone: '+919822222222',
      name: 'Rohan Mehta',
      status: UserStatus.approved,
      role: UserRole.member,
      practiceAreas: const ['Corporate Law', 'Tax Law'],
      firmOrganization: 'Mehta Chambers',
      yearsOfExperience: 12,
      city: 'Mumbai',
      state: 'Maharashtra',
      bio: 'Corporate M&A counsel',
      availabilityStatus: AvailabilityStatus.availableForConsultation,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  testWidgets(
      'DirectoryScreen lists approved members and filters by search query and practice area',
      (WidgetTester tester) async {
    final repo = InMemoryProfileRepository(List.of(sampleMembers));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: DirectoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Both approved members are displayed initially
    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('Rohan Mehta'), findsOneWidget);

    // Filter by search query "Mumbai"
    await tester.enterText(
      find.byKey(const Key('directory_search_field')),
      'Mumbai',
    );
    await tester.pumpAndSettle();

    expect(find.text('Rohan Mehta'), findsOneWidget);
    expect(find.text('Priya Nair'), findsNothing);

    // Clear search and filter by practice area "Family Law"
    await tester.enterText(
      find.byKey(const Key('directory_search_field')),
      '',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Family Law').first);
    await tester.pumpAndSettle();

    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('Rohan Mehta'), findsNothing);
  });
}
