import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_insets.dart';
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
import 'package:trufit_bodamma/theme/app_typography.dart';
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

  double _targetCalories = 1250;
  bool _isCaloriesManuallyEdited = false;
  TargetMacros? _targetMacros;
  final List<String> _selectedHabitIds = ['sleep', 'walk', 'water'];

  @override
  void initState() {
    super.initState();
    _draftAccount = ref.read(activeAccountIdProvider);
    final profile = ref.read(profileProvider);
    _nameController.text = profile.name;
    _coachNameController.text = profile.coachName;
    if (profile.height != null)
      _heightController.text = profile.height.toString();
    _useKg = profile.useKg;
    if (profile.currentWeight != null) {
      final double displayW = _useKg
          ? profile.currentWeight!
          : profile.currentWeight! * 2.20462;
      _weightController.text = displayW
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '');
    }
    if (profile.targetCalories > 0) {
      _targetCalories = profile.targetCalories.toDouble();
      _isCaloriesManuallyEdited = profile.name.trim().isNotEmpty;
    }

    _targetMacros = TargetMacros(
      calories: profile.targetCalories, proteinG: profile.targetProteinG,
      carbsG: profile.targetCarbsG, fatG: profile.targetFatG,
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
        _pageController.nextPage(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Motion.deliberate,
          curve: Motion.enter,
        );
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
      _pageController.previousPage(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Motion.deliberate,
        curve: Motion.enter,
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
      final w = double.tryParse(wText);
      if (w != null) {
        final double wKg = _useKg ? w : w / 2.20462;
        if (!wKg.isFinite || wKg < 30 || wKg > 200) {
          FocusScope.of(context).requestFocus(_weightFocus);
          return false;
        }
      } else {
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

    double? finalWeight;
    final wText = _weightController.text;
    if (wText.isNotEmpty) {
      final w = double.tryParse(wText);
      if (w != null) finalWeight = _useKg ? w : w / 2.20462;
    }

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
      if (recovered == null || recovered == _draftAccount ||
          recovered != ref.read(activeAccountIdProvider)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || recovered != ref.read(activeAccountIdProvider)) return;
        final profile = ref.read(profileProvider);
        setState(() {
          _draftAccount = recovered;
          _nameController.text = profile.name;
          _coachNameController.text = profile.coachName;
          _heightController.text = profile.height?.toString() ?? '';
          _useKg = profile.useKg;
          _weightController.text = profile.currentWeight == null ? '' :
              (profile.currentWeight! * (_useKg ? 1 : 2.20462)).toStringAsFixed(1);
          _targetCalories = profile.targetCalories.toDouble();
          _isCaloriesManuallyEdited = true;
          _targetMacros = TargetMacros(
            calories: profile.targetCalories, proteinG: profile.targetProteinG,
            carbsG: profile.targetCarbsG, fatG: profile.targetFatG,
          );
          _selectedHabitIds
            ..clear()
            ..addAll(ref.read(habitRepoProvider).getHabits().map((habit) => habit.id));
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
                                final wText = _weightController.text;
                                if (wText.isNotEmpty) {
                                  final w = double.tryParse(wText);
                                  if (w != null) {
                                    if (_useKg) {
                                      _weightController.text = (w * 2.20462)
                                          .round()
                                          .toString();
                                    } else {
                                      _weightController.text = (w / 2.20462)
                                          .toStringAsFixed(1)
                                          .replaceAll(RegExp(r'\.0$'), '');
                                    }
                                  }
                                }
                                _useKg = !_useKg;
                              });
                            },
                          ),
                          YourPlanPage(
                            initialCalories: _targetCalories,
                            initialMacros: _targetMacros,
                            heightCm: double.tryParse(_heightController.text),
                            weightKg:
                                double.tryParse(_weightController.text) != null
                                ? (_useKg
                                      ? double.parse(_weightController.text)
                                      : double.parse(_weightController.text) /
                                            2.20462)
                                : null,
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
