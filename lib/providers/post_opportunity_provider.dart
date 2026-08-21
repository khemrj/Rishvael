import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_failure.dart';
import '../models/opportunity_model.dart';
import '../data/opportunity_repository.dart';
import 'package:logger/logger.dart';

/// ---------------------------------------------------------------------------
/// Why a Notifier and not just a bag of TextEditingControllers in the widget:
///
/// The page has ~10 fields, three of which are growable lists (skills,
/// responsibilities, qualifications) built from chip inputs. That's exactly
/// the kind of state that turns a StatefulWidget into an unreadable pile of
/// setState calls. Here the widget owns nothing but TextEditingControllers
/// for raw text entry — every field that has *meaning* (selection, list
/// membership, validity, submission status) lives in this Notifier and is
/// unit-testable with zero widgets involved.
/// ---------------------------------------------------------------------------
final Logger logger = Logger();
enum SubmitKind { publish, draft }

@immutable
class PostOpportunityState {
  const PostOpportunityState({
    this.title = '',
    this.specialization,
    this.type,
    this.experienceLevel,
    this.workMode,
    this.location = '',
    this.description = '',
    this.responsibilities = const [],
    this.requiredSkills = const [],
    this.qualifications = const [],
    this.compensationMin,
    this.compensationMax,
    this.compensationDisclosed = true,
    this.openings = 1,
    this.applicationDeadline,
    this.fieldErrors = const {},
    this.isSubmitting = false,
    this.submittingKind,
    this.submitError,
    this.submitErrorRetryable = false,
    this.published,
    this.draftSaved,
  });

  final String title;
  final FinanceSpecialization? specialization;
  final OpportunityType? type;
  final ExperienceLevel? experienceLevel;
  final WorkMode? workMode;
  final String location;
  final String description;
  final List<String> responsibilities;
  final List<String> requiredSkills;
  final List<String> qualifications;
  final double? compensationMin;
  final double? compensationMax;
  final bool compensationDisclosed;
  final int openings;
  final DateTime? applicationDeadline;

  /// Keyed by field name, e.g. `errors['title']`. The page reads this to
  /// show inline errors instead of a single toast nobody reads.
  final Map<String, String> fieldErrors;
  final bool isSubmitting;

  /// Which action is in flight — lets the page disable/spin only the button
  /// that was actually pressed, instead of both Publish and Save Draft.
  final SubmitKind? submittingKind;

  final String? submitError;
  final bool submitErrorRetryable;

  /// Set once publish succeeds — the page listens for this to navigate away.
  final Opportunity? published;

  /// Set once a draft save succeeds — the page listens for this to show a
  /// confirmation, but (unlike publish) stays on the form.
  final Opportunity? draftSaved;

  bool get isValid => fieldErrors.isEmpty;

  PostOpportunityState copyWith({
    String? title,
    FinanceSpecialization? specialization,
    OpportunityType? type,
    ExperienceLevel? experienceLevel,
    WorkMode? workMode,
    String? location,
    String? description,
    List<String>? responsibilities,
    List<String>? requiredSkills,
    List<String>? qualifications,
    double? compensationMin,
    double? compensationMax,
    bool? compensationDisclosed,
    int? openings,
    DateTime? applicationDeadline,
    bool clearDeadline = false,
    Map<String, String>? fieldErrors,
    bool? isSubmitting,
    SubmitKind? submittingKind,
    bool clearSubmittingKind = false,
    String? submitError,
    bool clearSubmitError = false,
    bool submitErrorRetryable = false,
    Opportunity? published,
    Opportunity? draftSaved,
  }) {
    return PostOpportunityState(
      title: title ?? this.title,
      specialization: specialization ?? this.specialization,
      type: type ?? this.type,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      workMode: workMode ?? this.workMode,
      location: location ?? this.location,
      description: description ?? this.description,
      responsibilities: responsibilities ?? this.responsibilities,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      qualifications: qualifications ?? this.qualifications,
      compensationMin: compensationMin ?? this.compensationMin,
      compensationMax: compensationMax ?? this.compensationMax,
      compensationDisclosed: compensationDisclosed ?? this.compensationDisclosed,
      openings: openings ?? this.openings,
      applicationDeadline: clearDeadline ? null : (applicationDeadline ?? this.applicationDeadline),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittingKind: clearSubmittingKind ? null : (submittingKind ?? this.submittingKind),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitErrorRetryable: submitErrorRetryable,
      published: published,
      draftSaved: draftSaved,
    );
  }
}

