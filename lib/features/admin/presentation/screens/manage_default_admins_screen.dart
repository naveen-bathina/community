import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/constants/app_constants.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';

/// Screen accessible exclusively by the Super User (naveen.bathina9@gmail.com)
/// to configure and appoint default/founding administrators for the union.
class ManageDefaultAdminsScreen extends ConsumerStatefulWidget {
  const ManageDefaultAdminsScreen({super.key});

  @override
  ConsumerState<ManageDefaultAdminsScreen> createState() =>
      _ManageDefaultAdminsScreenState();
}

class _ManageDefaultAdminsScreenState
    extends ConsumerState<ManageDefaultAdminsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  UserRole _selectedRole = UserRole.foundingAdmin;
  bool _isSubmitting = false;
  String _memberSearchQuery = '';

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _appointAdminByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid advocate email address')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await ref.read(authProvider.notifier).setDefaultAdminByEmail(
          email,
          role: _selectedRole,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.errorRed),
      );
    } else {
      _emailController.clear();
      ref.invalidate(allMembersForSuperUserProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully appointed $email as ${_roleLabel(_selectedRole)}!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  Future<void> _updateMemberRole(AuthUser member, UserRole newRole) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Role for ${member.fullName}'),
        content: Text(
          'Are you sure you want to set role to ${_roleLabel(newRole)} for ${member.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await ref.read(authProvider.notifier).updateUserRole(
          targetUserId: member.uid,
          newRole: newRole,
        );
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.errorRed),
      );
    } else {
      ref.invalidate(allMembersForSuperUserProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated ${member.fullName} to ${_roleLabel(newRole)}',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super User';
      case UserRole.foundingAdmin:
        return 'Founding Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.member:
        return 'Member';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.amber.shade800;
      case UserRole.foundingAdmin:
        return AppTheme.primaryBlue;
      case UserRole.admin:
        return Colors.teal.shade700;
      case UserRole.member:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersForSuperUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Default Admins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Members',
            onPressed: () => ref.invalidate(allMembersForSuperUserProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Super User Authorization Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade100,
                  Colors.amber.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade400, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade800,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Super User Governance Control',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D3E00),
                            ),
                          ),
                          Text(
                            AppConfig.superAdminEmail,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'As the designated Super User, you have the initial authority to set and bootstrap '
                  'the Founding Council of up to ${AppConstants.foundingAdminCount} Default Admins. '
                  'Founding Admins verify applicant credentials and moderate the platform until the first democratic election.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.brown.shade900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Appoint by Email Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_add_alt_1, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Appoint Default Admin by Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Advocate Email Address',
                      hintText: 'advocate@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Admin Designation',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.foundingAdmin,
                        child: Text('Founding Admin (Initial Council)'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.admin,
                        child: Text('Regular Admin'),
                      ),
                    ],
                    onChanged: (role) {
                      if (role != null) setState(() => _selectedRole = role);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.how_to_reg),
                      label: const Text('Appoint as Default Admin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : _appointAdminByEmail,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Administrators & Founding Council List
          membersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading member roster: $err'),
              ),
            ),
            data: (allMembers) {
              // Ensure super user is included if not in DB yet
              final members = List<AuthUser>.from(allMembers);
              if (!members.any((u) => AppConfig.isSuperAdminEmail(u.email))) {
                members.insert(
                  0,
                  AuthUser(
                    uid: 'super-user-naveen',
                    email: AppConfig.superAdminEmail,
                    firstName: 'Naveen',
                    lastName: 'Bathina',
                    status: UserStatus.approved,
                    role: UserRole.superAdmin,
                    createdAt: DateTime(2026, 1, 1),
                    updatedAt: DateTime(2026, 1, 1),
                  ),
                );
              }

              final admins = members.where((u) => u.isAdmin || u.isSuperAdmin).toList();
              final regularMembers = members.where((u) => !u.isAdmin && !u.isSuperAdmin).toList();

              final filteredRegular = regularMembers.where((u) {
                if (_memberSearchQuery.isEmpty) return true;
                final q = _memberSearchQuery.toLowerCase();
                return u.fullName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q) ||
                    (u.enrollmentNumber?.toLowerCase().contains(q) ?? false);
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Admin Council (${admins.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          '${admins.where((a) => a.role == UserRole.foundingAdmin).length} / ${AppConstants.foundingAdminCount} Founding',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...admins.map((admin) {
                    final isSelf = AppConfig.isSuperAdminEmail(admin.email);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _roleColor(admin.role).withValues(alpha: 0.15),
                          child: Icon(
                            isSelf
                                ? Icons.verified_user
                                : admin.role == UserRole.foundingAdmin
                                    ? Icons.stars
                                    : Icons.admin_panel_settings,
                            color: _roleColor(admin.role),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                admin.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _roleColor(admin.role).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _roleColor(admin.role)),
                              ),
                              child: Text(
                                _roleLabel(admin.role),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _roleColor(admin.role),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(admin.email),
                            if (admin.enrollmentNumber != null)
                              Text(
                                'Enrollment: ${admin.enrollmentNumber}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: isSelf
                            ? const Tooltip(
                                message: 'Super User (Permanent)',
                                child: Icon(Icons.lock, size: 18, color: Colors.amber),
                              )
                            : PopupMenuButton<UserRole>(
                                tooltip: 'Change Role',
                                icon: const Icon(Icons.more_vert),
                                onSelected: (newRole) =>
                                    _updateMemberRole(admin, newRole),
                                itemBuilder: (context) => [
                                  if (admin.role != UserRole.foundingAdmin)
                                    const PopupMenuItem(
                                      value: UserRole.foundingAdmin,
                                      child: Text('Set as Founding Admin'),
                                    ),
                                  if (admin.role != UserRole.admin)
                                    const PopupMenuItem(
                                      value: UserRole.admin,
                                      child: Text('Set as Regular Admin'),
                                    ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: UserRole.member,
                                    child: Text(
                                      'Demote to Member',
                                      style: TextStyle(color: AppTheme.errorRed),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Registered Members section
                  const Text(
                    'Registered Members Roster',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search members by name, email, or enrollment...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _memberSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _memberSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) => setState(() => _memberSearchQuery = val),
                  ),
                  const SizedBox(height: 8),

                  if (filteredRegular.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            _memberSearchQuery.isNotEmpty
                                ? 'No members match "$_memberSearchQuery"'
                                : 'No additional registered members available',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredRegular.map(
                      (member) => Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          title: Text(member.fullName),
                          subtitle: Text(
                            '${member.email}${member.enrollmentNumber != null ? " • ${member.enrollmentNumber}" : ""}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: AppTheme.primaryBlue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () => _updateMemberRole(
                              member,
                              UserRole.foundingAdmin,
                            ),
                            child: const Text('Make Founding Admin'),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
