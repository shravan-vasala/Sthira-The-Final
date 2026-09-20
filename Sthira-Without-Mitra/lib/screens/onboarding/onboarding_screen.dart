import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/habit.dart';
import '../../utils/target_calculator.dart';
import '../../theme/app_theme.dart';
import 'widgets/sthira_aura_background.dart';

import 'package:trufit_bodamma/widgets/primary_button.dart';

import 'pages/welcome_page.dart';
import 'pages/about_you_page.dart';
import 'pages/your_plan_page.dart';
import 'pages/connect_page.dart';
import '../../theme/app_motion.dart';

String kOnboardingCompletedKey = 'onboarding_completed';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;
  bool _showCompletion = false;
  bool _isSaving = false;
  bool _showErrors = false;
  late String _draftAccount;

  final _nameController = TextEditingController();
  final _coachNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final _nameFocus = FocusNode();
  final _heightFocus = FocusNode();
  final _weightFocus = FocusNode();

  bool _useKg = true;
  double? _unchangedWeightKg;
  String? _unchangedWeightText;
  bool? _unchangedWeightUsesKg;

  double? get _draftWeightKg {
    if (_weightController.text == _unchangedWeightText &&
        _useKg == _unchangedWeightUsesKg) {
      return _unchangedWeightKg;
    }
    final value = double.tryParse(_weightController.text);
    return value == null ? null : value / (_useKg ? 1 : 2.20462);
  }

  void _rememberWeight(double? kilograms) {
    _unchangedWeightKg = kilograms;
    _unchangedWeightText = _weightController.text;
    _unchangedWeightUsesKg = _useKg;
  }

  double _targetCalories = 1250;
  bool _isCaloriesManuallyEdited = false;
  TargetMacros? _targetMacros;
  int? _estimateAge;
  String? _estimateGender;
  String? _estimateActivity;
  String? _estimateGoal;
  final List<String> _selectedHabitIds = ['sleep', 'walk', 'water'];

  @override
  void initState() {
    super.initState();
    _draftAccount = ref.read(activeAccountIdProvider);
    final profile = ref.read(profileProvider);
    _nameController.text = profile.name;
    _coachNameController.text = profile.coachName;
    final newProfile = profile.name.trim().isEmpty;
    final initialHeight =
        profile.height ??
        (newProfile ? TargetCalculator.defaultHeightCm : null);
    _heightController.text = initialHeight?.toString() ?? '';
    _estimateAge = profile.age;
    _estimateGender = profile.gender;
    _estimateActivity = profile.activityLevel;
    _estimateGoal = profile.primaryGoal;
    _useKg = profile.useKg;
    final initialWeight =
        profile.currentWeight ??
        (newProfile ? TargetCalculator.defaultWeightKg : null);
    if (initialWeight != null) {
      final double displayW = _useKg ? initialWeight : initialWeight * 2.20462;
      _weightController.text = displayW
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '');
    }
    _rememberWeight(initialWeight);
    if (profile.targetCalories > 0) {
      _targetCalories = profile.targetCalories.toDouble();
      _isCaloriesManuallyEdited = profile.name.trim().isNotEmpty;
    }

    _targetMacros = TargetMacros(
      calories: profile.targetCalories,
      proteinG: profile.targetProteinG,
      carbsG: profile.targetCarbsG,
      fatG: profile.targetFatG,
    );
    final currentHabits = ref.read(habitRepoProvider).getHabits();
    if (currentHabits.isNotEmpty) {
      _selectedHabitIds.clear();
      _selectedHabitIds.addAll(currentHabits.map((h) => h.id));
    }

    _nameController.addListener(_triggerRebuild);
    _heightController.addListener(_triggerRebuild);
    _weightController.addListener(_triggerRebuild);
  }

  void _triggerRebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_triggerRebuild);
    _heightController.removeListener(_triggerRebuild);
    _weightController.removeListener(_triggerRebuild);
    _pageController.dispose();
    _nameController.dispose();
    _coachNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _nameFocus.dispose();
    _heightFocus.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  void _completeRoute() {
    ref.read(onboardingCompletedProvider.notifier).completeRoute();
  }

  Future<void> _goNext() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      if (_currentPage == 1) {
        setState(() => _showErrors = true);
        if (!_validateProfile()) return;
        if (!mounted) return;
      }
      if (_currentPage == 2) {
        if (_selectedHabitIds.isEmpty) return;
      }

      if (_currentPage < _totalPages - 1) {
        HapticFeedback.selectionClick();
        _moveToPage(_currentPage + 1);
      } else {
        await _commitAllToDb();
        await ref.read(onboardingCompletedProvider.notifier).commitLocalSetup();

        if (!mounted) return;
        HapticFeedback.lightImpact();
        setState(() {
          _showCompletion = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      HapticFeedback.selectionClick();
      _moveToPage(_currentPage - 1);
    }
  }

  void _moveToPage(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(page);
    } else {
      unawaited(
        _pageController.animateToPage(
          page,
          duration: Motion.deliberate,
          curve: Motion.enter,
        ),
      );
    }
  }

  bool _validateProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      FocusScope.of(context).requestFocus(_nameFocus);
      return false;
    }

    final hText = _heightController.text;
    if (hText.isNotEmpty) {
      final h = double.tryParse(hText);
      if (h == null || !h.isFinite || h < 100 || h > 230) {
        FocusScope.of(context).requestFocus(_heightFocus);
        return false;
      }
    }

    final wText = _weightController.text;
    if (wText.isNotEmpty) {
      final wKg = _draftWeightKg;
      if (wKg == null || !wKg.isFinite || wKg < 30 || wKg > 200) {
        FocusScope.of(context).requestFocus(_weightFocus);
        return false;
      }
    }
    return true;
  }

  Future<void> _commitAllToDb() async {
    if (_draftAccount != ref.read(activeAccountIdProvider)) {
      final current = ref.read(profileProvider);
      // Keep a recovered profile. An empty new account may still use this draft.
      if (ref.read(recoveredAccountProvider) ==
          ref.read(activeAccountIdProvider)) {
        _nameController.text = current.name;
        return;
      }
    }
    double? finalHeight;
    final hText = _heightController.text;
    if (hText.isNotEmpty) finalHeight = double.tryParse(hText);

    final wText = _weightController.text;
    final finalWeight = _draftWeightKg;

    final current = ref.read(profileProvider);
    await ref
        .read(profileProvider.notifier)
        .updateProfile(
          current.copyWith(
            name: _nameController.text.trim(),
            coachName: _coachNameController.text.trim(),
            height: finalHeight,
            clearHeight: hText.isEmpty,
            currentWeight: finalWeight,
            clearCurrentWeight: wText.isEmpty,
            useKg: _useKg,
            age: _estimateAge,
            gender: _estimateGender,
            activityLevel: _estimateActivity,
            primaryGoal: _estimateGoal,
            targetCalories: _targetCalories.round(),
            targetProteinG: _targetMacros?.proteinG,
            targetCarbsG: _targetMacros?.carbsG,
            targetFatG: _targetMacros?.fatG,
          ),
        );

    final habitRepo = ref.read(habitRepoProvider);
    final currentHabits = habitRepo.getHabits();

    for (final defHabit in Habit.defaults) {
      final isSelected = _selectedHabitIds.contains(defHabit.id);
      final exists = currentHabits.any((h) => h.id == defHabit.id);
      if (isSelected && !exists) {
        await habitRepo.saveHabit(defHabit);
      } else if (!isSelected && exists) {
        await habitRepo.deleteHabit(defHabit.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recoveredAccountProvider, (previous, recovered) {
      if (recovered == null ||
          recovered == _draftAccount ||
          recovered != ref.read(activeAccountIdProvider))
        return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || recovered != ref.read(activeAccountIdProvider)) return;
        final profile = ref.read(profileProvider);
        setState(() {
          _draftAccount = recovered;
          _nameController.text = profile.name;
          _coachNameController.text = profile.coachName;
          _heightController.text = profile.height?.toString() ?? '';
          _useKg = profile.useKg;
          _weightController.text = profile.currentWeight == null
              ? ''
              : (profile.currentWeight! * (_useKg ? 1 : 2.20462))
                    .toStringAsFixed(1);
          _rememberWeight(profile.currentWeight);
          _estimateAge = profile.age;
          _estimateGender = profile.gender;
          _estimateActivity = profile.activityLevel;
          _estimateGoal = profile.primaryGoal;
          _targetCalories = profile.targetCalories.toDouble();
          _isCaloriesManuallyEdited = true;
          _targetMacros = TargetMacros(
            calories: profile.targetCalories,
            proteinG: profile.targetProteinG,
            carbsG: profile.targetCarbsG,
            fatG: profile.targetFatG,
          );
          _selectedHabitIds
            ..clear()
            ..addAll(
              ref.read(habitRepoProvider).getHabits().map((habit) => habit.id),
            );
        });
      });
    });
    if (_showCompletion) {
      return CompletionScreen(
        name: _nameController.text.trim(),
        onComplete: _completeRoute,
      );
    }

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        body: PopScope(
          canPop: _currentPage == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !_isSaving) {
              _goBack();
            }
          },
          child: Stack(
            children: [
              SthiraAuraBackground(currentPage: _currentPage),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        children: [
                          const WelcomePage(),
                          AboutYouPage(
                            nameController: _nameController,
                            coachController: _coachNameController,
                            heightController: _heightController,
                            weightController: _weightController,
                            nameFocus: _nameFocus,
                            heightFocus: _heightFocus,
                            weightFocus: _weightFocus,
                            useKg: _useKg,
                            showErrors: _showErrors,
                            onToggleUnit: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                final canonicalWeight = _draftWeightKg;
                                _useKg = !_useKg;
                                if (canonicalWeight != null) {
                                  _weightController.text =
                                      (canonicalWeight * (_useKg ? 1 : 2.20462))
                                          .toStringAsFixed(2)
                                          .replaceFirst(RegExp(r'\.?0+$'), '');
                                }
                                _rememberWeight(canonicalWeight);
                              });
                            },
                          ),
                          YourPlanPage(
                            key: ValueKey(ref.watch(accountGenerationProvider)),
                            age: _estimateAge,
                            gender: _estimateGender,
                            activityLevel: _estimateActivity,
                            goal: _estimateGoal,
                            useKg: _useKg,
                            estimateSession: ref.watch(
                              accountGenerationProvider,
                            ),
                            estimatesEnabled:
                                !ref.watch(accountTransitionProvider) &&
                                !ref.watch(accountHydratingProvider),
                            onEstimateApplied: (estimate) {
                              setState(() {
                                _estimateAge = estimate.inputs.age;
                                _estimateGender = estimate.inputs.gender;
                                _estimateActivity =
                                    estimate.inputs.activityLevel;
                                _estimateGoal = estimate.inputs.goal;
                                _heightController.text = estimate
                                    .inputs
                                    .heightCm
                                    .toString();
                                _weightController.text =
                                    (estimate.inputs.weightKg *
                                            (_useKg ? 1 : 2.20462))
                                        .toStringAsFixed(2)
                                        .replaceFirst(RegExp(r'\.?0+$'), '');
                                _rememberWeight(estimate.inputs.weightKg);
                              });
                            },
                            initialCalories: _targetCalories,
                            initialMacros: _targetMacros,
                            heightCm: double.tryParse(_heightController.text),
                            weightKg: _draftWeightKg,
                            selectedHabitIds: _selectedHabitIds,
                            isManuallyEdited: _isCaloriesManuallyEdited,
                            onCaloriesChanged: (v, manual) {
                              _targetCalories = v;
                              _isCaloriesManuallyEdited = manual;
                            },
                            onMacrosChanged: (m) => _targetMacros = m,
                            onHabitToggled: (id, selected) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (selected) {
                                  if (!_selectedHabitIds.contains(id))
                                    _selectedHabitIds.add(id);
                                } else {
                                  if (_selectedHabitIds.length > 1) {
                                    _selectedHabitIds.remove(id);
                                  }
                                }
                              });
                            },
                          ),
                          const ConnectPage(),
                        ],
                      ),
                    ),
                    _NavButtons(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      canGoNext: _canGoNext(),
                      isSaving: _isSaving,
                      onNext: _goNext,
                      onBack: _goBack,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canGoNext() {
    if (_currentPage == 1) {
      return true; // Allow attempting Next to surface validation errors
    }
    if (_currentPage == 2) {
      if (_selectedHabitIds.isEmpty) return false;
    }
    return true;
  }
}

class _NavButtons extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool canGoNext;
  final bool isSaving;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _NavButtons({
    required this.currentPage,
    required this.totalPages,
    required this.canGoNext,
    required this.isSaving,
    required this.onNext,
    required this.onBack,
  });

  bool get _isLastPage => currentPage == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          Row(
            // Progress dots
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              final active = index == currentPage;
              final completed = index < currentPage;
              return AnimatedContainer(
                duration: Motion.standard,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active || completed
                      ? context.colors.primary
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentPage > 0)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.onPrimary.withValues(alpha: 0.05),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: context.colors.textMedium,
                    ),
                  ),
                )
              else
                const SizedBox(width: 48), // spacer placeholder for first page
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  onPressed: canGoNext ? onNext : null,
                  isLoading: _isLastPage && isSaving,
                  label: _isLastPage ? 'Start my journey' : 'Next',
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(width: 48), // Balancing spacer on the right
            ],
          ),
        ],
      ),
    );
  }
}
