import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive.dart';
import '../../models/opportunity_model.dart';
import '../../providers/post_opportunity_provider.dart';

/// Business-facing form to publish an opportunity (role, internship, or gig).
///
/// Deliberately dumb: every field writes straight to [postOpportunityProvider]
/// and every value it shows comes straight from it. If you're tempted to add
/// a `setState` in here for anything other than a `TextEditingController`,
/// that piece of state belongs in the Notifier instead.
class PostOpportunityPage extends ConsumerStatefulWidget {
  const PostOpportunityPage({super.key});

  @override
  ConsumerState<PostOpportunityPage> createState() => _PostOpportunityPageState();
}

class _PostOpportunityPageState extends ConsumerState<PostOpportunityPage> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _compMinCtrl = TextEditingController();
  final _compMaxCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _compMinCtrl.dispose();
    _compMaxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postOpportunityProvider);
    final notifier = ref.read(postOpportunityProvider.notifier);
    final theme = Theme.of(context);
    final compact = context.breakpoint.isCompact;

    ref.listen(postOpportunityProvider.select((s) => s.published), (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${next.title}" is live.')),
        );
        Navigator.of(context).pop(next);
      }
    });

    // Unlike publish, a saved draft does NOT navigate away — the business
    // stays on the form to keep editing.
    ref.listen(postOpportunityProvider.select((s) => s.draftSaved), (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${next.title}" saved as draft.')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Post an Opportunity')),
      body: SafeArea(
        child: ReadableWidth(
          maxWidth: 860,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: Insets.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reach vetted finance talent', style: theme.textTheme.headlineSmall),
                SizedBox(height: Insets.xs),
                Text(
                  'Every field below shapes how candidates are matched to this role. '
                  'Be specific — vague postings get vague applicants.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: Insets.xl),

                _SectionCard(
                  title: 'The role',
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      decoration: _decoration('Role title', hint: 'e.g. Associate, Equity Research', error: state.fieldErrors['title']),
                      onChanged: notifier.setTitle,
                    ),
                    SizedBox(height: Insets.md),
                    _ResponsiveRow(
                      compact: compact,
                      children: [
                        _EnumDropdown<FinanceSpecialization>(
                          label: 'Specialization',
                          value: state.specialization,
                          values: FinanceSpecialization.values,
                          labelOf: (v) => v.label,
                          error: state.fieldErrors['specialization'],
                          onChanged: notifier.setSpecialization,
                        ),
                        _EnumDropdown<OpportunityType>(
                          label: 'Type',
                          value: state.type,
                          values: OpportunityType.values,
                          labelOf: (v) => v.label,
                          error: state.fieldErrors['type'],
                          onChanged: notifier.setType,
                        ),
                      ],
                    ),
                    SizedBox(height: Insets.md),
                    _ResponsiveRow(
                      compact: compact,
                      children: [
                        _EnumDropdown<ExperienceLevel>(
                          label: 'Experience level',
                          value: state.experienceLevel,
                          values: ExperienceLevel.values,
                          labelOf: (v) => v.label,
                          error: state.fieldErrors['experienceLevel'],
                          onChanged: notifier.setExperienceLevel,
                        ),
                        _EnumDropdown<WorkMode>(
                          label: 'Work mode',
                          value: state.workMode,
                          values: WorkMode.values,
                          labelOf: (v) => v.label,
                          error: state.fieldErrors['workMode'],
                          onChanged: notifier.setWorkMode,
                        ),
                      ],
                    ),
                    SizedBox(height: Insets.md),
                    TextField(
                      controller: _locationCtrl,
                      decoration: _decoration('Location', hint: 'City, country — or "Remote"', error: state.fieldErrors['location']),
                      onChanged: notifier.setLocation,
                    ),
                  ],
                ),

                SizedBox(height: Insets.lg),
                _SectionCard(
                  title: 'Description',
                  children: [
                    TextField(
                      controller: _descriptionCtrl,
                      maxLines: 6,
                      decoration: _decoration(
                        'What is this role about?',
                        hint: 'Team, mandate, what success looks like in the first 6 months…',
                        error: state.fieldErrors['description'],
                      ),
                      onChanged: notifier.setDescription,
                    ),
                    SizedBox(height: Insets.md),
                    _ChipInput(
                      label: 'Key responsibilities',
                      hint: 'Add a responsibility and press enter',
                      values: state.responsibilities,
                      onAdd: notifier.addResponsibility,
                      onRemove: notifier.removeResponsibility,
                    ),
                  ],
                ),

                SizedBox(height: Insets.lg),
                _SectionCard(
                  title: 'Candidate fit',
                  children: [
                    _ChipInput(
                      label: 'Required skills',
                      hint: 'e.g. DCF modelling, Bloomberg Terminal, IFRS',
                      values: state.requiredSkills,
                      onAdd: notifier.addSkill,
                      onRemove: notifier.removeSkill,
                      error: state.fieldErrors['requiredSkills'],
                    ),
                    SizedBox(height: Insets.md),
                    _ChipInput(
                      label: 'Qualifications ',
                      hint: 'e.g. CFA Level II, ACCA, MBA',
                      values: state.qualifications,
                      onAdd: notifier.addQualification,
                      onRemove: notifier.removeQualification,
                    ),
                  ],
                ),

                SizedBox(height: Insets.lg),
                _SectionCard(
                  title: 'Compensation & logistics',
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Disclose compensation'),
                      subtitle: const Text('Postings with a disclosed range get more qualified applicants.'),
                      value: state.compensationDisclosed,
                      onChanged: (v) => notifier.setCompensation(
                        min: state.compensationMin,
                        max: state.compensationMax,
                        disclosed: v,
                      ),
                    ),
                    if (state.compensationDisclosed) ...[
                      SizedBox(height: Insets.sm),
                      _ResponsiveRow(
                        compact: compact,
                        children: [
                          TextField(
                            controller: _compMinCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _decoration('Minimum (USD)', error: state.fieldErrors['compensation']),
                            onChanged: (v) => notifier.setCompensation(
                              min: double.tryParse(v),
                              max: state.compensationMax,
                              disclosed: true,
                            ),
                          ),
                          TextField(
                            controller: _compMaxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _decoration('Maximum (USD)'),
                            onChanged: (v) => notifier.setCompensation(
                              min: state.compensationMin,
                              max: double.tryParse(v),
                              disclosed: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: Insets.md),
                    _ResponsiveRow(
                      compact: compact,
                      children: [
                        _OpeningsStepper(value: state.openings, onChanged: notifier.setOpenings),
                        _DeadlinePicker(value: state.applicationDeadline, onChanged: notifier.setDeadline),
                      ],
                    ),
                  ],
                ),

                if (state.submitError != null) ...[
                  SizedBox(height: Insets.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(state.submitError!, style: TextStyle(color: theme.colorScheme.error)),
                      ),
                      // Only retryable failures (network blip, timeout, 5xx) get
                      // a retry action — a validation-shaped 4xx wouldn't
                      // succeed on a bare retry, so we don't offer one.
                      if (state.submitErrorRetryable && !state.isSubmitting)
                        TextButton(
                          onPressed: () {
                            _syncControllersIfEmpty(state);
                            notifier.submit();
                          },
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ],

                SizedBox(height: Insets.xl),
                _ResponsiveRow(
                  compact: compact,
                  children: [
                    OutlinedButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () {
                              _syncControllersIfEmpty(state);
                              notifier.saveDraft();
                            },
                      child: state.submittingKind == SubmitKind.draft
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator.adaptive())
                          : const Text('Save as draft'),
                    ),
                    FilledButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () {
                              _syncControllersIfEmpty(state);
                              notifier.submit();
                            },
                      child: state.submittingKind == SubmitKind.publish
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator.adaptive())
                          : const Text('Publish opportunity'),
                    ),
                  ],
                ),
                SizedBox(height: Insets.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Controllers are the source of truth for typed text; this only guards
  /// against the (rare) case of autofill or restored state bypassing
  /// onChanged. Safe no-op in the normal typing flow.
  void _syncControllersIfEmpty(PostOpportunityState state) {
    if (_titleCtrl.text != state.title) _titleCtrl.text = state.title;
    if (_locationCtrl.text != state.location) _locationCtrl.text = state.location;
    if (_descriptionCtrl.text != state.description) _descriptionCtrl.text = state.description;
  }

  InputDecoration _decoration(String label, {String? hint, String? error}) => InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
      );
}

/// ---------------------------------------------------------------------------
/// Small private presentational widgets. Kept in this file because none of
/// them are reused outside this page yet — promote to lib/pages/dashboard/
/// widgets/ the moment a second page needs one.
/// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: Insets.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.compact, required this.children});

  final bool compact;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) SizedBox(height: Insets.md),
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) SizedBox(width: Insets.md),
        ],
      ],
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    this.error,
    super.key,
  });

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, errorText: error),
      items: [for (final v in values) DropdownMenuItem(value: v, child: Text(labelOf(v)))],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _ChipInput extends StatefulWidget {
  const _ChipInput({
    required this.label,
    required this.values,
    required this.onAdd,
    required this.onRemove,
    this.hint,
    this.error,
  });

  final String label;
  final List<String> values;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final String? hint;
  final String? error;

  @override
  State<_ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<_ChipInput> {
  final _ctrl = TextEditingController();

  void _commit() {
    if (_ctrl.text.trim().isEmpty) return;
    widget.onAdd(_ctrl.text);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            errorText: widget.error,
            suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _commit),
          ),
          onSubmitted: (_) => _commit(),
        ),
        if (widget.values.isNotEmpty) ...[
          SizedBox(height: Insets.sm),
          Wrap(
            spacing: Insets.xs,
            runSpacing: Insets.xs,
            children: [
              for (final v in widget.values)
                Chip(label: Text(v), onDeleted: () => widget.onRemove(v)),
            ],
          ),
        ],
      ],
    );
  }
}

class _OpeningsStepper extends StatelessWidget {
  const _OpeningsStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Openings', style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => onChanged(value - 1)),
        Text('$value', style: Theme.of(context).textTheme.titleMedium),
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => onChanged(value + 1)),
      ],
    );
  }
}

class _DeadlinePicker extends StatelessWidget {
  const _DeadlinePicker({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = value == null ? 'No deadline' : '${value!.day}/${value!.month}/${value!.year}';
    return OutlinedButton.icon(
      icon: const Icon(Icons.event_outlined),
      label: Text('Deadline: $label'),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(picked);
      },
    );
  }
}