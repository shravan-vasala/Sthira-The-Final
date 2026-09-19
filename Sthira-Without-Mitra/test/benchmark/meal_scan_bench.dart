import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/ai_client.dart';
import 'package:trufit_bodamma/services/ai_profiler.dart';
import 'package:trufit_bodamma/services/gemini_food_service.dart';
import 'package:trufit_bodamma/services/nutrition_lookup_service.dart';

// Helper for F1 Score with 1-to-1 matching
double calculateF1(List<String> trueNames, List<String> predNames) {
  if (trueNames.isEmpty && predNames.isEmpty) return 1.0;
  if (trueNames.isEmpty || predNames.isEmpty) return 0.0;

  int truePositives = 0;
  final Set<int> matchedTrueIdx = {};

  for (var pred in predNames) {
    for (int i = 0; i < trueNames.length; i++) {
      if (!matchedTrueIdx.contains(i)) {
        final t = trueNames[i];
        if (t.toLowerCase().contains(pred.toLowerCase()) ||
            pred.toLowerCase().contains(t.toLowerCase())) {
          truePositives++;
          matchedTrueIdx.add(i);
          break; // move to next pred once matched
        }
      }
    }
  }

  double precision = truePositives / predNames.length;
  double recall = truePositives / trueNames.length;

  if (precision + recall == 0) return 0.0;
  return 2 * (precision * recall) / (precision + recall);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Meal Scan AI-01 Benchmark', () async {
    // Replace with your real Gemini API key
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      fail('RUN_BENCH requires GEMINI_API_KEY. No live benchmark was run.');
    }

    if (!kEnableAiProfiling) {
      fail(
        'RUN_BENCH requires --dart-define=AI_PROFILE=true for valid timings.',
      );
    }

    // Load Fixtures
    final fixturesDir = Directory('test/fixtures/meal_scan');
    if (!fixturesDir.existsSync()) {
      fail('Meal scan fixtures directory is missing.');
    }

    final gtFile = File('${fixturesDir.path}/ground_truth.json');
    if (!gtFile.existsSync()) {
      fail('ground_truth.json is missing.');
    }

    final gtData = jsonDecode(gtFile.readAsStringSync()) as List<dynamic>;

    final aiClient = AiClient();
    addTearDown(aiClient.dispose);
    final nutritionLookup = NutritionLookupService();
    final service = GeminiFoodService(
      apiKey: apiKey,
      aiClient: aiClient,
      nutritionLookup: nutritionLookup,
    );

    final resultsCsv = File('test/benchmark/baseline_results.csv');
    if (!resultsCsv.existsSync()) resultsCsv.createSync(recursive: true);

    final sink = resultsCsv.openWrite(mode: FileMode.writeOnly);
    sink.writeln(
      'id,iteration,totalMs,preprocessMs,networkMs,totalKcalMape,itemF1,schemaFailed,hallucinations,thoughtsTokens,model,attempts,weighed',
    );

    const iterations = int.fromEnvironment('ITERATIONS', defaultValue: 3);
    expect(iterations, greaterThan(0));

    final List<int> allTotalMs = [];
    final List<int> allNetworkMs = [];

    int totalItemsTested = 0;
    double sumKcalMape = 0;
    double sumItemF1 = 0;
    int hallucinations = 0;
    int schemaFailures = 0;

    print(
      'Accuracy values for unweighed/synthetic fixtures are diagnostics, not measured food accuracy.',
    );
    print(
      'Starting benchmark across ${gtData.length} images for $iterations iterations...',
    );

    for (var gt in gtData) {
      final id = gt['id'];
      final images = List<String>.from(gt['images'] ?? []);
      final gtItems = List<dynamic>.from(gt['items'] ?? []);
      final gtTotalKcal = (gt['total_kcal'] as num).toDouble();

      expect(
        images,
        isNotEmpty,
        reason: 'Every fixture needs its complete image set.',
      );
      for (final imageName in images) {
        expect(
          File(fixturesDir.path + '/images/' + imageName).existsSync(),
          isTrue,
          reason: 'Missing image: ' + imageName,
        );
      }

      for (int i = 0; i < iterations; i++) {
        final profiler = AiProfileSession();
        profiler.startPhase('totalMs');
        profiler.startPhase('fileReadMs');
        final imageBytesList = await Future.wait(
          images.map(
            (name) => File(fixturesDir.path + '/images/' + name).readAsBytes(),
          ),
        );
        profiler.endPhase('fileReadMs');

        Map<String, dynamic>? result;
        try {
          result = await service.analyzeFoodImage(
            imageBytesList,
            'image/jpeg',
            '',
            true, // skip cache
            false,
            null,
            profiler,
          );
          profiler.recordMetadata(terminalOutcome: TerminalOutcome.success);
        } catch (e) {
          print('Schema/API failure on $id iter $i: $e');
          profiler.recordMetadata(
            terminalOutcome: TerminalOutcome.error,
            failureReason: e.toString(),
          );
          schemaFailures++;
        }

        profiler.endPhase('totalMs');
        final session = profiler.toMap();

        allTotalMs.add(session['totalMs'] ?? 0);
        allNetworkMs.add(session['networkMs'] ?? 0);

        double kcalMape = 0;
        double itemF1 = 0;
        int iterHallucinations = 0;

        if (result != null) {
          final resItems = List<dynamic>.from(result['items'] ?? []);
          final resTotalKcal =
              (result['total']?['calories'] as num?)?.toDouble() ?? 0;

          if (gtTotalKcal > 0) {
            kcalMape =
                ((resTotalKcal - gtTotalKcal).abs() / gtTotalKcal) * 100.0;
          }

          final gtNames = gtItems.map((e) => e['name'].toString()).toList();
          final resNames = resItems.map((e) => e['name'].toString()).toList();
          itemF1 = calculateF1(gtNames, resNames);

          for (var rName in resNames) {
            bool found = gtNames.any(
              (g) =>
                  g.toLowerCase().contains(rName.toLowerCase()) ||
                  rName.toLowerCase().contains(g.toLowerCase()),
            );
            if (!found) iterHallucinations++;
          }

          sumKcalMape += kcalMape;
          sumItemF1 += itemF1;
          hallucinations += iterHallucinations;
          totalItemsTested++;
        }

        sink.writeln(
          '$id,$i,${session['totalMs']},${session['preprocessMs']},${session['networkMs']},${kcalMape.toStringAsFixed(2)},${itemF1.toStringAsFixed(2)},${result == null ? 1 : 0},$iterHallucinations,${session['thoughtsTokenCount'] ?? ''},${session['modelUsed'] ?? ''},${session['attemptCount']},${gt['weighed'] == true}',
        );
      }
    }

    await sink.flush();
    await sink.close();

    allTotalMs.sort();
    allNetworkMs.sort();

    int p50(List<int> l) => l.isEmpty ? 0 : l[(l.length * 0.50).floor()];
    int p90(List<int> l) => l.isEmpty ? 0 : l[(l.length * 0.90).floor()];
    int p99(List<int> l) => l.isEmpty ? 0 : l[(l.length * 0.99).floor()];

    print('\\n--- Benchmark Results ---');
    print(
      'Total Latency: p50: ${p50(allTotalMs)}ms, p90: ${p90(allTotalMs)}ms, p99: ${p99(allTotalMs)}ms',
    );
    print(
      'Network Latency: p50: ${p50(allNetworkMs)}ms, p90: ${p90(allNetworkMs)}ms, p99: ${p99(allNetworkMs)}ms',
    );

    if (totalItemsTested > 0) {
      print(
        'Mean Kcal Error: ${(sumKcalMape / totalItemsTested).toStringAsFixed(2)}%',
      );
      print(
        'Mean Item F1: ${(sumItemF1 / totalItemsTested).toStringAsFixed(2)}',
      );
      print('Total Hallucinated Items: $hallucinations');
      print('Schema Failures: $schemaFailures');
    }
  }, skip: !const bool.fromEnvironment('RUN_BENCH', defaultValue: false));
}
