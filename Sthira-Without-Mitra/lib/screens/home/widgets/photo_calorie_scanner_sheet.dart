import '../../../utils/food_name.dart';
import 'dart:io';

import '../../../theme/app_motion.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'dart:async';

import '../../../services/ai_client.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/haptics.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../models/daily_meal_log.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';

import '../../../models/user_food_log.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/surface_card.dart';
import '../../../models/food_nutrition.dart';
import '../../../widgets/offline_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../services/ai_profiler.dart';
import '../../../services/image_preprocessor.dart';

import 'package:trufit_bodamma/theme/app_typography.dart';

/// Opens with photo-first capture, or describe-in-text when [isManualEntry] is true.
class PhotoCalorieScannerSheet extends ConsumerStatefulWidget {
  final String slotId;
  final String slotDisplayName;
  final bool isManualEntry;
  final MealSlotLog? appendToLog;

  const PhotoCalorieScannerSheet({
    super.key,
    required this.slotId,
    required this.slotDisplayName,
    this.isManualEntry = false,
    this.appendToLog,
  });

  @override
  ConsumerState<PhotoCalorieScannerSheet> createState() =>
      _PhotoCalorieScannerSheetState();
}

class _PhotoCalorieScannerSheetState
    extends ConsumerState<PhotoCalorieScannerSheet> {
  final _picker = ImagePicker();
  final _descriptionCtrl = TextEditingController();

  List<File> _selectedImages = [];
  final Map<String, Future<Uint8List?>> _preparedImages = {};
  bool _isPickingImage = false;
  final _scanStatus = ValueNotifier<String>('Preparing photos...');
  // AI Measurement Profiler
  AiProfileSession? profiler;

  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  bool _describeMode = false;
  String? _confidence;
  String? _errorMessage;
  String? _techErrorMsg;
  bool _isOffline = false;
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  int _connectivityRevision = 0;
  bool _isSavingMeal = false;

  int _analysisSessionToken = 0;
  Timer? _countdownTimer;
  final _cooldownSeconds = ValueNotifier<int>(0);
  CancellationToken? _cancellationToken;
  Timer? _statusTimer;

  void _startCooldown(int seconds) {
    _cooldownSeconds.value = seconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _cooldownSeconds.value--;
      if (_cooldownSeconds.value <= 0) {
        _cooldownSeconds.value = 0;
        timer.cancel();
      }
    });
  }

  void _cancelAnalysis() {
    _analysisSessionToken++;
    _cancellationToken?.cancel();
    _statusTimer?.cancel();
    _finishProfile(TerminalOutcome.cancelled);
    setState(() {
      _isAnalyzing = false;
    });
  }

  void _onScanProgress(AiScanStage stage, int session) {
    if (!mounted || session != _analysisSessionToken || !_isAnalyzing) return;
    _statusTimer?.cancel();
    _scanStatus.value = switch (stage) {
      AiScanStage.preparing => 'Preparing photos...',
      AiScanStage.analyzing => 'Identifying food and portions...',
      AiScanStage.retrying => 'AI is busy. Trying again...',
      AiScanStage.resolving => 'Calculating nutrition...',
    };
    if (stage == AiScanStage.analyzing || stage == AiScanStage.retrying) {
      _statusTimer = Timer(const Duration(seconds: 12), () {
        if (mounted && session == _analysisSessionToken && _isAnalyzing) {
          _scanStatus.value =
              'Still waiting for AI. You can cancel and keep your input.';
        }
      });
    }
  }

  void _finishProfile(TerminalOutcome outcome) {
    final session = profiler;
    if (session == null) return;
    session.endPhase('totalMs');
    session.recordMetadata(terminalOutcome: outcome);
    if (kEnableAiProfiling) {
      debugPrint('Meal scan: ${session.toMap()}');
    }
    profiler = null;
  }

  Future<Uint8List?> _preparePhoto(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final processed = await ImagePreprocessor.processImage(
        bytes,
        'image/jpeg',
      );
      return processed.$1;
    } catch (_) {
      // Store a handled failure; Analyze can retry without an unhandled future.
      return null;
    }
  }

  List<MealItemLog> _items = [];
  int _totalCalories = 0;
  double _totalProtein = 0.0;
  double _totalCarbs = 0.0;
  double _totalFat = 0.0;
  int _unresolvedCount = 0;

  final Map<int, MealItemLog> _baseItems = {};
  final Map<int, double> _itemScales = {};

  late String _initialDate;
  late String _initialUid;
  late String _initialAccountId;
  late int _initialAccountGeneration;
  Isar? _initialDatabase;

  @override
  void initState() {
    super.initState();
    _initialDate = ref.read(dateStringProvider);
    _initialUid = ref.read(authServiceProvider).uid ?? '';
    _initialAccountId = ref.read(activeAccountIdProvider);
    _initialAccountGeneration = ref.read(accountGenerationProvider);
    _initialDatabase = ref.read(activeDatabaseProvider);

    _describeMode = widget.isManualEntry;
    if (_describeMode) {
      // Stay on describe form until she estimates or adds items herself.
      _analysisComplete = false;
    }
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        _connectivityRevision++;
        _updateConnectivity(results);
      },
      onError: (Object _) {}, // A platform hint must not block a real request.
    );
    unawaited(_checkConnectivity());

    unawaited(
      ref.read(nutritionLookupServiceProvider).load().catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    _cancellationToken?.cancel();
    unawaited(_connectivitySubscription?.cancel());
    _countdownTimer?.cancel();
    _statusTimer?.cancel();
    _descriptionCtrl.dispose();
    _cooldownSeconds.dispose();
    _scanStatus.dispose();
    super.dispose();
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    if (!mounted) return;
    final offline =
        results.isNotEmpty &&
        results.every((result) => result == ConnectivityResult.none);
    if (offline != _isOffline) setState(() => _isOffline = offline);
  }

  Future<void> _checkConnectivity() async {
    final revision = _connectivityRevision;
    try {
      final results = await _connectivity.checkConnectivity();
      if (revision == _connectivityRevision) _updateConnectivity(results);
    } catch (_) {
      // Connectivity is advisory; the request itself handles network failures.
    }
  }

  void _applyResult(Map<String, dynamic> result) {
    if (!_ownsCurrentLog) {
      if (mounted)
        _showError(
          'Date or account changed. Reopen this meal to log it.',
          _analysisSessionToken,
        );
      return;
    }
    final session = profiler;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        session.endPhase('firstUsableFrameMs');
        if (identical(profiler, session)) {
          _finishProfile(
            _unresolvedCount > 0
                ? TerminalOutcome.partial
                : (session.cacheHit
                      ? TerminalOutcome.cacheCompletion
                      : TerminalOutcome.success),
          );
        }
      });
    }
    if (!mounted) return;

    final itemsData = result['items'] as List?;
    final totalData = result['total'] as Map<String, dynamic>?;

    final newItems = (itemsData ?? []).map((i) {
      final m = i as Map<String, dynamic>;
      return MealItemLog(
        name: m['name']?.toString() ?? 'Unknown',
        portion: m['portion']?.toString() ?? '1 serving',
        computedNutrition: FoodNutrition(
          kcal: (m['calories'] as num?)?.toDouble() ?? 0,
          proteinG: (m['protein_g'] as num?)?.toDouble() ?? 0.0,
          carbsG: (m['carbs_g'] as num?)?.toDouble() ?? 0.0,
          fatG: (m['fat_g'] as num?)?.toDouble() ?? 0.0,
        ),
        baseNutrition: m['baseNutrition'] != null
            ? FoodNutrition.fromJson(m['baseNutrition'])
            : null,
        isPer100g: m['is_per_100g'] as bool? ?? false,
        servingGrams: (m['serving_grams'] as num?)?.toDouble(),
        consumedGrams: (m['estimated_grams'] as num?)?.toDouble(),
        provenance: m['provenance'] as String?,
        resolved: m['resolved'] as bool? ?? true,
      );
    }).toList();

    setState(() {
      if (widget.appendToLog != null) {
        _items = [..._previousItems(), ...newItems];
        _totalCalories =
            widget.appendToLog!.totalCalories +
            ((totalData?['calories'] as num?)?.toInt() ?? 0);
        _totalProtein =
            widget.appendToLog!.knownProtein +
            ((totalData?['protein_g'] as num?)?.toDouble() ?? 0.0);
        _totalCarbs =
            widget.appendToLog!.knownCarbs +
            ((totalData?['carbs_g'] as num?)?.toDouble() ?? 0.0);
        _totalFat =
            widget.appendToLog!.knownFat +
            ((totalData?['fat_g'] as num?)?.toDouble() ?? 0.0);
      } else {
        _items = newItems;
        _totalCalories = (totalData?['calories'] as num?)?.toInt() ?? 0;
        _totalProtein = (totalData?['protein_g'] as num?)?.toDouble() ?? 0.0;
        _totalCarbs = (totalData?['carbs_g'] as num?)?.toDouble() ?? 0.0;
        _totalFat = (totalData?['fat_g'] as num?)?.toDouble() ?? 0.0;
      }
      _recalculateTotals();
      _confidence = result['confidence']?.toString();
      _isAnalyzing = false;
      _analysisComplete = true;
      _errorMessage = null;

      _baseItems.clear();
      _itemScales.clear();
      for (int i = 0; i < _items.length; i++) {
        _baseItems[i] = _cloneItem(_items[i]);
        _itemScales[i] = 1.0;
      }
    });
  }

  MealItemLog _cloneItem(MealItemLog src) => src.copy();

  List<MealItemLog> _previousItems() {
    final previous = widget.appendToLog;
    if (previous == null) return [];
    if (previous.items.isNotEmpty) {
      final items = previous.items.map((item) {
        final copy = item.copy();
        if (!previous.hasKnownMacrosFor(item)) {
          copy.macrosKnown = false;
        }
        return copy;
      }).toList();
      // Older logs can hold a saved aggregate without per-food nutrition.
      // Keep its unassigned remainder as a clearly labeled subtotal instead of
      // discarding it or assigning it to an unresolved food.
      final itemCalories = items.fold(
        0.0,
        (sum, item) => sum + (item.computedNutrition?.kcal ?? 0),
      );
      final knownItems = items.where((item) => item.hasKnownMacros);
      double remainder(double saved, double itemTotal) =>
          (saved - itemTotal).clamp(0.0, double.infinity);
      final residual = FoodNutrition(
        kcal: remainder(previous.totalCalories.toDouble(), itemCalories),
        proteinG: remainder(
          previous.knownProtein,
          knownItems.fold(
            0.0,
            (sum, item) => sum + item.computedNutrition!.proteinG,
          ),
        ),
        carbsG: remainder(
          previous.knownCarbs,
          knownItems.fold(
            0.0,
            (sum, item) => sum + item.computedNutrition!.carbsG,
          ),
        ),
        fatG: remainder(
          previous.knownFat,
          knownItems.fold(
            0.0,
            (sum, item) => sum + item.computedNutrition!.fatG,
          ),
        ),
      );
      if (residual.kcal > 0 ||
          residual.proteinG > 0 ||
          residual.carbsG > 0 ||
          residual.fatG > 0) {
        items.add(
          MealItemLog(
            name: 'Previously saved totals',
            portion: 'Unassigned nutrition subtotal',
            computedNutrition: residual,
            provenance: 'saved_total',
            macrosKnown: true,
          ),
        );
      }
      return items;
    }
    if (previous.totalCalories == 0 &&
        previous.knownProtein == 0 &&
        previous.knownCarbs == 0 &&
        previous.knownFat == 0) {
      if (previous.isLogged &&
          (!previous.hasCompleteCalories || !previous.hasCompleteMacros)) {
        return [
          MealItemLog(
            name: 'Previously photographed meal',
            portion: previous.hasCompleteCalories
                ? 'Saved calories; macros not recorded'
                : 'Nutrition not recorded',
            provenance: 'legacy',
            computedNutrition: previous.hasCompleteCalories
                ? FoodNutrition(kcal: 0)
                : null,
            resolved: previous.hasCompleteCalories,
            macrosKnown: previous.hasCompleteMacros,
          ),
        ];
      }
      return [];
    }
    return [
      MealItemLog(
        name: 'Previously logged food',
        portion: 'Saved meal total',
        computedNutrition: FoodNutrition(
          kcal: previous.totalCalories.toDouble(),
          proteinG: previous.knownProtein,
          carbsG: previous.knownCarbs,
          fatG: previous.knownFat,
        ),
        provenance: 'legacy',
        resolved: previous.hasCompleteCalories,
        macrosKnown: previous.hasCompleteMacros,
      ),
    ];
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage || _isAnalyzing || _selectedImages.length >= 3) return;
    _isPickingImage = true;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (!mounted || picked == null) return;
      _analysisSessionToken++;
      final file = File(picked.path);
      _preparedImages[file.path] = _preparePhoto(file);
      setState(() {
        _selectedImages.add(file);
        _describeMode = false;
        _analysisComplete = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Could not open that photo. Please try again.',
        );
      }
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _analyzeImage({bool skipCache = false}) async {
    if (_selectedImages.isEmpty || _isAnalyzing) return;
    FocusManager.instance.primaryFocus?.unfocus();
    profiler = AiProfileSession()
      ..startPhase('totalMs')
      ..startPhase('firstUsableFrameMs');

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _techErrorMsg = null;
    });
    final currentToken = ++_analysisSessionToken;
    _cancellationToken?.cancel();
    final cancellation = _cancellationToken = CancellationToken();
    final images = List<File>.of(_selectedImages);
    final hint = _descriptionCtrl.text;
    final service = ref.read(geminiFoodServiceProvider);
    _onScanProgress(AiScanStage.preparing, currentToken);

    try {
      profiler?.startPhase('fileReadMs');
      final allBytes = await cancellation.waitFor(
        Future.wait(
          images.map((file) async {
            cancellation.throwIfCancelled();
            var bytes = await (_preparedImages[file.path] ??= _preparePhoto(
              file,
            ));
            cancellation.throwIfCancelled();
            if (bytes == null) {
              _preparedImages[file.path] = _preparePhoto(file);
              bytes = await _preparedImages[file.path]!;
            }
            if (bytes == null) {
              throw AiException(
                'Could not read this photo. Try another JPEG or PNG.',
                cause: AiErrorCause.parse,
              );
            }
            return bytes;
          }),
        ),
        timeout: const Duration(seconds: 10),
      );
      if (!mounted || currentToken != _analysisSessionToken) return;
      profiler?.endPhase('fileReadMs');

      final String mimeType = 'image/jpeg';

      final result = await service.analyzeFoodImage(
        allBytes,
        mimeType,
        hint,
        skipCache,
        true, // isAlreadyProcessed
        cancellation,
        profiler,
        (stage) => _onScanProgress(stage, currentToken),
      );

      if (!mounted) return;

      if (currentToken != _analysisSessionToken) return;
      _statusTimer?.cancel();
      if (result != null) {
        _applyResult(result);
      } else {
        _showError('AI could not analyze the image.', currentToken);
      }
    } catch (e) {
      if (!mounted) return;
      _handleAnalyzeError(e, currentToken);
    }
  }

  Future<void> _analyzeDescription() async {
    if (_isAnalyzing) return;
    final text = _descriptionCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Type what you ate first — e.g. rice, sambar, curd'),
        ),
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    profiler = AiProfileSession();
    profiler!.startPhase('totalMs');
    profiler!.startPhase('firstUsableFrameMs');

    setState(() {
      _isAnalyzing = true;
      _analysisComplete = false;
      _errorMessage = null;
      _techErrorMsg = null;
      _items = [];
      _selectedImages = [];
      _preparedImages.clear();
    });
    final currentToken = ++_analysisSessionToken;
    _cancellationToken?.cancel();
    _cancellationToken = CancellationToken();
    _onScanProgress(AiScanStage.analyzing, currentToken);

    try {
      final result = await ref
          .read(geminiFoodServiceProvider)
          .analyzeFoodText(
            text,
            _cancellationToken,
            profiler,
            (stage) => _onScanProgress(stage, currentToken),
          );

      if (!mounted) return;

      if (currentToken != _analysisSessionToken) return;
      _statusTimer?.cancel();
      if (result != null) {
        _applyResult(result);
      } else {
        _showError(
          'AI could not estimate from that description.',
          currentToken,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _handleAnalyzeError(e, currentToken);
    }
  }

  void _handleAnalyzeError(Object e, int token) {
    if (token != _analysisSessionToken) return;
    _statusTimer?.cancel();
    _finishProfile(TerminalOutcome.error);
    final msg = e
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('AiException: ', '');
    String humanMsg = msg;
    AiErrorCause? cause;

    if (e is AiException) {
      cause = e.cause;
    }

    if (cause == AiErrorCause.rateLimited) {
      _startCooldown(90);
    } else if (cause == AiErrorCause.overloaded) {
      _startCooldown(30);
    }

    if (msg.contains('OFFLINE_FALLBACK') ||
        msg.contains('Service temporarily unavailable')) {
      humanMsg = 'OFFLINE_FALLBACK';
    }

    Haptics.error();
    setState(() {
      _isAnalyzing = false;
      _errorMessage = humanMsg;
      _techErrorMsg = msg;
    });
  }

  void _showError(String message, int token) {
    if (token != _analysisSessionToken) return;
    _statusTimer?.cancel();
    _finishProfile(TerminalOutcome.error);
    Haptics.error();
    setState(() {
      _isAnalyzing = false;
      _errorMessage = message;
    });
  }

  void _switchToDescribe() {
    _analysisSessionToken++;
    _cancellationToken?.cancel();
    _statusTimer?.cancel();
    _finishProfile(TerminalOutcome.cancelled);
    setState(() {
      _describeMode = true;
      _selectedImages = [];
      _preparedImages.clear();
      _analysisComplete = false;
      _errorMessage = null;
      _isAnalyzing = false;
      _items = [];
    });
  }

  void _switchToPhoto() {
    _analysisSessionToken++;
    _cancellationToken?.cancel();
    _statusTimer?.cancel();
    _finishProfile(TerminalOutcome.cancelled);
    setState(() {
      _describeMode = false;
      _analysisComplete = false;
      _errorMessage = null;
      _isAnalyzing = false;
      _items = [];
    });
  }

  void _enterManualItems() {
    _analysisSessionToken++;
    _cancellationToken?.cancel();
    _statusTimer?.cancel();
    _finishProfile(TerminalOutcome.cancelled);
    setState(() {
      _errorMessage = null;
      _isAnalyzing = false;
      _analysisComplete = true;
      if (_items.isEmpty) {
        if (widget.appendToLog != null) {
          _items = _previousItems();
          _totalCalories = widget.appendToLog!.totalCalories;
          _totalProtein = widget.appendToLog!.knownProtein;
          _totalCarbs = widget.appendToLog!.knownCarbs;
          _totalFat = widget.appendToLog!.knownFat;
        } else {
          _items = [
            MealItemLog(
              name: 'Unknown Dish',
              resolved: false,
              portion: '1 serving',
              computedNutrition: FoodNutrition(
                kcal: 0,
                proteinG: 0,
                carbsG: 0,
                fatG: 0,
              ),
            ),
          ];
        }
      }
      for (int i = 0; i < _items.length; i++) {
        _baseItems[i] = _cloneItem(_items[i]);
        _itemScales[i] = 1.0;
      }
      _recalculateTotals();
    });
    if (_items.length == 1 &&
        (_items.first.computedNutrition?.kcal ?? 0) == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _editItem(0));
    }
  }

  void _removeItem(int index) {
    final removedItem = _items[index];
    final removedBase = _baseItems[index];
    final removedScale = _itemScales[index];

    setState(() {
      _items.removeAt(index);

      for (int i = index; i < _items.length; i++) {
        _baseItems[i] = _baseItems[i + 1]!;
        _itemScales[i] = _itemScales[i + 1]!;
      }
      _baseItems.remove(_items.length);
      _itemScales.remove(_items.length);

      _recalculateTotals();
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedItem.name} removed'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: context.colors.primary,
          onPressed: () {
            if (!mounted || _isSavingMeal) return;
            setState(() {
              _items.insert(index, removedItem);

              for (int i = _items.length - 1; i > index; i--) {
                _baseItems[i] = _baseItems[i - 1]!;
                _itemScales[i] = _itemScales[i - 1]!;
              }
              if (removedBase != null) _baseItems[index] = removedBase;
              if (removedScale != null) _itemScales[index] = removedScale;

              _recalculateTotals();
            });
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _editItem(int? index) {
    final item = index != null
        ? _items[index]
        : MealItemLog(
            name: 'New Item',
            resolved: false,
            portion: '1 serving',
            computedNutrition: FoodNutrition(
              kcal: 0,
              proteinG: 0,
              carbsG: 0,
              fatG: 0,
            ),
          );
    final nameCtrl = TextEditingController(text: item.name);
    final portionCtrl = TextEditingController(text: item.portion);
    final calsCtrl = TextEditingController(
      text: item.resolved
          ? (item.computedNutrition?.kcal.round().toString() ?? '')
          : '',
    );
    final pCtrl = TextEditingController(
      text: item.hasKnownMacros
          ? (item.computedNutrition?.proteinG.toString() ?? '')
          : '',
    );
    final cCtrl = TextEditingController(
      text: item.hasKnownMacros
          ? (item.computedNutrition?.carbsG.toString() ?? '')
          : '',
    );
    final fCtrl = TextEditingController(
      text: item.hasKnownMacros
          ? (item.computedNutrition?.fatG.toString() ?? '')
          : '',
    );

    Widget macroField(TextEditingController controller, String label) =>
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        );
    final stackedMacros =
        MediaQuery.sizeOf(context).width < 420 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    String? inputError;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Edit Item',
            style: context.text.body.copyWith(color: context.colors.textDark),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: context.text.body.copyWith(
                      color: context.colors.textMedium,
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: context.colors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Portion',
                    labelStyle: context.text.body.copyWith(
                      color: context.colors.textMedium,
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: context.colors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: calsCtrl,
                  style: context.text.body,
                  decoration: InputDecoration(
                    labelText: 'Calories',
                    labelStyle: context.text.body.copyWith(
                      color: context.colors.textMedium,
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: context.colors.primary),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                if (stackedMacros) ...[
                  macroField(pCtrl, 'Protein (g)'),
                  const SizedBox(height: 12),
                  macroField(cCtrl, 'Carbs (g)'),
                  const SizedBox(height: 12),
                  macroField(fCtrl, 'Fat (g)'),
                ] else
                  Row(
                    children: [
                      Expanded(child: macroField(pCtrl, 'Protein (g)')),
                      const SizedBox(width: 12),
                      Expanded(child: macroField(cCtrl, 'Carbs (g)')),
                      const SizedBox(width: 12),
                      Expanded(child: macroField(fCtrl, 'Fat (g)')),
                    ],
                  ),
                if (inputError != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      inputError!,
                      style: context.text.caption.copyWith(
                        color: context.colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textMedium,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final cVal = double.tryParse(calsCtrl.text.trim());
                final pVal = double.tryParse(pCtrl.text.trim());
                final carbsVal = double.tryParse(cCtrl.text.trim());
                final fVal = double.tryParse(fCtrl.text.trim());
                final macros = [pVal, carbsVal, fVal];
                if (nameCtrl.text.trim().isEmpty ||
                    portionCtrl.text.trim().isEmpty ||
                    cVal == null ||
                    !cVal.isFinite ||
                    cVal < 0 ||
                    cVal > 9999 ||
                    macros.any(
                      (value) =>
                          value == null ||
                          !value.isFinite ||
                          value < 0 ||
                          value > 999.9,
                    )) {
                  setDialogState(
                    () => inputError =
                        'Add a name and portion, and valid non-negative nutrition values. Enter 0 only when known.',
                  );
                  return;
                }
                setState(() {
                  final newItem = item.copy()
                    ..name = nameCtrl.text.trim()
                    ..portion = portionCtrl.text.trim()
                    ..computedNutrition = FoodNutrition(
                      kcal: cVal.toDouble(),
                      proteinG: pVal!,
                      carbsG: carbsVal!,
                      fatG: fVal!,
                    )
                    ..resolved = true
                    ..macrosKnown = true;
                  if (portionCtrl.text.trim() != (item.portion ?? '').trim()) {
                    // Free text may describe a different amount or unit. Keep
                    // product identity, but do not retain a misleading quantity.
                    newItem
                      ..consumedGrams = null
                      ..consumedMl = null
                      ..consumedServings = null;
                  }
                  if (newItem.nutritionBasis == null) {
                    // A correction becomes the new serving basis; scaling must
                    // not silently restore the old database/AI numbers.
                    newItem
                      ..baseNutrition = FoodNutrition(
                        kcal: cVal,
                        proteinG: pVal,
                        carbsG: carbsVal,
                        fatG: fVal,
                      )
                      ..isPer100g = false
                      ..servingGrams = newItem.consumedGrams;
                  }
                  newItem.provenance = 'yours';

                  if (index != null) {
                    _items[index] = newItem;
                    _baseItems[index] = _cloneItem(newItem);
                    _itemScales[index] = 1.0;
                  } else {
                    _items.add(newItem);
                    _baseItems[_items.length - 1] = _cloneItem(newItem);
                    _itemScales[_items.length - 1] = 1.0;
                  }

                  _recalculateTotals();
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    _editItem(null);
  }

  void _setPortionScale(int index, double scale) {
    if (_baseItems[index] == null) return;
    Haptics.tap();
    setState(() {
      _itemScales[index] = scale;
      final base = _baseItems[index]!;
      FoodNutrition? newComputed;
      bool newResolved = base.resolved;
      final newConsumedGrams = base.consumedGrams != null
          ? (base.consumedGrams! * scale)
          : null;

      if (base.nutritionBasis == null &&
          base.baseNutrition != null &&
          newConsumedGrams != null) {
        try {
          newComputed = FoodNutrition.compute(
            consumedGrams: newConsumedGrams,
            baseNutrition: base.baseNutrition!,
            isPer100g: base.isPer100g,
            servingGrams: base.servingGrams,
          );
          newResolved = true;
        } on FormatException catch (_) {
          newResolved = false;
        }
      } else {
        newComputed = FoodNutrition(
          kcal: ((base.computedNutrition?.kcal ?? 0) * scale).roundToDouble(),
          proteinG: double.parse(
            ((base.computedNutrition?.proteinG ?? 0.0) * scale).toStringAsFixed(
              1,
            ),
          ),
          carbsG: double.parse(
            ((base.computedNutrition?.carbsG ?? 0.0) * scale).toStringAsFixed(
              1,
            ),
          ),
          fatG: double.parse(
            ((base.computedNutrition?.fatG ?? 0.0) * scale).toStringAsFixed(1),
          ),
        );
      }

      final scaled = base.copy()
        ..computedNutrition = newComputed
        ..consumedGrams = newConsumedGrams
        ..consumedMl = base.consumedMl == null ? null : base.consumedMl! * scale
        ..consumedServings = base.consumedServings == null
            ? null
            : base.consumedServings! * scale
        ..resolved = newResolved;
      if (base.nutritionBasis == null ||
          (scaled.consumedMl == null &&
              scaled.consumedGrams == null &&
              scaled.consumedServings == null)) {
        final originalPortion = base.portion?.trim();
        if (originalPortion != null && originalPortion.isNotEmpty) {
          scaled.portion = scale == 1
              ? originalPortion
              : '$scale \u00d7 $originalPortion';
        }
      }
      if (base.nutritionBasis != null) {
        final amount =
            scaled.consumedMl ??
            scaled.consumedGrams ??
            scaled.consumedServings;
        if (amount != null) {
          final unit = scaled.consumedMl != null
              ? 'ml'
              : scaled.consumedGrams != null
              ? 'g'
              : amount == 1
              ? 'serving'
              : 'servings';
          final quantity = amount
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\.?0+$'), '');
          scaled.portion = '$quantity $unit';
        }
      }
      _items[index] = scaled;
      _recalculateTotals();
    });
  }

  void _recalculateTotals() {
    int c = 0;
    double p = 0;
    double carbs = 0;
    double f = 0;
    int unresolved = 0;
    for (final i in _items) {
      c += i.computedNutrition?.kcal.round() ?? 0;
      if (i.hasKnownMacros) {
        p += i.computedNutrition?.proteinG ?? 0.0;
        carbs += i.computedNutrition?.carbsG ?? 0.0;
        f += i.computedNutrition?.fatG ?? 0.0;
      }
      if (!i.resolved || !i.hasKnownMacros) unresolved++;
    }
    _totalCalories = c;
    _totalProtein = p;
    _totalCarbs = carbs;
    _totalFat = f;
    _unresolvedCount = unresolved;
  }

  bool get _ownsCurrentLog =>
      mounted &&
      ref.read(dateStringProvider) == _initialDate &&
      (ref.read(authServiceProvider).uid ?? '') == _initialUid &&
      ref.read(activeAccountIdProvider) == _initialAccountId &&
      ref.read(accountGenerationProvider) == _initialAccountGeneration &&
      !ref.read(accountTransitionProvider);

  Future<void> _rememberFoods(Isar? database, List<MealItemLog> items) async {
    if (database == null || !database.isOpen) return;
    try {
      await database.writeTxn(() async {
        for (final item in items) {
          if (item.barcode != null ||
              !item.hasKnownMacros ||
              (item.computedNutrition?.kcal ?? 0) <= 0 ||
              (item.provenance != 'yours' && item.provenance != 'ai_estimate'))
            continue;
          final name = item.name?.trim() ?? '';
          if (name.isEmpty) continue;
          final normalized = canonicalFoodName(name);
          if (normalized.isEmpty) continue;
          final query = database.userFoodLogs.filter().normalizedNameEqualTo(
            normalized,
          );
          if (item.provenance == 'yours') {
            await query.deleteAll();
          } else if (await query.count() > 0) {
            continue;
          }
          await database.userFoodLogs.put(
            UserFoodLog(
              normalizedName: normalized,
              originalName: name,
              baseNutrition: item.computedNutrition!,
              isPer100g: false,
              servingGrams: item.consumedGrams,
              provenance: item.provenance,
              addedAt: DateTime.now(),
            ),
          );
        }
      });
    } catch (_) {
      // Remembering a shortcut is optional and cannot undo a saved meal.
    }
  }

  Future<void> _saveMeal() async {
    if (_isSavingMeal || _items.isEmpty) return;
    if (!_ownsCurrentLog) {
      _showError(
        'Date or account changed. Reopen this meal to log it.',
        _analysisSessionToken,
      );
      return;
    }
    final items = _items.map((item) => item.copy()).toList();
    final calories = _totalCalories;
    final protein = _totalProtein;
    final carbs = _totalCarbs;
    final fat = _totalFat;
    final unresolved = _unresolvedCount;
    final notifier = ref.read(dailyMealLogProvider.notifier);
    final database = _initialDatabase;
    setState(() => _isSavingMeal = true);
    try {
      final finalPhotoPaths = <String>[];
      if (_selectedImages.isNotEmpty) {
        if (!kIsWeb) {
          final mediaRepo = ref.read(mediaRepoProvider);
          for (final image in List<File>.of(_selectedImages)) {
            finalPhotoPaths.add(
              await mediaRepo.saveMediaFile(image.path, 'meal_photos'),
            );
          }
        } else {
          finalPhotoPaths.addAll(_selectedImages.map((file) => file.path));
        }
      }
      if (!_ownsCurrentLog) {
        if (mounted)
          _showError(
            'Date or account changed. Reopen this meal to log it.',
            _analysisSessionToken,
          );
        return;
      }
      final slotLog = MealSlotLog(
        name: widget.slotDisplayName,
        photoPath: finalPhotoPaths.isEmpty
            ? widget.appendToLog?.photoPath
            : finalPhotoPaths.first,
        photoPaths: [
          ...(widget.appendToLog?.photoPaths ?? []),
          ...finalPhotoPaths,
        ],
        items: items,
        totalCalories: calories,
        totalProtein: protein,
        totalCarbs: carbs,
        totalFat: fat,
        confidence: _confidence ?? widget.appendToLog?.confidence,
        caloriesComplete: items.every((item) => item.resolved),
        macrosComplete: items.every((item) => item.hasKnownMacros),
      );
      await notifier.saveMealSlot(
        widget.slotId,
        slotLog,
        targetDate: _initialDate,
      );
      // The durable log comes first; optional personal shortcuts do not delay UI.
      unawaited(_rememberFoods(database, items));
      if (mounted) {
        Haptics.success();
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              unresolved > 0
                  ? 'Saved ${widget.slotDisplayName} with $unresolved ${unresolved == 1 ? 'item' : 'items'} still to review.'
                  : 'Logged $calories kcal for ${widget.slotDisplayName}.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Haptics.error();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save meal. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingMeal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showChooser =
        !_analysisComplete &&
        !_isAnalyzing &&
        _errorMessage == null &&
        _selectedImages.isEmpty;

    final title = widget.appendToLog != null
        ? 'Add to ${widget.slotDisplayName}'
        : 'Log ${widget.slotDisplayName}';

    return AppSheet(
      title: title,
      subtitle: widget.appendToLog != null
          ? 'Add another serving to this meal'
          : _describeMode
          ? 'Describe home cooking — AI estimates macros'
          : 'Photo of your plate works best for home meals',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isOffline && !_analysisComplete)
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: OfflineBanner(),
            ),

          if (showChooser && !_describeMode) ...[
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 40,
                    color: context.colors.textDark,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Snap what you ate',
                    style: context.text.cardTitle.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Best for home-cooked plates',
                    style: context.text.caption.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _actionPair(
                    context,
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_rounded, size: 18),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.accentText,
                        backgroundColor: context.colors.primary.withValues(
                          alpha: 0.1,
                        ),
                        minimumSize: const Size(48, 48),
                        side: BorderSide(
                          color: context.colors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Minimalist Tile for secondary action
            InkWell(
              onTap: _switchToDescribe,
              borderRadius: BorderRadius.circular(20),
              child: SurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      color: context.colors.textDark,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Or describe in text',
                        style: context.text.bodyStrong.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.textMedium,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Minimalist Tile for manual macros
            InkWell(
              onTap: _enterManualItems,
              borderRadius: BorderRadius.circular(20),
              child: SurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: context.colors.textDark,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Enter macros yourself',
                        style: context.text.bodyStrong.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.textMedium,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ] else if ((showChooser || _isAnalyzing) && _describeMode) ...[
            Text(
              'What did you eat?',
              style: context.text.body.copyWith(color: context.colors.textDark),
            ),
            const SizedBox(height: 8),
            if (!_isAnalyzing)
              _MyFoodsScroller(
                database: _initialDatabase,
                onFoodTap: (food) {
                  // Instantly inject validated personal food
                  if (!mounted) return;
                  setState(() {
                    _describeMode = false;
                    _isAnalyzing = false;
                    _analysisComplete = true;
                    _errorMessage = null;
                    final item = MealItemLog(
                      name: food.originalName,
                      portion: '1 serving',
                      computedNutrition: FoodNutrition(
                        kcal: food.baseNutrition.kcal,
                        proteinG: food.baseNutrition.proteinG,
                        carbsG: food.baseNutrition.carbsG,
                        fatG: food.baseNutrition.fatG,
                      ),
                      resolved: true,
                    );
                    item.provenance = food.provenance ?? 'yours';

                    if (_items.isEmpty) {
                      if (widget.appendToLog != null) {
                        _items = _previousItems();
                      }
                    }
                    _items.add(item);
                    for (int index = 0; index < _items.length; index++) {
                      _baseItems[index] = _cloneItem(_items[index]);
                      _itemScales[index] = 1.0;
                    }
                    _recalculateTotals();
                  });
                },
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              enabled: !_isAnalyzing,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'e.g. 1 cup rice, chicken curry, beans fry, curd',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Estimate macros',
              icon: Icons.auto_awesome_rounded,
              onPressed: _isOffline ? null : _analyzeDescription,
              isLoading: _isAnalyzing,
            ),
            if (_isAnalyzing) _buildScanStatus(context),
            const SizedBox(height: 10),
            _actionPair(
              context,
              OutlinedButton.icon(
                onPressed: _switchToPhoto,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Use photo'),
              ),
              TextButton(
                onPressed: _enterManualItems,
                child: const Text('Enter yourself'),
              ),
            ),
          ] else if (_errorMessage == 'OFFLINE_FALLBACK') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.orange.withValues(alpha: 0.1),
                border: Border.all(
                  color: context.colors.orange.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: context.colors.orange,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI Service Offline',
                    style: context.text.bodyStrong.copyWith(
                      color: context.colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The AI system is temporarily overwhelmed or unavailable. Please log your macros manually for now.',
                    textAlign: TextAlign.center,
                    style: context.text.caption.copyWith(
                      color: context.colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enterManualItems,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Enter manual macros'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.orange,
                        foregroundColor: context.colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.red.withValues(alpha: 0.1),
                border: Border.all(
                  color: context.colors.red.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: context.colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: context.text.body.copyWith(
                            color: context.colors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_techErrorMsg != null &&
                      _techErrorMsg != _errorMessage) ...[
                    const SizedBox(height: 12),
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          'Details',
                          style: context.text.caption.copyWith(
                            color: context.colors.red,
                          ),
                        ),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        children: [
                          Text(
                            _techErrorMsg!,
                            style: context.text.micro.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ValueListenableBuilder<int>(
                    valueListenable: _cooldownSeconds,
                    builder: (context, cooldown, child) {
                      return ElevatedButton.icon(
                        onPressed: cooldown > 0
                            ? null
                            : () {
                                setState(() => _errorMessage = null);
                                if (_describeMode) {
                                  _analyzeDescription();
                                } else if (_selectedImages.isNotEmpty) {
                                  _analyzeImage(skipCache: true);
                                } else {
                                  _pickImage(ImageSource.gallery);
                                }
                              },
                        icon: cooldown > 0
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          cooldown > 0 ? 'Wait $cooldown s...' : 'Try again',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.red,
                          foregroundColor: context.colors.onPrimary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _actionPair(
              context,
              OutlinedButton(
                onPressed: _switchToDescribe,
                child: const Text('Describe instead'),
              ),
              ElevatedButton(
                onPressed: _enterManualItems,
                child: const Text('Enter yourself'),
              ),
            ),
          ] else if (_selectedImages.isNotEmpty || _isAnalyzing) ...[
            if (_selectedImages.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _selectedImages.length +
                          (_selectedImages.length < 3 && !_isAnalyzing ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          // Add angle button
                          return GestureDetector(
                            onTap: () => _pickImage(ImageSource.camera),
                            child: Container(
                              width: 120,
                              decoration: BoxDecoration(
                                color: context.colors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    color: context.colors.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add angle\n(Max 3)',
                                    textAlign: TextAlign.center,
                                    style: context.text.micro.copyWith(
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final img = _selectedImages[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              kIsWeb
                                  ? Image.network(
                                      img.path,
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      img,
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                              if (!_isAnalyzing)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _preparedImages.remove(
                                          _selectedImages[index].path,
                                        );
                                        _selectedImages.removeAt(index);
                                        if (_selectedImages.isEmpty) {
                                          _analysisComplete = false;
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: context.colors.textDark
                                            .withValues(alpha: 0.54),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: context.colors.onPrimary,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isAnalyzing)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildScanStatus(context),
                          const SizedBox(height: 16),
                          for (int i = 0; i < 2; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child:
                                  Container(
                                        height: 80,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: context.colors.surface
                                              .withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    height: 16,
                                                    width: 140,
                                                    decoration: BoxDecoration(
                                                      color: context
                                                          .colors
                                                          .textMedium
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    height: 12,
                                                    width: 80,
                                                    decoration: BoxDecoration(
                                                      color: context
                                                          .colors
                                                          .textMedium
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 48,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: context.colors.textMedium
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .animate(
                                        onPlay:
                                            MediaQuery.disableAnimationsOf(
                                              context,
                                            )
                                            ? (c) => c.stop()
                                            : (c) => c.repeat(),
                                      )
                                      .shimmer(
                                        duration:
                                            MediaQuery.disableAnimationsOf(
                                              context,
                                            )
                                            ? Motion.instant
                                            : Motion.deliberate,
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            if (_selectedImages.isNotEmpty &&
                !_isAnalyzing &&
                !_analysisComplete) ...[
              const SizedBox(height: 16),
              Text(
                'Optional hint',
                style: context.text.body.copyWith(
                  color: context.colors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. This is chicken biryani, normal portion',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Analyze Photo',
                icon: Icons.auto_awesome_rounded,
                onPressed: _isOffline ? null : _analyzeImage,
                isLoading: _isAnalyzing,
              ),
            ],
          ],

          if (_analysisComplete) ...[
            const SizedBox(height: 16),
            if (_confidence != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'AI estimate \u00b7 Check foods and portions before saving.',
                  style: context.text.caption,
                ),
              ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                final isResolved = item.resolved;
                final macrosKnown = item.hasKnownMacros;
                final scale = _itemScales[index] ?? 1.0;

                return Dismissible(
                  key: ValueKey('${item.name}_$index'),
                  direction: _isSavingMeal
                      ? DismissDirection.none
                      : DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: context.colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: context.colors.onPrimary,
                    ),
                  ),
                  onDismissed: (_) => _removeItem(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isResolved
                          ? Colors.transparent
                          : context.colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: isResolved
                          ? null
                          : Border.all(
                              color: context.colors.orange.withValues(
                                alpha: 0.4,
                              ),
                              width: 1,
                              style: BorderStyle
                                  .solid, // Should ideally be dashed, but sticking to standard border
                            ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          if (macrosKnown) ...[
                            Container(
                              width: 4,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: _getDominantMacroColor(item, context),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name ?? 'Unknown',
                                  style: context.text.bodyStrong.copyWith(
                                    color: isResolved
                                        ? context.colors.textDark
                                        : context.colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (isResolved) ...[
                                  Text(
                                    '${item.portion} • ${item.computedNutrition?.kcal.round() ?? 0} kcal',
                                    style: context.text.caption.copyWith(
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (macrosKnown)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildMacroPill(
                                          context,
                                          'Protein',
                                          '${item.computedNutrition?.proteinG.toStringAsFixed(1) ?? '0'}g',
                                          const Color(0xFFE8A163),
                                        ),
                                        _buildMacroPill(
                                          context,
                                          'Carbs',
                                          '${item.computedNutrition?.carbsG.toStringAsFixed(1) ?? '0'}g',
                                          const Color(0xFF8FB896),
                                        ),
                                        _buildMacroPill(
                                          context,
                                          'Fat',
                                          '${item.computedNutrition?.fatG.toStringAsFixed(1) ?? '0'}g',
                                          const Color(0xFFE58B88),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'Macros unknown - enter actual values to complete.',
                                      style: context.text.caption.copyWith(
                                        color: context.colors.orange,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildPortionChip(
                                        context,
                                        index,
                                        0.5,
                                        '½',
                                        scale,
                                      ),
                                      _buildPortionChip(
                                        context,
                                        index,
                                        1.0,
                                        '1×',
                                        scale,
                                      ),
                                      _buildPortionChip(
                                        context,
                                        index,
                                        1.5,
                                        '1½',
                                        scale,
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Text(
                                    'Couldn\'t estimate — tap edit to fix',
                                    style: context.text.caption.copyWith(
                                      color: context.colors.textMedium,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit ${item.name ?? 'food'}',
                            icon: Icon(
                              Icons.edit_rounded,
                              size: 20,
                              color: isResolved
                                  ? context.colors.textMedium
                                  : context.colors.orange,
                            ),
                            onPressed: _isSavingMeal
                                ? null
                                : () => _editItem(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildReviewSummary(context),
            const SizedBox(height: 16),
            PrimaryButton(
              label: _unresolvedCount > 0 ? 'Save partial log' : 'Save Log',
              icon: Icons.check_circle_rounded,
              onPressed: _saveMeal,
              isLoading: _isSavingMeal,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewSummary(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final summary = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              (_unresolvedCount > 0
                      ? context.colors.orange
                      : context.colors.primary)
                  .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _unresolvedCount > 0 ? 'Known total' : 'Total',
              style: context.text.caption,
            ),
            Text('$_totalCalories kcal', style: context.text.cardTitle),
            if (_unresolvedCount > 0)
              Text(
                '$_unresolvedCount ${_unresolvedCount == 1 ? 'item needs' : 'items need'} review',
                style: context.text.caption,
              ),
          ],
        ),
      );
      final add = TextButton.icon(
        onPressed: _isSavingMeal ? null : _addItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      );
      if (constraints.maxWidth <
          320 * MediaQuery.textScalerOf(context).scale(1)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summary,
            Align(alignment: Alignment.centerRight, child: add),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: summary),
          const SizedBox(width: 8),
          add,
        ],
      );
    },
  );

  Widget _actionPair(BuildContext context, Widget first, Widget second) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth <
              260 * MediaQuery.textScalerOf(context).scale(1);
          final width = stacked
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              SizedBox(width: width, child: first),
              SizedBox(width: width, child: second),
            ],
          );
        },
      );

  Widget _buildScanStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _scanStatus,
              builder: (context, status, _) => Semantics(
                liveRegion: true,
                child: Text(status, style: context.text.caption),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cancel analysis',
            onPressed: _cancelAnalysis,
            icon: const Icon(Icons.cancel_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: context.text.caption.copyWith(color: context.colors.textDark),
      ),
    );
  }

  Widget _buildPortionChip(
    BuildContext context,
    int itemIndex,
    double scaleValue,
    String label,
    double currentScale,
  ) {
    final isSelected = currentScale == scaleValue;
    return Semantics(
      label: '$scaleValue times original portion',
      selected: isSelected,
      child: TextButton(
        onPressed: _isSavingMeal
            ? null
            : () => _setPortionScale(itemIndex, scaleValue),
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          foregroundColor: isSelected
              ? context.colors.accentText
              : context.colors.textMedium,
          backgroundColor: isSelected
              ? context.colors.primary.withValues(alpha: 0.15)
              : context.colors.inputFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isSelected
                  ? context.colors.primary.withValues(alpha: 0.5)
                  : context.colors.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Text(label, style: context.text.caption),
      ),
    );
  }

  Color _getDominantMacroColor(MealItemLog item, BuildContext context) {
    final pCal = (item.computedNutrition?.proteinG ?? 0) * 4;
    final cCal = (item.computedNutrition?.carbsG ?? 0) * 4;
    final fCal = (item.computedNutrition?.fatG ?? 0) * 9;

    if (pCal >= cCal && pCal >= fCal) return context.colors.green;
    if (cCal >= pCal && cCal >= fCal) return context.colors.orange;
    return context.colors.primary;
  }
}

class _MyFoodsScroller extends StatefulWidget {
  final Function(UserFoodLog) onFoodTap;
  final Isar? database;

  const _MyFoodsScroller({required this.onFoodTap, required this.database});

  @override
  State<_MyFoodsScroller> createState() => _MyFoodsScrollerState();
}

class _MyFoodsScrollerState extends State<_MyFoodsScroller> {
  List<UserFoodLog> _myFoods = [];
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadMyFoods();
    _setupSubscription();
  }

  void _setupSubscription() {
    final database = widget.database;
    if (database == null || !database.isOpen) return;
    try {
      _subscription = database.userFoodLogs.watchLazy().listen(
        (_) => unawaited(_loadMyFoods()),
        onError: (Object _) {},
      );
    } catch (_) {
      // Personal shortcuts are optional during account/database transitions.
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _loadMyFoods() async {
    final database = widget.database;
    if (database == null || !database.isOpen) return;
    try {
      final foods = await database.userFoodLogs
          .where()
          .sortByAddedAtDesc()
          .limit(10)
          .findAll();
      if (mounted) setState(() => _myFoods = foods);
    } catch (_) {
      // The scan form remains usable if optional shortcuts cannot be read.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_myFoods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _myFoods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final food = _myFoods[index];
              return GestureDetector(
                onTap: () {
                  Haptics.tap();
                  widget.onFoodTap(food);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          food.originalName,
                          style: context.text.caption.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