/// autoDispose: this form is scoped to one visit of the page. Without this,
/// publishing once and reopening "Post an Opportunity" later in the session
/// would show the *previous* posting's data instead of a blank form.
class PostOpportunityNotifier extends AutoDisposeNotifier<PostOpportunityState> {
  /// Manual stand-in for `ref.mounted` (Riverpod 2.3+). If you're on a newer
  /// flutter_riverpod, delete this field and the `onDispose` line below and
  /// use `ref.mounted` directly instead — it's the maintained equivalent.
  bool _disposed = false;

  @override
  PostOpportunityState build() {
    ref.onDispose(() => _disposed = true);
    return const PostOpportunityState();
  }

  void setTitle(String v) => state = state.copyWith(title: v, fieldErrors: _clear('title'));
  void setSpecialization(FinanceSpecialization v) =>
      state = state.copyWith(specialization: v, fieldErrors: _clear('specialization'));
  void setType(OpportunityType v) => state = state.copyWith(type: v, fieldErrors: _clear('type'));
  void setExperienceLevel(ExperienceLevel v) =>
      state = state.copyWith(experienceLevel: v, fieldErrors: _clear('experienceLevel'));
  void setWorkMode(WorkMode v) => state = state.copyWith(workMode: v, fieldErrors: _clear('workMode'));
  void setLocation(String v) => state = state.copyWith(location: v, fieldErrors: _clear('location'));
  void setDescription(String v) => state = state.copyWith(description: v, fieldErrors: _clear('description'));
  void setOpenings(int v) => state = state.copyWith(openings: v < 1 ? 1 : v);
  void setDeadline(DateTime? v) => state = v == null
      ? state.copyWith(clearDeadline: true, fieldErrors: _clear('applicationDeadline'))
      : state.copyWith(applicationDeadline: v, fieldErrors: _clear('applicationDeadline'));

  void setCompensation({double? min, double? max, required bool disclosed}) => state = state.copyWith(
        compensationMin: min,
        compensationMax: max,
        compensationDisclosed: disclosed,
        fieldErrors: _clear('compensation'),
      );

  void addSkill(String raw) =>
      _addToList(raw, state.requiredSkills, (l) => state = state.copyWith(requiredSkills: l, fieldErrors: _clear('requiredSkills')));
  void removeSkill(String v) => state = state.copyWith(requiredSkills: [...state.requiredSkills]..remove(v));

  void addResponsibility(String raw) =>
      _addToList(raw, state.responsibilities, (l) => state = state.copyWith(responsibilities: l));
  void removeResponsibility(String v) =>
      state = state.copyWith(responsibilities: [...state.responsibilities]..remove(v));

  void addQualification(String raw) =>
      _addToList(raw, state.qualifications, (l) => state = state.copyWith(qualifications: l));
  void removeQualification(String v) =>
      state = state.copyWith(qualifications: [...state.qualifications]..remove(v));

  void _addToList(String raw, List<String> current, void Function(List<String>) apply) {
    final v = raw.trim();
    if (v.isEmpty || current.contains(v)) return;
    apply([...current, v]);
  }

  /// Returns `fieldErrors` with [key] removed — used so fixing a field clears
  /// its own error immediately instead of waiting for the next full validate().
  Map<String, String> _clear(String key) {
    if (!state.fieldErrors.containsKey(key)) return state.fieldErrors;
    return {...state.fieldErrors}..remove(key);
  }

