import 'package:benchmark_harness/benchmark_harness.dart';
import 'dart:io' as io;
import '../lib/src/models.dart';
import '../lib/src/square_set.dart';
import '../lib/src/setup.dart';
import '../lib/src/position.dart' as new_api;
import '../lib/src/position_old.dart' as old_api;

// --- TEST SCENARIOS ---
final scenarios = <String, String>{
  'Initial Position': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  'Middlegame (Complex)': 'rn1qkb1r/pbp2ppp/1p2p3/3n4/8/2N2NP1/PP1PPPBP/R1BQ1RK1 b kq -',
  'Endgame (Pawn)': '8/2p5/4k3/1p6/8/8/3P4/4K3 w - - 0 1',
  'Checkmate (Terminal)': '7k/6Q1/6K1/8/8/8/8/8 b - - 0 1',
  'Stalemate (Terminal)': '7k/5Q2/7K/8/8/8/8/8 b - - 0 1',
  'Heavy Pins Stress': 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
  'Double Check Escape': 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQ1RK1 b kq - 0 1',
};

// Map setups to typed position lists
final Map<String, new_api.Position> newTestPositions = {
  for (final e in scenarios.entries) e.key: new_api.Chess.fromSetup(Setup.parseFen(e.value)),
  'Horde Variant': new_api.Horde.initial,
};

final Map<String, old_api.Position> oldTestPositions = {
  for (final e in scenarios.entries) e.key: old_api.Chess.fromSetup(Setup.parseFen(e.value)),
  'Horde Variant': old_api.Horde.initial,
};

int oldChecksum = 0;
int newChecksum = 0;

// Benchmark class runner helper
double runBenchmark(void Function() action) {
  final stopwatch = Stopwatch()..start();
  int iterations = 0;
  
  // Benchmark for 200ms per run for high precision
  while (stopwatch.elapsedMilliseconds < 200) {
    action();
    iterations++;
  }
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds / iterations;
}

void printComparison(String label, double newMicros, double oldMicros) {
  final diffPct = ((oldMicros - newMicros) / oldMicros) * 100;
  final symbol = diffPct >= 0 ? '🚀 FASTER' : '⚠️ SLOWER';
  final pctFormatted = diffPct.abs().toStringAsFixed(1);
  
  print(
    '  ${label.padRight(24)} | New: ${newMicros.toStringAsFixed(3).padLeft(7)} µs | '
    'Old: ${oldMicros.toStringAsFixed(3).padLeft(7)} µs | '
    '[$pctFormatted% $symbol]',
  );
}

void main() {
  print('--- Warming up JIT Optimizations ---');
  for (int i = 0; i < 5000; i++) {
    for (final pos in newTestPositions.values) {
      newChecksum += pos.legalMoves.length;
      if (pos.hasSomeLegalMoves) newChecksum++;
    }
    for (final pos in oldTestPositions.values) {
      oldChecksum += pos.legalMoves.length;
      if (pos.hasSomeLegalMoves) oldChecksum++;
    }
  }

  print('\n===============================================================');
  print('          CATEGORY 1: FULL LEGAL MOVE GENERATION (legalMoves)');
  print('===============================================================');

  // Aggregated Suite Benchmark
  final newAgg = runBenchmark(() {
    for (final pos in newTestPositions.values) {
      newChecksum += pos.legalMoves.length;
    }
  });
  final oldAgg = runBenchmark(() {
    for (final pos in oldTestPositions.values) {
      oldChecksum += pos.legalMoves.length;
    }
  });
  printComparison('FULL SUITE ALL POSITIONS', newAgg, oldAgg);
  print('-' * 63);

  // Per-position breakdown
  for (final key in newTestPositions.keys) {
    final newPos = newTestPositions[key]!;
    final oldPos = oldTestPositions[key]!;

    final nTime = runBenchmark(() => newChecksum += newPos.legalMoves.length);
    final oTime = runBenchmark(() => oldChecksum += oldPos.legalMoves.length);

    printComparison(key, nTime, oTime);
  }

  print('\n===============================================================');
  print('      CATEGORY 2: EARLY EXIT CHECKMATE/STALEMATE (hasSomeLegalMoves)');
  print('===============================================================');

  final newAggEarly = runBenchmark(() {
    for (final pos in newTestPositions.values) {
      if (pos.hasSomeLegalMoves) newChecksum++;
    }
  });
  final oldAggEarly = runBenchmark(() {
    for (final pos in oldTestPositions.values) {
      if (pos.hasSomeLegalMoves) oldChecksum++;
    }
  });
  printComparison('FULL SUITE ALL POSITIONS', newAggEarly, oldAggEarly);
  print('-' * 63);

  for (final key in newTestPositions.keys) {
    final newPos = newTestPositions[key]!;
    final oldPos = oldTestPositions[key]!;

    final nTime = runBenchmark(() {
      if (newPos.hasSomeLegalMoves) newChecksum++;
    });
    final oTime = runBenchmark(() {
      if (oldPos.hasSomeLegalMoves) oldChecksum++;
    });

    printComparison(key, nTime, oTime);
  }

  if (oldChecksum == 0 || newChecksum == 0) {
    print('Guard check failed.');
  }
}
