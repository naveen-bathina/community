import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:legal_unity_network/core/utils/validation_utils.dart';
import 'package:legal_unity_network/features/auth/domain/entities/join_request.dart';
import 'package:legal_unity_network/features/auth/presentation/providers/auth_provider.dart';

/// Screen where a newly signed-up user submits their Join Request details
/// (First Name, Last Name, Date Of Birth, Gender, Mobile Number,
/// State Bar Association, Enrollment Number, and Profile Picture) for admin verification.
class JoinRequestScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const JoinRequestScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  ConsumerState<JoinRequestScreen> createState() => _JoinRequestScreenState();
}

class _JoinRequestScreenState extends ConsumerState<JoinRequestScreen> {
  static const List<String> _genders = [
    'Male',
    'Female',
    'Other',
  ];

  static const List<String> _stateBarAssociations = [
    'Bar Council of Andhra Pradesh',
    'Bar Council of Assam, Nagaland, Mizoram, Arunachal Pradesh & Sikkim',
    'Bar Council of Bihar',
    'Bar Council of Chhattisgarh',
    'Bar Council of Delhi',
    'Bar Council of Gujarat',
    'Bar Council of Himachal Pradesh',
    'Bar Council of Jammu & Kashmir',
    'Bar Council of Jharkhand',
    'Bar Council of Karnataka',
    'Bar Council of Kerala',
    'Bar Council of Madhya Pradesh',
    'Bar Council of Maharashtra & Goa',
    'Bar Council of Odisha',
    'Bar Council of Punjab & Haryana',
    'Bar Council of Rajasthan',
    'Bar Council of Tamil Nadu & Puducherry',
    'Bar Council of Telangana',
    'Bar Council of Tripura',
    'Bar Council of Uttar Pradesh',
    'Bar Council of Uttarakhand',
    'Bar Council of West Bengal',
    'Other State Bar Association',
  ];

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _imagePicker = ImagePicker();

  DateTime? _selectedDob;
  String? _selectedGender;
  String? _selectedStateBar;
  Uint8List? _pickedPhotoBytes;
  String? _existingPhotoUrl;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      if (user.dateOfBirth != null) {
        _selectedDob = user.dateOfBirth;
        _dobController.text =
            DateFormat('dd MMM yyyy').format(user.dateOfBirth!);
      }
      if (user.gender != null && _genders.contains(user.gender)) {
        _selectedGender = user.gender;
      }
      _mobileController.text = user.phoneNumber ?? '';
      if (user.stateBarAssociation != null &&
          _stateBarAssociations.contains(user.stateBarAssociation)) {
        _selectedStateBar = user.stateBarAssociation;
      }
      _enrollmentController.text = user.enrollmentNumber ?? '';
      _existingPhotoUrl = user.photoUrl;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _enrollmentController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final initial = _selectedDob ?? DateTime(now.year - 28, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate:
          initial.isAfter(eighteenYearsAgo) ? eighteenYearsAgo : initial,
      firstDate: DateTime(1930, 1, 1),
      lastDate: eighteenYearsAgo,
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _pickedPhotoBytes = bytes;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not select image: $e';
        });
      }
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickProfilePhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickProfilePhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _buildAvatarImage() {
    if (_pickedPhotoBytes != null) {
      return MemoryImage(_pickedPhotoBytes!);
    }
    final url = _existingPhotoUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          try {
            return MemoryImage(base64Decode(url.substring(commaIdx + 1)));
          } catch (_) {
            return null;
          }
        }
      } else {
        return NetworkImage(url);
      }
    }
    return null;
  }

  Future<void> _submitJoinRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDob == null) {
      setState(() => _error = 'Date of Birth is required');
      return;
    }
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      setState(() => _error = 'Gender is required');
      return;
    }
    if (_selectedStateBar == null || _selectedStateBar!.isEmpty) {
      setState(() => _error = 'State Bar Association is required');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final input = JoinRequestInput(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _selectedDob!,
      gender: _selectedGender!,
      mobileNumber: _mobileController.text.trim(),
      stateBarAssociation: _selectedStateBar!,
      enrollmentNumber: _enrollmentController.text.trim(),
      profilePhotoBytes: _pickedPhotoBytes,
      existingPhotoUrl: _existingPhotoUrl,
    );

    final error =
        await ref.read(authProvider.notifier).submitJoinRequest(input);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _error = error;
    });

    if (error == null && widget.isEditing && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _buildAvatarImage();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Update Join Request' : 'Join Request'),
        actions: [
          if (!widget.isEditing)
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authProvider.notifier).signOut(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Complete Your Advocate Verification',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit your details and bar credentials below. An admin will verify your request and approve your membership.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Profile Picture Picker
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isSubmitting ? null : _showPhotoSourceSheet,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  size: 36,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _isSubmitting ? null : _showPhotoSourceSheet,
                        icon: const Icon(Icons.upload),
                        label: Text(
                          avatarImage == null
                              ? 'Upload Profile Picture *'
                              : 'Change Profile Picture',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (val) =>
                      ValidationUtils.validateRequired(val, 'First Name'),
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (val) =>
                      ValidationUtils.validateRequired(val, 'Last Name'),
                ),
                const SizedBox(height: 16),

                // Date Of Birth
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _isSubmitting ? null : _pickDateOfBirth,
                  decoration: const InputDecoration(
                    labelText: 'Date Of Birth *',
                    hintText: 'Select Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (val) =>
                      ValidationUtils.validateRequired(val, 'Date Of Birth'),
                ),
                const SizedBox(height: 16),

                // Gender
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: _genders
                      .map(
                        (g) => DropdownMenuItem<String>(
                          value: g,
                          child: Text(g),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) => setState(() => _selectedGender = val),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Gender is required' : null,
                ),
                const SizedBox(height: 16),

                // Mobile Number
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: '+91XXXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: ValidationUtils.validatePhone,
                ),
                const SizedBox(height: 16),

                // State Bar Association
                DropdownButtonFormField<String>(
                  initialValue: _selectedStateBar,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'State Bar Association *',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  items: _stateBarAssociations
                      .map(
                        (bar) => DropdownMenuItem<String>(
                          value: bar,
                          child: Text(
                            bar,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) => setState(() => _selectedStateBar = val),
                  validator: (val) => val == null || val.isEmpty
                      ? 'State Bar Association is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Enrollment Number
                TextFormField(
                  controller: _enrollmentController,
                  decoration: const InputDecoration(
                    labelText: 'Enrollment Number *',
                    hintText: 'e.g. KAR/1234/2020',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: ValidationUtils.validateBarNumber,
                ),
                const SizedBox(height: 24),

                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitJoinRequest,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.isEditing
                              ? 'Resubmit Join Request'
                              : 'Submit Join Request',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