  /// [forPublish] = false relaxes the rules for a draft: a business should be
  /// able to save half a form (e.g. title + specialization only) and come
  /// back later. Publishing enforces the full checklist.
  bool _validate({required bool forPublish}) {
    final errors = <String, String>{};
    if (state.title.trim().length < 3) errors['title'] = 'Give the role a real title (min 3 characters).';
    if (state.specialization == null) errors['specialization'] = 'Choose a finance specialization.';

    if (forPublish) {
      if (state.type == null) errors['type'] = 'Choose an opportunity type.';
      if (state.experienceLevel == null) errors['experienceLevel'] = 'Choose an experience level.';
      if (state.workMode == null) errors['workMode'] = 'Choose a work mode.';
      if (state.location.trim().isEmpty) errors['location'] = 'Location is required, even for remote roles.';
      if (state.description.trim().length < 40) {
        errors['description'] = 'Description should give candidates enough to self-select (40+ characters).';
      }
      if (state.requiredSkills.isEmpty) errors['requiredSkills'] = 'Add at least one required skill.';
      if (state.compensationDisclosed && state.compensationMin == null && state.compensationMax == null) {
        errors['compensation'] = 'Enter a range, or mark compensation as undisclosed.';
      }
    }

    if (state.compensationMin != null &&
        state.compensationMax != null &&
        state.compensationMin! > state.compensationMax!) {
      errors['compensation'] = 'Minimum compensation is higher than the maximum.';
    }
    if (state.applicationDeadline != null && state.applicationDeadline!.isBefore(DateTime.now())) {
      errors['applicationDeadline'] = 'Deadline is in the past.';
    }

    state = state.copyWith(fieldErrors: errors);
    return errors.isEmpty;
  }

  /// Kept as a public alias so the page's existing `validate()` call site
  /// (full, publish-strength validation) doesn't need to change.
  bool validate() => _validate(forPublish: true);

  Future<void> submit() => _run(kind: SubmitKind.publish);
  Future<void> saveDraft() => _run(kind: SubmitKind.draft);

  Future<void> _run({required SubmitKind kind}) async {
    if (!_validate(forPublish: kind == SubmitKind.publish)) return;

    state = state.copyWith(isSubmitting: true, submittingKind: kind, clearSubmitError: true);

    final draft = OpportunityDraft(
      title: state.title.trim(),
      specialization: state.specialization!,
      type: state.type ?? OpportunityType.fullTime,
      experienceLevel: state.experienceLevel ?? ExperienceLevel.graduate,
      workMode: state.workMode ?? WorkMode.onsite,
      location: state.location.trim(),
      description: state.description.trim(),
      responsibilities: state.responsibilities,
      requiredSkills: state.requiredSkills,
      qualifications: state.qualifications,
      compensation: state.compensationDisclosed
          ? CompensationRange(min: state.compensationMin, max: state.compensationMax)
          : CompensationRange.undisclosed,
      openings: state.openings,
      applicationDeadline: state.applicationDeadline,
    );

       try {
      final repo = ref.read(opportunityRepositoryProvider);
      final result = kind == SubmitKind.publish ? await repo.publish(draft) : await repo.saveDraft(draft);
      logger.d('PostOpportunityNotifier._run: Successfully submitted opportunity');
      if (_disposed) return;

      state = kind == SubmitKind.publish
          ? state.copyWith(isSubmitting: false, clearSubmittingKind: true, published: result)
          : state.copyWith(isSubmitting: false, clearSubmittingKind: true, draftSaved: result);
    } on ApiFailure catch (e) {
      if (_disposed) return;
      final serverFieldErrors = e is ValidationFailure ? e.fieldErrors : const <String, String>{};

      state = state.copyWith(
        isSubmitting: false,
        clearSubmittingKind: true,
        fieldErrors: serverFieldErrors.isNotEmpty ? {...state.fieldErrors, ...serverFieldErrors} : state.fieldErrors,
        submitError: e.message,
        submitErrorRetryable: e.isRetryable,
      );
    } catch (e, stackTrace) {
      // Anything that isn't an ApiFailure: network blips, JSON decode
      // errors, type mismatches from a malformed response, etc. Without
      // this, isSubmitting never resets and the button spins forever.
      logger.e('PostOpportunityNotifier._run: Unexpected error', error: e, stackTrace: stackTrace);
      if (_disposed) return;

      state = state.copyWith(
        isSubmitting: false,
        clearSubmittingKind: true,
        submitError: 'Something went wrong. Please try again.',
        submitErrorRetryable: true,
      );
    }
  }
}

final postOpportunityProvider =
    NotifierProvider.autoDispose<PostOpportunityNotifier, PostOpportunityState>(
  PostOpportunityNotifier.new,
);