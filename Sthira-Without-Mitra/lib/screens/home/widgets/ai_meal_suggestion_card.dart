import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

import 'package:trufit_bodamma/theme/app_colors.dart';
// TODO: Flagged for relocation! This file currently lives in home/widgets/
// but its only consumer is `lib/screens/home/meal_detail_screen.dart`.
// It should likely be moved to a shared location.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/surface_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../providers/app_providers.dart';
import '../../../services/ai_client.dart';

class AIMealSuggestionCard extends ConsumerStatefulWidget {
  final int remainingCalories;
  final double? remainingProtein;
  final double? remainingCarbs;
  final double? remainingFat;
  final String? mealName;
  final int mealsLeft;

  const AIMealSuggestionCard({
    super.key,
    required this.remainingCalories,
    required this.remainingProtein,
    required this.remainingCarbs,
    required this.remainingFat,
    this.mealName,
    this.mealsLeft = 1,
  });

  @override
  ConsumerState<AIMealSuggestionCard> createState() =>
      _AIMealSuggestionCardState();
}

class _AIMealSuggestionCardState extends ConsumerState<AIMealSuggestionCard> {
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _suggestionText;
  String? _error;
  StreamSubscription<String>? _activeSub;
  CancellationToken? _cancelToken;
  int _requestId = 0;

  void _resetSuggestion() {
    _requestId++;
    _cancelToken?.cancel();
    unawaited(_activeSub?.cancel());
    if (!mounted) return;
    setState(() {
      _suggestionText = null;
      _error = null;
      _isLoading = false;
      _isStreaming = false;
    });
  }

  @override
  void dispose() {
    unawaited(_activeSub?.cancel());
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(AIMealSuggestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remainingCalories != widget.remainingCalories ||
        oldWidget.remainingProtein != widget.remainingProtein ||
        oldWidget.remainingCarbs != widget.remainingCarbs ||
        oldWidget.remainingFat != widget.remainingFat ||
        oldWidget.mealName != widget.mealName ||
        oldWidget.mealsLeft != widget.mealsLeft) {
      _resetSuggestion();
    }
  }

