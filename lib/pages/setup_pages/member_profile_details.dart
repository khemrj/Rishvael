import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/media/photo_picker_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../models/member_setup_data.dart';

class MemberProfileDetailsPage extends StatefulWidget {
  const MemberProfileDetailsPage({
    super.key,
    required this.initialData,
    this.onCompleted,
  });

  final MemberSetupData initialData;
  final ValueChanged<MemberSetupData>? onCompleted;

  @override
  State<MemberProfileDetailsPage> createState() =>
      _MemberProfileDetailsPageState();
}

class _MemberProfileDetailsPageState
    extends State<MemberProfileDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _headlineController;
  late final TextEditingController _locationController;

  String? _profileImagePath;
  File? _profileImageFile;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadSavedProfileImage();
   
    final data = widget.initialData;

    final fullName = [
      data.firstName,
      data.lastName,
    ].whereType<String>().join(' ');

    final location = [
      data.city,
      data.country,
    ].whereType<String>().join(', ');

    _fullNameController = TextEditingController(
      text: fullName,
    );

    _headlineController = TextEditingController(
      text: data.headline ?? '',
    );

    _locationController = TextEditingController(
      text: location,
    );

    _profileImagePath = data.profileImagePath;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _headlineController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto) return; // Guards against double-taps

    final source = await _showSourceSheet();
    if (source == null || !mounted) return;

    setState(() => _isPickingPhoto = true);

    try {
      final result = await PhotoPickerService.pick(source: source);

      if (!mounted) return;

      switch (result) {
        case PhotoPickSuccess(:final file):
          // 1. Copy to permanent app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final permanentFile = await file.copy('${appDir.path}/profile_image_${DateTime.now().millisecondsSinceEpoch}.png');
          
          // 2. Save the path to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_path', permanentFile.path);

          setState(() {
            _profileImageFile = permanentFile;
            _profileImagePath = permanentFile.path;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to: ${_profileImageFile?.path}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          break;

        case PhotoPickCancelled():
          break; // User backed out — nothing to change

        case PhotoPickFailure(:final message):
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<ImageSource?> _showSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.ink),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.error),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _finish() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nameParts = _splitName(
      _fullNameController.text.trim(),
    );

    final location = _parseLocation(
      _locationController.text.trim(),
    );

    final data = widget.initialData.copyWith(
      firstName: nameParts.$1,
      lastName: nameParts.$2,
      headline: _headlineController.text.trim(),
      city: location.$1,
      country: location.$2,
      profileImagePath: _profileImagePath,
    );

    widget.onCompleted?.call(data);

    if (widget.onCompleted == null) {
     
    }
  }

  (String, String) _splitName(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return ('', '');
    }

    if (parts.length == 1) {
      return (parts.first, '');
    }

    return (
      parts.first,
      parts.skip(1).join(' '),
    );
  }

  (String, String) _parseLocation(String value) {
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return ('', '');
    }

    if (parts.length == 1) {
      return (parts.first, '');
    }

    return (
      parts.first,
      parts.skip(1).join(', '),
    );
  }

  Future<void> _loadSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profile_image_path');

    if (savedPath != null) {
      final savedFile = File(savedPath);
      if (await savedFile.exists()) {
        setState(() {
          _profileImagePath = savedPath;
          _profileImageFile = savedFile;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.navy,
            ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        appBar: AppBar(
          title: const Text('Profile Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.ivoryMuted,
                        backgroundImage: _profileImageFile != null
                            ? FileImage(_profileImageFile!) as ImageProvider
                            : null,
                        child: _profileImageFile == null
                            ? const Icon(Icons.person, size: 50, color: AppColors.navy)
                            : null,
                      ),
                      if (_isPickingPhoto)
                        const Positioned.fill(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isPickingPhoto ? null : _pickPhoto,
                    child: const Text(
                      'Change Profile Photo',
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.navyCard, width: 2),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _headlineController,
                  decoration: InputDecoration(
                    labelText: 'Headline',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.ink, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location (City, Country)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.ink, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _finish,
                  child: const Text(
                    'Save and Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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