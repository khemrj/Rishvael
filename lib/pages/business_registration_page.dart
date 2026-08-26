import 'package:csc_picker/csc_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive.dart';
import '../models/address.dart';
import '../models/business.dart';
import '../providers/business_provider.dart';
// TODO: point this at your actual login page location.
// import 'login_page.dart';

/// Business/firm self-registration — creates a ROLE_BUSINESS User + a
/// pending Business profile together. On success, routes to login (this
/// endpoint doesn't issue a token — the account exists but isn't verified
/// yet, so there's nothing useful to be "logged in" to besides the pending
/// state screen, which /businesses/me + Business.canPostOpportunities
/// already covers once they do log in).
class BusinessRegistrationPage extends ConsumerStatefulWidget {
  const BusinessRegistrationPage({super.key});

  @override
  ConsumerState<BusinessRegistrationPage> createState() => _BusinessRegistrationPageState();
}

class _BusinessRegistrationPageState extends ConsumerState<BusinessRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _companyName = TextEditingController();
  final _registrationNumber = TextEditingController();
  final _website = TextEditingController();
  final _description = TextEditingController();
  final _street = TextEditingController();
  final _postalCode = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactPhone = TextEditingController();
  final _loginEmail = TextEditingController();
  final _password = TextEditingController();

  IndustryType? _industryType;
  CompanySize? _companySize;
  String _country = '';
  String _state = '';
  String _city = '';

  @override
  void dispose() {
    for (final c in [
      _companyName,
      _registrationNumber,
      _website,
      _description,
      _street,
      _postalCode,
      _contactEmail,
      _contactPhone,
      _loginEmail,
      _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Address get _headquarters => Address(
        street: _street.text.trim(),
        city: _city,
        state: _state,
        postalCode: _postalCode.text.trim(),
        country: _country,
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_headquarters.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select country, state, and city')),
      );
      return;
    }
    if (_industryType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an industry type')),
      );
      return;
    }

    final draft = BusinessRegistrationDraft(
      email: _loginEmail.text.trim(),
      password: _password.text,
      companyName: _companyName.text.trim(),
      registrationNumber: _registrationNumber.text.trim(),
      industryType: _industryType!,
      companySize: _companySize,
      website: _website.text.trim().isEmpty ? null : _website.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      headquarters: _headquarters,
      contactEmail: _contactEmail.text.trim(),
      contactPhone: _contactPhone.text.trim().isEmpty ? null : _contactPhone.text.trim(),
    );

    await ref.read(businessRegistrationControllerProvider.notifier).submit(draft);

    final result = ref.read(businessRegistrationControllerProvider);
    if (!mounted) return;

    result.whenOrNull(
      data: (business) {
        if (business == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registered — your profile is pending admin verification.'),
          ),
        );
        // rootNavigator: true so this works regardless of where this page
        // sits relative to any nested/adaptive-shell Navigator.
        // Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (_) => const LoginPage()),
        //   (route) => false,
        // );
      },
      error: (err, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $err')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(businessRegistrationControllerProvider);
    final isLoading = registrationState.isLoading;
    final wide = context.breakpoint.atLeastExpanded;

    return Scaffold(
      appBar: AppBar(title: const Text('Register your business')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: Insets.lg),
        child: ReadableWidth(
          maxWidth: 640,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Company details', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: Insets.md),
                _fieldRow(
                  wide,
                  _textField(_companyName, 'Company name', required: true),
                  _textField(_registrationNumber, 'Registration / tax number', required: true),
                ),
                SizedBox(height: Insets.md),
                _fieldRow(
                  wide,
                  DropdownButtonFormField<IndustryType>(
                    initialValue: _industryType,
                    decoration: const InputDecoration(labelText: 'Industry type'),
                    items: IndustryType.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _industryType = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  DropdownButtonFormField<CompanySize>(
                    initialValue: _companySize,
                    decoration: const InputDecoration(labelText: 'Company size (optional)'),
                    items: CompanySize.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _companySize = v),
                  ),
                ),
                SizedBox(height: Insets.md),
                _textField(_website, 'Website (optional)', required: false),
                SizedBox(height: Insets.md),
                _textField(_description, 'Short description (optional)', maxLines: 3),
                SizedBox(height: Insets.xl),
                Text('Headquarters', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: Insets.md),
                CSCPicker(
                  showStates: true,
                  showCities: true,
                  flagState: CountryFlag.DISABLE,
                  onCountryChanged: (value) => setState(() => _country = value),
                  onStateChanged: (value) => setState(() => _state = value ?? ''),
                  onCityChanged: (value) => setState(() => _city = value ?? ''),
                ),
                SizedBox(height: Insets.md),
                _fieldRow(
                  wide,
                  _textField(_street, 'Street address'),
                  _textField(_postalCode, 'Postal code'),
                ),
                SizedBox(height: Insets.xl),
                Text('Contact', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: Insets.md),
                _fieldRow(
                  wide,
                  _textField(
                    _contactEmail,
                    'Contact email',
                    required: true,
                    validator: _emailValidator,
                  ),
                  _textField(_contactPhone, 'Contact phone (optional)'),
                ),
                SizedBox(height: Insets.xl),
                Text('Login credentials', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: Insets.md),
                _textField(
                  _loginEmail,
                  'Login email',
                  required: true,
                  validator: _emailValidator,
                ),
                SizedBox(height: Insets.md),
                _textField(
                  _password,
                  'Password',
                  required: true,
                  obscure: true,
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'At least 8 characters' : null,
                ),
                SizedBox(height: Insets.xl),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register business'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact: stacked. Expanded+: side by side — matches the
  /// responsive.dart convention (MediaQuery = shell-level layout decision).
  Widget _fieldRow(bool wide, Widget a, Widget b) {
    if (!wide) {
      return Column(children: [a, SizedBox(height: Insets.md), b]);
    }
    return Row(
      children: [
        Expanded(child: a),
        SizedBox(width: Insets.md),
        Expanded(child: b),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool obscure = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      validator: validator ??
          (required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null),
    );
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }
}