  Future<void> _fetchSuggestion({bool fresh = false}) async {
    final previousSuggestion = _error == null ? _suggestionText : null;
    unawaited(_activeSub?.cancel());
    _cancelToken?.cancel();
    final token = _cancelToken = CancellationToken();
    final requestId = ++_requestId;
    final accountId = ref.read(activeAccountIdProvider);
    final generation = ref.read(accountGenerationProvider);
    final targetDate = ref.read(dateStringProvider);
    bool isCurrent() =>
        mounted &&
        !token.isCancelled &&
        requestId == _requestId &&
        ref.read(activeAccountIdProvider) == accountId &&
        ref.read(accountGenerationProvider) == generation &&
        ref.read(dateStringProvider) == targetDate;
    setState(() {
      _isLoading = true;
      _isStreaming = false;
      _error = null;
      _suggestionText = null;
    });

    try {
      final service = ref.read(geminiFoodServiceProvider);

      final dateStr = ref.read(dateStringProvider);
      final mealRepo = ref.read(mealRepoProvider);
      final todayLogs = mealRepo.getLogsInRange(dateStr, dateStr);
      final previousMeals = todayLogs
          .expand((l) => l.customSlots.values)
          .expand((slot) => slot.items)
          .map((i) => i.name ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      final stream = service.suggestMealStream(
        remainingCalories: widget.remainingCalories,
        remainingProtein: widget.remainingProtein,
        remainingCarbs: widget.remainingCarbs,
        remainingFat: widget.remainingFat,
        mealName: widget.mealName,
        mealsLeft: widget.mealsLeft,
        previousMeals: previousMeals,
        cancellationToken: token,
        targetDate: targetDate,
        forceRefresh: fresh,
        previousSuggestion: fresh ? previousSuggestion : null,
      );

      bool isFirstChunk = true;
      _activeSub = stream.listen(
        (chunk) {
          if (isCurrent()) {
            setState(() {
              if (isFirstChunk) {
                _isLoading = false;
                _isStreaming = true;
                _suggestionText = '';
                isFirstChunk = false;
              }
              _suggestionText = (_suggestionText ?? '') + chunk;
            });
          }
        },
        onError: (e) {
          if (isCurrent()) {
            setState(() {
              _error = e.toString();
              _isLoading = false;
              _isStreaming = false;
            });
          }
        },
        onDone: () {
          if (isCurrent()) {
            setState(() {
              _isStreaming = false;
            });
            if (isFirstChunk) {
              setState(() {
                _isLoading = false;
                _error = 'Failed to generate a suggestion. Please try again.';
              });
            }
          }
        },
      );
    } catch (e) {
      if (isCurrent()) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isStreaming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dateStringProvider, (previous, next) {
      if (previous != next) _resetSuggestion();
    });
    ref.listen(accountGenerationProvider, (previous, next) {
      if (previous != next) _resetSuggestion();
    });
    ref.listen(dailyMealLogProvider, (previous, next) {
      if (previous != next) _resetSuggestion();
    });

    if (widget.remainingCalories <= 0) {
      return SurfaceCard(
        margin: EdgeInsets.zero,
        elevation: SurfaceCardElevation.nested,
        child: Column(
          children: [
            Icon(
              Icons.restaurant_rounded,
              color: context.colors.primary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              widget.remainingCalories < 0
                  ? 'Above your calorie target'
                  : 'Calorie target logged',
              textAlign: TextAlign.center,
              style: context.text.cardTitle.copyWith(
                color: context.colors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.remainingCalories < 0
                  ? '${-widget.remainingCalories} kcal above your daily target, based on logged meals.'
                  : 'Your logged meals add up to your daily target.',
              style: context.text.body.copyWith(
                color: context.colors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SurfaceCard(
      margin: EdgeInsets.zero,
      elevation: SurfaceCardElevation.nested,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: context.colors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Meal ideas',
                  style: context.text.bodyStrong.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                    .animate(
                      onPlay: MediaQuery.disableAnimationsOf(context)
                          ? (c) => c.stop()
                          : (c) => c.repeat(),
                    )
                    .shimmer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Motion.instant
                          : Motion.deliberate,
                      color: context.colors.primary.withValues(alpha: 0.4),
                    ),
                const SizedBox(height: 8),
                Container(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                    .animate(
                      onPlay: MediaQuery.disableAnimationsOf(context)
                          ? (c) => c.stop()
                          : (c) => c.repeat(),
                    )
                    .shimmer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Motion.instant
                          : Motion.deliberate,
                      color: context.colors.primary.withValues(alpha: 0.4),
                    ),
                const SizedBox(height: 8),
                Container(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.4,
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                    .animate(
                      onPlay: MediaQuery.disableAnimationsOf(context)
                          ? (c) => c.stop()
                          : (c) => c.repeat(),
                    )
                    .shimmer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Motion.instant
                          : Motion.deliberate,
                      color: context.colors.primary.withValues(alpha: 0.4),
                    ),
              ],
            )
          else if (_suggestionText != null) ...[
            Wrap(
              children: [
                Text(
                  _suggestionText!,
                  style: context.text.body.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
                if (_isStreaming)
                  Text(
                        '▍',
                        style: context.text.body.copyWith(
                          color: context.colors.primary,
                        ),
                      )
                      .animate(
                        onPlay: MediaQuery.disableAnimationsOf(context)
                            ? (c) => c.stop()
                            : (c) => c.repeat(),
                      )
                      .fade(duration: Motion.deliberate),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                'This response was interrupted. Try again for a complete suggestion.',
                style: context.text.micro.copyWith(color: context.colors.red),
              ),
              const SizedBox(height: 8),
            ],
            if (!_isStreaming)
              CompactButton(
                label: _error == null ? 'Suggest something else' : 'Try again',
                icon: Icons.refresh_rounded,
                filled: false,
                onPressed: () => _fetchSuggestion(fresh: true),
              ),
          ] else ...[
            Text(
              'Ideas based on your remaining daily targets (${widget.remainingCalories} kcal). Review portions before logging.',
              style: context.text.body.copyWith(
                color: context.colors.textMedium,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: context.text.micro.copyWith(color: context.colors.red),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(onPressed: _fetchSuggestion, label: 'Suggest a Meal'),
          ],
        ],
      ),
    );
  }
}
