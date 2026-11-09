import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/profile/presentation/providers/profile_provider.dart';
import 'package:legal_unity_network/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:legal_unity_network/shared/widgets/app_top_bar_actions.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  final AuthUser currentUser;

  const MyProfileScreen({super.key, required this.currentUser});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  UserModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final loaded = await ref
          .read(profileRepositoryProvider)
          .getProfile(widget.currentUser.uid);
      if (!mounted) return;
      setState(() {
        _profile = loaded;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  ImageProvider? _buildAvatar(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      final commaIdx = url.indexOf(',');
      if (commaIdx != -1) {
        try {
          return MemoryImage(base64Decode(url.substring(commaIdx + 1)));
        } catch (_) {
          return null;
        }
      }
    }
    return NetworkImage(url);
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<UserModel?>(
        builder: (_) => EditProfileScreen(currentUser: widget.currentUser),
      ),
    );
    await _loadProfile();
  }

  Future<void> _updateAvailability(AvailabilityStatus status) async {
    final base = _profile ??
        UserModel(
          userId: widget.currentUser.uid,
          email: widget.currentUser.email,
          name: widget.currentUser.fullName,
          status: widget.currentUser.status,
          role: widget.currentUser.role,
          createdAt: widget.currentUser.createdAt,
          updatedAt: DateTime.now(),
        );
    final updated = base.copyWith(
      availabilityStatus: status,
      updatedAt: DateTime.now(),
    );
    await ref.read(profileRepositoryProvider).updateProfile(updated);
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final displayName = (p != null && p.name.isNotEmpty)
        ? p.name
        : widget.currentUser.fullName;
    final photoUrl = p?.photoUrl ?? widget.currentUser.photoUrl;
    final avatar = _buildAvatar(photoUrl);
    final email = p?.email.isNotEmpty == true
        ? p!.email
        : widget.currentUser.email;
    final phone = p?.phone ?? widget.currentUser.phoneNumber;
    final location = [p?.city, p?.state]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
    final availability =
        p?.availabilityStatus ?? AvailabilityStatus.acceptingReferrals;
    final barAdmissions = (p?.barAdmissions != null &&
            p!.barAdmissions!.isNotEmpty)
        ? p.barAdmissions!
        : (widget.currentUser.stateBarAssociation != null
            ? [
                BarAdmission(
                  jurisdiction: widget.currentUser.stateBarAssociation!,
                  barNumber: widget.currentUser.enrollmentNumber ?? 'Verified',
                  yearAdmitted: widget.currentUser.createdAt.year,
                ),
              ]
            : <BarAdmission>[]);

    final isComplete = p?.isProfileComplete ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            key: const Key('appbar_edit_profile_btn'),
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEditProfile,
          ),
          const AppTopBarActions(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header Identity Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundImage: avatar,
                            child: avatar == null
                                ? const Icon(Icons.person, size: 44)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (p?.firmOrganization != null &&
                              p!.firmOrganization!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              p.firmOrganization!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              Chip(
                                avatar: const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                                label: Text(
                                  '${widget.currentUser.role.value.toUpperCase()} • ${widget.currentUser.status.value.toUpperCase()}',
                                ),
                              ),
                              if (p?.yearsOfExperience != null)
                                Chip(
                                  label: Text(
                                    '${p!.yearsOfExperience} Years Experience',
                                  ),
                                ),
                              Chip(
                                backgroundColor: isComplete
                                    ? AppTheme.successGreen
                                        .withValues(alpha: 0.15)
                                    : AppTheme.warningOrange
                                        .withValues(alpha: 0.15),
                                label: Text(
                                  isComplete
                                      ? 'Profile Complete'
                                      : 'Complete Your Profile',
                                  style: TextStyle(
                                    color: isComplete
                                        ? AppTheme.successGreen
                                        : AppTheme.warningOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Referral Availability Toggle Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Referral Availability Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<AvailabilityStatus>(
                            key: const Key('quick_availability_dropdown'),
                            initialValue: availability,
                            items: AvailabilityStatus.values
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                _updateAvailability(val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Contact & Legal Credentials Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Credentials & Contact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 20),
                          _ProfileInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: email,
                          ),
                          if (phone != null && phone.isNotEmpty)
                            _ProfileInfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Mobile',
                              value: phone,
                            ),
                          if (p?.lawSchool != null && p!.lawSchool!.isNotEmpty)
                            _ProfileInfoRow(
                              icon: Icons.school_outlined,
                              label: 'Law School',
                              value: p.lawSchool!,
                            ),
                          if (barAdmissions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Bar Admissions',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...barAdmissions.map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.account_balance_outlined,
                                      size: 18,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        b.jurisdiction,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${b.barNumber} (${b.yearSpanText})',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryLight,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Practice Areas & Bio Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Practice Areas & Bio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 20),
                          if (p?.practiceAreas != null &&
                              p!.practiceAreas!.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: p.practiceAreas!
                                  .map((area) => Chip(label: Text(area)))
                                  .toList(),
                            )
                          else
                            const Text(
                              'No practice areas added yet.',
                              style: TextStyle(
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          if (p?.bio != null && p!.bio!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              p.bio!,
                              style: const TextStyle(height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Achievements, CLEs & Publications Card
                  if ((p?.achievements != null &&
                          p!.achievements!.isNotEmpty) ||
                      (p?.cles != null && p!.cles!.isNotEmpty) ||
                      (p?.publications != null &&
                          p!.publications!.isNotEmpty)) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Honors, CLEs & Publications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 20),
                            if (p.achievements != null &&
                                p.achievements!.isNotEmpty)
                              _ProfileInfoRow(
                                icon: Icons.emoji_events_outlined,
                                label: 'Achievements',
                                value: p.achievements!,
                              ),
                            if (p.cles != null && p.cles!.isNotEmpty)
                              _ProfileInfoRow(
                                icon: Icons.workspace_premium_outlined,
                                label: 'CLEs',
                                value: p.cles!,
                              ),
                            if (p.publications != null &&
                                p.publications!.isNotEmpty)
                              _ProfileInfoRow(
                                icon: Icons.menu_book_outlined,
                                label: 'Publications',
                                value: p.publications!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
