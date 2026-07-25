import 'package:benchmark_harness/benchmark_harness.dart';
import 'dart:io' as io;
import '../lib/src/models.dart';
import '../lib/src/square_set.dart';
import '../lib/src/setup.dart';
import '../lib/src/position.dart' as new_api;
import '../lib/src/position_old.dart' as old_api;

// Setup FENs
final middlegameSetup = Setup.parseFen('rn1qkb1r/pbp2ppp/1p2p3/3n4/8/2N2NP1/PP1PPPBP/R1BQ1RK1 b kq -');
final endgameSetup = Setup.parseFen('8/2p5/4k3/1p6/8/8/3P4/4K3 w - - 0 1');
final checkmateSetup = Setup.parseFen('7k/6Q1/6K1/8/8/8/8/8 b - - 0 1');
final stalemateSetup = Setup.parseFen('7k/5Q2/7K/8/8/8/8/8 b - - 0 1');

// --- TEST SUITE POSITIONS ---
final List<new_api.Position> newPositions = [
  new_api.Chess.initial,
  new_api.Chess.fromSetup(middlegameSetup),
  new_api.Chess.fromSetup(endgameSetup),
  new_api.Chess.fromSetup(checkmateSetup),
  new_api.Chess.fromSetup(stalemateSetup),
  new_api.Horde.initial,
];

final List<old_api.Position> oldPositions = [
  old_api.Chess.initial,
  old_api.Chess.fromSetup(middlegameSetup),
  old_api.Chess.fromSetup(endgameSetup),
  old_api.Chess.fromSetup(checkmateSetup),
  old_api.Chess.fromSetup(stalemateSetup),
  old_api.Horde.initial,
];
// Dead-code elimination preventers
int oldHarnessChecksum = 0;
int newHarnessChecksum = 0;

// --- 1. LEGAL MOVES BENCHMARK ---

class OldLegalMovesBenchmark extends BenchmarkBase {
  const OldLegalMovesBenchmark() : super('Old legalMoves (Map generation)');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (final pos in oldPositions) {
      local += pos.legalMoves.hashCode;
    }
    oldHarnessChecksum += local;
  }
}

class NewLegalMovesBenchmark extends BenchmarkBase {
  const NewLegalMovesBenchmark()
      : super('New legalMoves (Optimized bit-scan)');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (final pos in newPositions) {
      local += pos.legalMoves.hashCode;
    }
    newHarnessChecksum += local;
  }
}

// --- 2. HAS SOME LEGAL MOVES BENCHMARK ---

class OldHasSomeLegalMovesBenchmark extends BenchmarkBase {
  const OldHasSomeLegalMovesBenchmark()
      : super('Old hasSomeLegalMoves (Checkmate/Stalemate check)');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (final pos in oldPositions) {
      local += pos.hasSomeLegalMoves.hashCode;
    }
    oldHarnessChecksum += local;
  }
}

class NewHasSomeLegalMovesBenchmark extends BenchmarkBase {
  const NewHasSomeLegalMovesBenchmark()
      : super('New hasSomeLegalMoves (Optimized early exit)');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (final pos in newPositions) {
      local += pos.hasSomeLegalMoves.hashCode;
    }
    newHarnessChecksum += local;
  }
}

// --- EXACT ONE-PASS VERIFICATION ---

void _assertEquivalentMaps(
  Map<Square, SquareSet> oldMap,
  Map<Square, SquareSet> newMap,
  String positionFen,
) {
  if (oldMap.length != newMap.length) {
    throw StateError('''
❌ KEY COUNT MISMATCH!
Position FEN: $positionFen
Expected Key Count: ${oldMap.length}
Received Key Count: ${newMap.length}
''');
  }

  for (final key in oldMap.keys) {
    if (!newMap.containsKey(key)) {
      throw StateError('''
❌ MISSING SQUARE KEY IN NEW API!
Position FEN: $positionFen
Missing Square Key: $key
''');
    }

    final oldSet = oldMap[key]!.value;
    final newSet = newMap[key]!.value;

    if (oldSet != newSet) {
      throw StateError('''
❌ DIVERGENT LEGAL MOVES DETECTED!
Position FEN: $positionFen
Square: $key
Expected Set (Old API): $oldSet (${oldMap[key]})
Received Set (New API): $newSet (${newMap[key]})
''');
    }
  }
}

void executeAuthoritativeVerification() {
  for (int i = 0; i < oldPositions.length; i++) {
    final oldPos = oldPositions[i];
    final newPos = newPositions[i];
    final fen = newPos.fen;

    // 1. Verify hasSomeLegalMoves equality
    if (oldPos.hasSomeLegalMoves != newPos.hasSomeLegalMoves) {
      throw StateError('''
❌ HAS SOME LEGAL MOVES MISMATCH!
Position FEN: $fen
Old API: ${oldPos.hasSomeLegalMoves}
New API: ${newPos.hasSomeLegalMoves}
''');
    }

    // 2. Verify complete legalMoves map equality
    _assertEquivalentMaps(oldPos.legalMoves, newPos.legalMoves, fen);
  }
}

void main() {
  print('--- Checking Position Logic Integrity ---');
  try {
    executeAuthoritativeVerification();
    print('✅ VERIFICATION PASSED: Position logic is 100% equivalent.\n');
  } catch (e) {
    print(e);
    io.exit(1);
  }

  print('--- Running Position Isolation Benchmarks ---');

  print('\n[Category 1: Full Legal Move Generation]');
  const OldLegalMovesBenchmark().report();
  const NewLegalMovesBenchmark().report();

  print('\n[Category 2: Early-Exit Stalemate/Checkmate Check]');
  const OldHasSomeLegalMovesBenchmark().report();
  const NewHasSomeLegalMovesBenchmark().report();

  // Ensure VM optimization guard rails stay true
  if (oldHarnessChecksum == 0 || newHarnessChecksum == 0) {
    print('\nError: Benchmark traces were dropped.');
  }
}
