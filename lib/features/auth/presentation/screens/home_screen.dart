import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/features/election/presentation/screens/elections_screen.dart';
import 'package:legal_unity_network/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/directory_screen.dart';
import 'package:legal_unity_network/features/wall/presentation/screens/community_wall_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:legal_unity_network/shared/widgets/app_brand.dart';
import 'package:legal_unity_network/shared/widgets/app_top_bar_actions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<CommunityWallScreenState> _wallKey =
      GlobalKey<CommunityWallScreenState>();

  AuthUser _effectiveUser(AuthUser? user) {
    return user ??
        AuthUser(
          uid: 'guest-member',
          email: 'member@legalunity.org',
          firstName: 'Legal',
          lastName: 'Member',
          status: UserStatus.approved,
          role: UserRole.member,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final effectiveUser = _effectiveUser(user);
    final electionReleasedAsync = ref.watch(
      electionNotificationReleasedProvider(effectiveUser.uid),
    );
    final showElections = electionReleasedAsync.valueOrNull ?? false;

    final pages = <Widget>[
      _buildWallHomeTab(context, effectiveUser),
      const DirectoryScreen(),
      if (showElections) ElectionsScreen(currentUser: effectiveUser),
    ];

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline),
        label: 'Directory',
      ),
      if (showElections)
        const BottomNavigationBarItem(
          icon: Icon(Icons.how_to_vote_outlined),
          label: 'Elections',
        ),
    ];

    final safeIndex = _selectedIndex >= pages.length ? 0 : _selectedIndex;

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        items: navItems,
      ),
    );
  }

  Widget _buildWallHomeTab(BuildContext context, AuthUser effectiveUser) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 28, showBadgeBorder: true),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                AppConfig.appName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          AppTopBarActions(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_wall_post_button'),
        onPressed: () => _wallKey.currentState?.showCreatePostDialog(),
        icon: const Icon(Icons.post_add),
        label: const Text('New Post'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          children: [
            CommunityWallScreen(
              key: _wallKey,
              currentUser: effectiveUser,
            ),
          ],
        ),
      ),
    );
  }
}
