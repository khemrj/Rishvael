import 'package:flutter/material.dart';

class ProfessionalSetupPage extends StatefulWidget {
	const ProfessionalSetupPage({super.key});

	@override
	State<ProfessionalSetupPage> createState() => _ProfessionalSetupPageState();
}

class _ProfessionalSetupPageState extends State<ProfessionalSetupPage> {
	final _formKey = GlobalKey<FormState>();
	final _nameController = TextEditingController();
	final _emailController = TextEditingController();
	final _phoneController = TextEditingController();
	final _licenseController = TextEditingController();
	final _experienceController = TextEditingController();
	String _specialty = 'Financial Advisor';
	String _country = 'United States';
	bool _termsAccepted = false;

	@override
	void dispose() {
		_nameController.dispose();
		_emailController.dispose();
		_phoneController.dispose();
		_licenseController.dispose();
		_experienceController.dispose();
		super.dispose();
	}

	InputDecoration _decoration(String label, IconData icon) => InputDecoration(
				labelText: label,
				prefixIcon: Icon(icon),
				filled: true,
				fillColor: const Color(0xfff7f8fa),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide.none,
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: Color(0xff176b87), width: 1.5),
				),
			);

	String? _required(String? value) =>
			value == null || value.trim().isEmpty ? 'This field is required' : null;

	void _submit() {
		if (!_formKey.currentState!.validate()) return;
		if (!_termsAccepted) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please accept the terms to continue.')),
			);
			return;
		}
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(content: Text('Registration submitted successfully.')),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xfff4f7f8),
			appBar: AppBar(
				title: const Text('Professional registration'),
				centerTitle: false,
				backgroundColor: Colors.transparent,
				elevation: 0,
				foregroundColor: const Color(0xff153b4a),
			),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.all(20),
					child: Center(
						child: ConstrainedBox(
							constraints: const BoxConstraints(maxWidth: 850),
							child: Card(
								elevation: 0,
								margin: EdgeInsets.zero,
								shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(24)),
								child: Padding(
									padding: const EdgeInsets.all(28),
									child: Form(
										key: _formKey,
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												const Icon(Icons.account_balance_rounded,
														size: 42, color: Color(0xff176b87)),
												const SizedBox(height: 14),
												const Text('Join our finance professional network',
														style: TextStyle(
																fontSize: 26,
																fontWeight: FontWeight.bold,
																color: Color(0xff153b4a))),
												const SizedBox(height: 8),
												const Text(
														'Tell us about your experience so clients can find the right expert for their financial goals.'),
												const SizedBox(height: 28),
												LayoutBuilder(builder: (context, constraints) {
													final wide = constraints.maxWidth >= 600;
													return Column(children: [
														if (wide)
															Row(children: [
																Expanded(child: _nameField()),
																const SizedBox(width: 16),
																Expanded(child: _emailField()),
															])
														else ...[_nameField(), const SizedBox(height: 16), _emailField()],
														const SizedBox(height: 16),
														if (wide)
															Row(children: [
																Expanded(child: _phoneField()),
																const SizedBox(width: 16),
																Expanded(child: _licenseField()),
															])
														else ...[_phoneField(), const SizedBox(height: 16), _licenseField()],
														const SizedBox(height: 16),
														if (wide)
															Row(children: [
																Expanded(child: _specialtyField()),
																const SizedBox(width: 16),
																Expanded(child: _countryField()),
															])
														else ...[_specialtyField(), const SizedBox(height: 16), _countryField()],
														const SizedBox(height: 16),
														_experienceField(),
													]);
												}),
												const SizedBox(height: 12),
												CheckboxListTile(
													value: _termsAccepted,
													onChanged: (value) => setState(() => _termsAccepted = value ?? false),
													contentPadding: EdgeInsets.zero,
													controlAffinity: ListTileControlAffinity.leading,
													title: const Text('I agree to the professional terms and privacy policy'),
												),
												const SizedBox(height: 12),
												SizedBox(
													width: double.infinity,
													height: 52,
													child: ElevatedButton(
														onPressed: _submit,
														style: ElevatedButton.styleFrom(
															backgroundColor: const Color(0xff176b87),
															foregroundColor: Colors.white,
															shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
														),
														child: const Text('Submit registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
													),
												),
											],
										),
									),
								),
							),
						),
					),
				),
			),
		);
	}

	Widget _nameField() => TextFormField(controller: _nameController, validator: _required, decoration: _decoration('Full name', Icons.person_outline));
	Widget _emailField() => TextFormField(controller: _emailController, validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email', keyboardType: TextInputType.emailAddress, decoration: _decoration('Email address', Icons.email_outlined));
	Widget _phoneField() => TextFormField(controller: _phoneController, validator: _required, keyboardType: TextInputType.phone, decoration: _decoration('Phone number', Icons.phone_outlined));
	Widget _licenseField() => TextFormField(controller: _licenseController, validator: _required, decoration: _decoration('License / certification ID', Icons.verified_user_outlined));
	Widget _experienceField() => TextFormField(controller: _experienceController, validator: _required, maxLines: 4, decoration: _decoration('Professional experience', Icons.description_outlined));

	Widget _specialtyField() => DropdownButtonFormField<String>(value: _specialty, decoration: _decoration('Specialty', Icons.work_outline), items: const ['Financial Advisor', 'Accountant', 'Investment Manager', 'Tax Specialist'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => _specialty = value!));
	Widget _countryField() => DropdownButtonFormField<String>(value: _country, decoration: _decoration('Country', Icons.public), items: const ['United States', 'Canada', 'United Kingdom', 'Australia'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => _country = value!));
}
