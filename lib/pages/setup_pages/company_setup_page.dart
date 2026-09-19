import 'package:flutter/material.dart';

/// Company Setup Page for members to set up their company details.
/// Built with modular widgets, responsive constraints, and the Rishvael palette.
class CompanySetupPage extends StatefulWidget {
  const CompanySetupPage({super.key});

  @override
  State<CompanySetupPage> createState() => _CompanySetupPageState();
}

class _CompanySetupPageState extends State<CompanySetupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _companyNameController = TextEditingController();
  final _locationController = TextEditingController();

  // Dropdown selections
  String? _selectedIndustry;
  String? _selectedCompanySize;

  // Rishvael Palette
  static const Color backgroundColor = Color(0xFF0A111E);
  static const Color cardBackgroundColor = Color(0xFF10192A);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFF9A7B2C);
  static const Color goldSubtle = Color(0x40C5A059);
  static const Color fieldBorderColor = Color(0xFF1E2B42);
  static const Color labelTextColor = Color(0xFF8A99AD);
  static const Color hintTextColor = Color(0xFF4A5970);

  // Options
  final List<String> _industries = [
    'Technology & Software',
    'E-Commerce & Retail',
    'Finance & Banking',
    'Healthcare & Biotech',
    'Education & EdTech',
    'Real Estate',
    'Marketing & Advertising',
    'Other',
  ];

  final List<String> _companySizes = [
    '1–10 employees',
    '11–50 employees',
    '51–200 employees',
    '201–500 employees',
    '500+ employees',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      // Process company setup logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company details saved successfully!'),
          backgroundColor: goldDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              // Responsive constraint: limit width for tablet/desktop views
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back / Action Button Top Left
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Container(
                    
                        decoration: BoxDecoration(
                          border: Border.all(color: fieldBorderColor),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white70,
                          size: 30,
                        ),
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),

                    const SizedBox(height: 28),

                    // Header Title
                    const Text(
                      'Tell us about your company',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Logo Upload Container
                    const Center(child: _LogoUploader()),

                    const SizedBox(height: 32),

                    // Field 1: Company Name
                    const _FieldLabel(label: 'COMPANY NAME'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyNameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _buildInputDecoration(
                        hintText: 'Your company name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Company name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Field 2: Industry (Dropdown)
                    const _FieldLabel(label: 'INDUSTRY'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedIndustry,
                      dropdownColor: cardBackgroundColor,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: hintTextColor,
                      ),
                      decoration: _buildInputDecoration(
                        hintText: 'Select industry',
                      ),
                      items: _industries.map((industry) {
                        return DropdownMenuItem(
                          value: industry,
                          child: Text(industry),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedIndustry = value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an industry';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Field 3: Company Size (Dropdown)
                    const _FieldLabel(label: 'COMPANY SIZE'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCompanySize,
                      dropdownColor: cardBackgroundColor,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: hintTextColor,
                      ),
                      decoration: _buildInputDecoration(
                        hintText: 'e.g. 1–10 employees',
                      ),
                      items: _companySizes.map((size) {
                        return DropdownMenuItem(
                          value: size,
                          child: Text(size),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCompanySize = value),
                    ),

                    const SizedBox(height: 20),

                    // Field 4: Location
                    const _FieldLabel(label: 'LOCATION'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _buildInputDecoration(
                        hintText: 'City, country',
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldPrimary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to build uniform input decorations
  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: hintTextColor, fontSize: 14),
      filled: true,
      fillColor: cardBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fieldBorderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: goldPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
      errorStyle: TextStyle(color: Colors.redAccent.shade100, fontSize: 12),
    );
  }
}

// ============================================================================
// MODULAR SUB-WIDGETS
// ============================================================================

/// Uppercase label above input fields
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _CompanySetupPageState.labelTextColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Dashed logo uploader box widget
class _LogoUploader extends StatelessWidget {
  const _LogoUploader();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement image picker logic
      },
      child: Column(
        children: [
          CustomPaint(
            painter: _DashedRectPainter(
              color: Colors.white24,
              strokeWidth: 1.2,
              gap: 4.0,
              dash: 5.0,
              radius: 14.0,
            ),
            child: Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_box_outline_blank_rounded,
                color: Colors.white38,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add your logo',
            style: TextStyle(
              color: _CompanySetupPageState.labelTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw a dashed rounded rectangle border
class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.gap = 4.0,
    this.dash = 5.0,
    this.radius = 12.0,
  });

  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path metricsPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        metricsPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    canvas.drawPath(metricsPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}