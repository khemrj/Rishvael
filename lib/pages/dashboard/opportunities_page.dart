import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/opportunity_model.dart';
import '../../providers/dashboard_providers.dart';

class OpportunitiesPage extends ConsumerStatefulWidget {
  const OpportunitiesPage({super.key});

  @override
  ConsumerState<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends ConsumerState<OpportunitiesPage> {
  final _searchController = TextEditingController();

  // Client-side refinement. opportunitiesProvider already applies search +
  // kind server-side; these three narrow whatever comes back.
  Set<dynamic> _specializations = {};
  Set<dynamic> _workModes = {};
  Set<dynamic> _experienceLevels = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount =>
      _specializations.length + _workModes.length + _experienceLevels.length;

  bool get _hasActiveFilters => _activeFilterCount > 0;

  List<Opportunity> _refine(List<Opportunity> source) {
    if (!_hasActiveFilters) return source;
    return source.where((o) {
      final matchesSpecialization =
          _specializations.isEmpty || _specializations.contains(o.specialization);
      final matchesWorkMode = _workModes.isEmpty || _workModes.contains(o.workMode);
      final matchesExperience =
          _experienceLevels.isEmpty || _experienceLevels.contains(o.experienceLevel);
      return matchesSpecialization && matchesWorkMode && matchesExperience;
    }).toList();
  }

  Future<void> _openFilterSheet(List<Opportunity> pool) async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        allSpecializations: pool.map((o) => o.specialization).toSet().toList(),
        allWorkModes: pool.map((o) => o.workMode).toSet().toList(),
        allExperienceLevels: pool.map((o) => o.experienceLevel).toSet().toList(),
        initialSpecializations: _specializations,
        initialWorkModes: _workModes,
        initialExperienceLevels: _experienceLevels,
      ),
    );

    if (result != null) {
      setState(() {
        _specializations = result.specializations;
        _workModes = result.workModes;
        _experienceLevels = result.experienceLevels;
      });
    }
  }

  void _clearAll() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).update('');
    setState(() {
      _specializations = {};
      _workModes = {};
      _experienceLevels = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opportunitiesAsync = ref.watch(opportunitiesProvider);

    return Column(
      children: [
        _SearchAndFilterBar(
          controller: _searchController,
          activeFilterCount: _activeFilterCount,
          onChanged: (value) {
            setState(() {}); // toggles the clear-icon
            ref.read(searchQueryProvider.notifier).update(value);
          },
          onClearSearch: () {
            _searchController.clear();
            ref.read(searchQueryProvider.notifier).update('');
            setState(() {});
          },
          onOpenFilters: opportunitiesAsync.hasValue
              ? () => _openFilterSheet(opportunitiesAsync.value!)
              : null,
        ),
        if (_hasActiveFilters)
          _ActiveFilterChips(
            specializations: _specializations,
            workModes: _workModes,
            experienceLevels: _experienceLevels,
            onRemoveSpecialization: (v) =>
                setState(() => _specializations = {..._specializations}..remove(v)),
            onRemoveWorkMode: (v) =>
                setState(() => _workModes = {..._workModes}..remove(v)),
            onRemoveExperience: (v) =>
                setState(() => _experienceLevels = {..._experienceLevels}..remove(v)),
            onClearAll: _clearAll,
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => refreshDashboard(ref),
            child: opportunitiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text('Failed to load opportunities:\n$err',
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
              data: (opportunities) {
                final filtered = _refine(opportunities);

                if (opportunities.isEmpty) {
                  return ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No opportunities available right now.')),
                    ],
                  );
                }

                if (filtered.isEmpty) {
                  return ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      const SizedBox(height: 100),
                      Icon(Icons.search_off, size: 40, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      const Center(child: Text('No opportunities match your filters.')),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _clearAll,
                          child: const Text('Clear all filters'),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${filtered.length} opportunit${filtered.length == 1 ? 'y' : 'ies'} found',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      );
                    }
                    return _OpportunityCard(opportunity: filtered[i - 1]);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// ===========================================================================
/// SEARCH + FILTER BAR
/// ===========================================================================

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.activeFilterCount,
    required this.onChanged,
    required this.onClearSearch,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final int activeFilterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search opportunities, businesses...',
                  hintStyle: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  prefixIcon:
                      Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: onClearSearch,
                          splashRadius: 18,
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: activeFilterCount > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeFilterCount > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.tune,
                    size: 20,
                    color: activeFilterCount > 0
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onOpenFilters,
                  splashRadius: 22,
                ),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$activeFilterCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ===========================================================================
/// ACTIVE FILTER CHIPS
/// ===========================================================================

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.specializations,
    required this.workModes,
    required this.experienceLevels,
    required this.onRemoveSpecialization,
    required this.onRemoveWorkMode,
    required this.onRemoveExperience,
    required this.onClearAll,
  });

  final Set<dynamic> specializations;
  final Set<dynamic> workModes;
  final Set<dynamic> experienceLevels;
  final ValueChanged<dynamic> onRemoveSpecialization;
  final ValueChanged<dynamic> onRemoveWorkMode;
  final ValueChanged<dynamic> onRemoveExperience;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      ...specializations.map((v) =>
          _RemovableChip(label: v.label as String, onRemoved: () => onRemoveSpecialization(v))),
      ...workModes.map(
          (v) => _RemovableChip(label: v.label as String, onRemoved: () => onRemoveWorkMode(v))),
      ...experienceLevels.map((v) =>
          _RemovableChip(label: v.label as String, onRemoved: () => onRemoveExperience(v))),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...chips,
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: theme.colorScheme.error,
              ),
              child:
                  const Text('Clear all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemoved});
  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onRemoved,
        deleteIconColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// ===========================================================================
/// FILTER BOTTOM SHEET
/// ===========================================================================

class _FilterResult {
  const _FilterResult({
    required this.specializations,
    required this.workModes,
    required this.experienceLevels,
  });
  final Set<dynamic> specializations;
  final Set<dynamic> workModes;
  final Set<dynamic> experienceLevels;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.allSpecializations,
    required this.allWorkModes,
    required this.allExperienceLevels,
    required this.initialSpecializations,
    required this.initialWorkModes,
    required this.initialExperienceLevels,
  });

  final List<dynamic> allSpecializations;
  final List<dynamic> allWorkModes;
  final List<dynamic> allExperienceLevels;
  final Set<dynamic> initialSpecializations;
  final Set<dynamic> initialWorkModes;
  final Set<dynamic> initialExperienceLevels;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<dynamic> _specializations;
  late Set<dynamic> _workModes;
  late Set<dynamic> _experienceLevels;

  @override
  void initState() {
    super.initState();
    _specializations = {...widget.initialSpecializations};
    _workModes = {...widget.initialWorkModes};
    _experienceLevels = {...widget.initialExperienceLevels};
  }

  void _toggle(Set<dynamic> set, dynamic value) {
    setState(() {
      set.contains(value) ? set.remove(value) : set.add(value);
    });
  }

  int get _count => _specializations.length + _workModes.length + _experienceLevels.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  Text('Refine results',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _specializations = {};
                      _workModes = {};
                      _experienceLevels = {};
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.allSpecializations.isNotEmpty) ...[
                      const _FilterSectionLabel('Specialization'),
                      _FilterChipWrap(
                        options: widget.allSpecializations,
                        selected: _specializations,
                        onToggle: (v) => _toggle(_specializations, v),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.allWorkModes.isNotEmpty) ...[
                      const _FilterSectionLabel('Work Mode'),
                      _FilterChipWrap(
                        options: widget.allWorkModes,
                        selected: _workModes,
                        onToggle: (v) => _toggle(_workModes, v),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.allExperienceLevels.isNotEmpty) ...[
                      const _FilterSectionLabel('Experience Level'),
                      _FilterChipWrap(
                        options: widget.allExperienceLevels,
                        selected: _experienceLevels,
                        onToggle: (v) => _toggle(_experienceLevels, v),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _FilterResult(
                      specializations: _specializations,
                      workModes: _workModes,
                      experienceLevels: _experienceLevels,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _count == 0 ? 'Show all opportunities' : 'Apply filters ($_count)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }
}

class _FilterChipWrap extends StatelessWidget {
  const _FilterChipWrap({required this.options, required this.selected, required this.onToggle});

  final List<dynamic> options;
  final Set<dynamic> selected;
  final ValueChanged<dynamic> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option.label as String),
          selected: isSelected,
          onSelected: (_) => onToggle(option),
          showCheckmark: false,
          selectedColor: theme.colorScheme.primary.withOpacity(0.14),
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          labelStyle: TextStyle(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }
}

/// ===========================================================================
/// OPPORTUNITY CARD — restyled
/// ===========================================================================

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = opportunity;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.title,
                          style:
                              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        o.businessName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    o.type.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TagChip(label: o.specialization.label),
                _TagChip(label: o.workMode.label),
                _TagChip(label: o.experienceLevel.label),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    o.location,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              o.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  o.compensation.display(),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                ),
                Row(
                  children: [
                    Icon(Icons.groups_outlined, size: 15, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${o.openings} opening${o.openings == 1 ? '' : 's'}',
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    );
  }
}