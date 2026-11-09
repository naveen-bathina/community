import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legal_unity_network/core/constants/app_constants.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';
import 'package:legal_unity_network/features/auth/domain/entities/auth_user.dart';
import 'package:legal_unity_network/features/profile/presentation/providers/profile_provider.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:legal_unity_network/shared/widgets/app_top_bar_actions.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final AuthUser currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firmController = TextEditingController();
  final _lawSchoolController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _practiceAreasController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _achievementsController = TextEditingController();
  final _clesController = TextEditingController();
  final _publicationsController = TextEditingController();
  final _imagePicker = ImagePicker();

  AvailabilityStatus _availability = AvailabilityStatus.acceptingReferrals;
  List<BarAdmission> _barAdmissions = [];
  String? _photoUrl;
  Uint8List? _pickedPhotoBytes;
  UserModel? _loadedProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _firmController.dispose();
    _lawSchoolController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _practiceAreasController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _achievementsController.dispose();
    _clesController.dispose();
    _publicationsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .getProfile(widget.currentUser.uid);
      if (!mounted) return;
      if (profile != null) {
        _loadedProfile = profile;
        _nameController.text = profile.name.isNotEmpty
            ? profile.name
            : widget.currentUser.fullName;
        _phoneController.text =
            profile.phone ?? widget.currentUser.phoneNumber ?? '';
        _firmController.text = profile.firmOrganization ?? '';
        _lawSchoolController.text = profile.lawSchool ?? '';
        _experienceController.text =
            profile.yearsOfExperience != null ? '${profile.yearsOfExperience}' : '';
        _bioController.text = profile.bio ?? '';
        _practiceAreasController.text =
            (profile.practiceAreas ?? const []).join(', ');
        _cityController.text = profile.city ?? '';
        _stateController.text = profile.state ?? '';
        _achievementsController.text = profile.achievements ?? '';
        _clesController.text = profile.cles ?? '';
        _publicationsController.text = profile.publications ?? '';
        _availability =
            profile.availabilityStatus ?? AvailabilityStatus.acceptingReferrals;
        _barAdmissions = List<BarAdmission>.from(profile.barAdmissions ?? const []);
        _photoUrl = profile.photoUrl ?? widget.currentUser.photoUrl;
      } else {
        _nameController.text = widget.currentUser.fullName;
        _phoneController.text = widget.currentUser.phoneNumber ?? '';
        _photoUrl = widget.currentUser.photoUrl;
        if (widget.currentUser.stateBarAssociation != null &&
            widget.currentUser.enrollmentNumber != null) {
          _barAdmissions = [
            BarAdmission(
              jurisdiction: widget.currentUser.stateBarAssociation!,
              barNumber: widget.currentUser.enrollmentNumber!,
              yearAdmitted: DateTime.now().year,
            ),
          ];
        }
      }
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedPhotoBytes = bytes;
          _photoUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (_) {}
  }

  Future<void> _showAddBarAdmissionDialog() async {
    String selectedCouncil = AppConstants.stateBarCouncils.first;
    final barNumberCtrl = TextEditingController();
    final startYearCtrl =
        TextEditingController(text: '${DateTime.now().year}');
    final endYearCtrl = TextEditingController();
    bool isPracticingCurrent = true;

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Bar Admission'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('bar_council_dropdown'),
                    initialValue: selectedCouncil,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'State Bar Council',
                    ),
                    items: AppConstants.stateBarCouncils
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCouncil = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('bar_number_input'),
                    controller: barNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Enrollment Number',
                      hintText: 'e.g. KAR/1234/2020',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('bar_start_year_input'),
                    controller: startYearCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Start Year',
                      hintText: 'e.g. 2020',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    key: const Key('bar_practicing_current_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Practicing Current'),
                    subtitle: const Text('Currently active advocate'),
                    value: isPracticingCurrent,
                    onChanged: (val) {
                      setDialogState(() => isPracticingCurrent = val);
                    },
                  ),
                  if (!isPracticingCurrent) ...[
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('bar_end_year_input'),
                      controller: endYearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'End Year',
                        hintText: 'e.g. 2024',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const Key('confirm_add_bar_button'),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    if (added == true &&
        selectedCouncil.trim().isNotEmpty &&
        barNumberCtrl.text.trim().isNotEmpty) {
      final startYear =
          int.tryParse(startYearCtrl.text.trim()) ?? DateTime.now().year;
      final endYear = isPracticingCurrent
          ? null
          : int.tryParse(endYearCtrl.text.trim());

      setState(() {
        _barAdmissions.add(
          BarAdmission(
            jurisdiction: selectedCouncil.trim(),
            barNumber: barNumberCtrl.text.trim(),
            yearAdmitted: startYear,
            endYear: endYear,
            isCurrentlyPracticing: isPracticingCurrent,
          ),
        );
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final areas = _practiceAreasController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final yearsExp = int.tryParse(_experienceController.text.trim());

    final base = _loadedProfile ??
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
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : base.name,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : base.phone,
      photoUrl: _photoUrl,
      barAdmissions: _barAdmissions,
      lawSchool: _lawSchoolController.text.trim(),
      yearsOfExperience: yearsExp,
      firmOrganization: _firmController.text.trim(),
      bio: _bioController.text.trim(),
      practiceAreas: areas,
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      availabilityStatus: _availability,
      achievements: _achievementsController.text.trim(),
      cles: _clesController.text.trim(),
      publications: _publicationsController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final error =
        await ref.read(profileRepositoryProvider).updateProfile(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ref.invalidate(directoryMembersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(updated);
      }
    }
  }

  ImageProvider? _buildAvatar() {
    if (_pickedPhotoBytes != null) {
      return MemoryImage(_pickedPhotoBytes!);
    }
    final url = _photoUrl;
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

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Professional Profile'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: const [
          AppTopBarActions(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: avatar,
                        child: avatar == null
                            ? const Icon(Icons.person, size: 42)
                            : null,
                      ),
                      TextButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Change Profile Photo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('edit_name_input'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('edit_phone_input'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('edit_firm_input'),
                  controller: _firmController,
                  decoration: const InputDecoration(
                    labelText: 'Law Firm / Chambers',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        key: const Key('edit_law_school_input'),
                        controller: _lawSchoolController,
                        decoration: const InputDecoration(
                          labelText: 'Law School / University',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: const Key('edit_experience_input'),
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Years Exp.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('edit_practice_areas_input'),
                  controller: _practiceAreasController,
                  decoration: const InputDecoration(
                    labelText: 'Practice Areas (comma-separated)',
                    prefixIcon: Icon(Icons.gavel_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('edit_city_input'),
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: const Key('edit_state_input'),
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'State',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AvailabilityStatus>(
                  initialValue: _availability,
                  decoration: const InputDecoration(
                    labelText: 'Referral Availability',
                  ),
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
                      setState(() => _availability = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bar Admissions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('add_bar_admission_btn'),
                      onPressed: _showAddBarAdmissionDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Admission'),
                    ),
                  ],
                ),
                ..._barAdmissions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final b = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.verified_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                      title: Text(b.jurisdiction),
                      subtitle: Text('${b.barNumber} (${b.yearSpanText})'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () {
                          setState(() => _barAdmissions.removeAt(idx));
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('edit_bio_input'),
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Professional Bio',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('edit_achievements_input'),
                  controller: _achievementsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notable Achievements & Honors',
                    prefixIcon: Icon(Icons.emoji_events_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('edit_cles_input'),
                  controller: _clesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'CLEs & Certifications',
                    prefixIcon: Icon(Icons.workspace_premium_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('edit_publications_input'),
                  controller: _publicationsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Publications & Speaking Engagements',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('save_profile_button'),
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                ),
              ],
            ),
    );
  }
}
