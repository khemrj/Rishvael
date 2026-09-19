import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/models/member_setup_data.dart';
import 'package:flutter_application_1/pages/setup_pages/member_profile_details.dart' show MemberProfileDetailsPage;



class MemberSetupPage extends StatefulWidget {
  const MemberSetupPage({
    super.key,
    this.initialData,
    this.onCompleted,
  });

  final MemberSetupData? initialData;
  final ValueChanged<MemberSetupData>? onCompleted;

  @override
  State<MemberSetupPage> createState() => _MemberSetupPageState();
}

class _MemberSetupPageState extends State<MemberSetupPage> {
  final Set<String> _specializations = {};
  final Set<String> _openTo = {};

  static const _specializationOptions = [
    'Investment banking',
    'Audit',
    'Risk',
    'Wealth management',
    'Fintech',
    'Corporate finance',
  ];

  static const _openToOptions = [
    'Job opportunities',
    'Mentoring',
    'Networking',
  ];

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;

    if (data != null) {
      _specializations.addAll(data.specializations);
      _openTo.addAll(data.openTo);
    }
  }

  void _toggleSpecialization(String value) {
    setState(() {
      if (_specializations.contains(value)) {
        _specializations.remove(value);
      } else {
        _specializations.add(value);
      }
    });
  }

  void _toggleOpenTo(String value) {
    setState(() {
      if (_openTo.contains(value)) {
        _openTo.remove(value);
      } else {
        _openTo.add(value);
      }
    });
  }

  void _next() {
    final data = MemberSetupData(
      specializations: Set.unmodifiable(_specializations),
      openTo: Set.unmodifiable(_openTo),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemberProfileDetailsPage(
          initialData: data,
          onCompleted: widget.onCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight = constraints.maxHeight < 700;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                
                  child: Column(
                    children: [
                      _SetupHeader(
                        currentStep: 1,
                        totalSteps: 3,
                        onBack: () {
                          Navigator.of(context).pop();
                        },
                      ),

                      SizedBox(
                        height: isCompactHeight ? 20 : 30,
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your focus in finance',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: AppColors.ivory,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Select all that apply',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.slate,
                                    ),
                              ),

                              SizedBox(
                                height:
                                    isCompactHeight ? 22 : 30,
                              ),

                              _OptionWrap(
                                options: _specializationOptions,
                                selected: _specializations,
                                onTap: _toggleSpecialization,
                              ),

                              SizedBox(
                                height:
                                    isCompactHeight ? 28 : 48,
                              ),

                              Text(
                                'What are you open to?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppColors.ivory,
                                    ),
                              ),

                              SizedBox(
                                height:
                                    isCompactHeight ? 18 : 28,
                              ),

                              _OptionWrap(
                                options: _openToOptions,
                                selected: _openTo,
                                onTap: _toggleOpenTo,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        height: isCompactHeight ? 14 : 24,
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _next,
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                
              ),
            );
          },
        ),
      ),
    );
  }
}
class _SetupHeader extends StatelessWidget {
  const _SetupHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.gold,
            ),
          ),
        ),

        const Spacer(),

        Row(
          children: List.generate(
            totalSteps,
            (index) {
              final active = index < currentStep;

              return Container(
                width: 29,
                height: 7,
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.gold
                      : AppColors.slate.withValues(
                          alpha: 0.45,
                        ),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: options.map((option) {
            final isSelected = selected.contains(option);

            return _SelectablePill(
              label: option,
              selected: isSelected,
              onTap: () => onTap(option),
              maxWidth: constraints.maxWidth,
            );
          }).toList(),
        );
      },
    );
  }
}

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.maxWidth,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.gold
          : Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected
                  ? AppColors.gold
                  : AppColors.gold.withValues(
                      alpha: 0.45,
                    ),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  color: selected
                      ? AppColors.ink
                      : AppColors.slate,
                  fontWeight: selected
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }
}