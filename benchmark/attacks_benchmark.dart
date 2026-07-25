import 'package:benchmark_harness/benchmark_harness.dart';
import 'dart:io' as io;
import 'dart:math';
import '../lib/src/attacks_old.dart' as old_api;
import '../lib/src/attacks.dart' as new_api;
import '../lib/src/models.dart';
import '../lib/src/square_set.dart';

const List<Square> testSquares = Square.values;

// Expanded occupancy layouts to thoroughly stress test hyperbola ray masking
final List<SquareSet> testOccupancies = [
  SquareSet.empty,
  SquareSet.full,
  // Typical pawn structures / starting profiles
  SquareSet.fromRank(Rank.second) | SquareSet.fromRank(Rank.seventh),
  // Blockers scattered across diagonals and center lines
  SquareSet.corners |
      SquareSet.center |
      SquareSet.fromFile(File.d) |
      SquareSet.fromFile(File.e),
  // Sparse layout mimicking an endgame
  SquareSet.fromSquare(Square.e1) |
      SquareSet.fromSquare(Square.e8) |
      SquareSet.fromSquare(Square.c4),
];

// Sample pieces for testing the polymorphic router
final List<Piece> testPieces = [
  Piece(color: Side.white, role: Role.pawn),
  Piece(color: Side.black, role: Role.knight),
  Piece(color: Side.white, role: Role.bishop),
  Piece(color: Side.black, role: Role.rook),
  Piece(color: Side.white, role: Role.queen),
  Piece(color: Side.black, role: Role.king),
];

// Dead-code elimination preventers
int oldHarnessChecksum = 0;
int newHarnessChecksum = 0;

/// Generates an expanded set of occupancies combining static edge-cases
/// with seeded pseudo-random bitboards for dynamic verification.
List<SquareSet> _generateVerificationOccupancies() {
  final rng = Random(42); // Seeded for deterministic execution
  final list = List<SquareSet>.from(testOccupancies); // Includes base 5 cases

  for (int i = 0; i < 200; i++) {
    // Combine two 32-bit random integers into a single 64-bit int mask
    final high = rng.nextInt(1 << 32);
    final low = rng.nextInt(1 << 32);
    final rawBits = (high << 32) | low;

    // Pass the 64-bit int directly to SquareSet constructor
    list.add(SquareSet(rawBits));
  }
  return list;
}

// --- 1. LEAPING PIECES (LOOKUPS) ---

class OldLeapersBenchmark extends BenchmarkBase {
  const OldLeapersBenchmark() : super('Old Leapers (King/Knight/Pawn)');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (int i = 0; i < 500; i++) {
      for (final sq in testSquares) {
        local += old_api.kingAttacks(sq).hashCode;
        local += old_api.knightAttacks(sq).hashCode;
        local += old_api.pawnAttacks(Side.white, sq).hashCode;
        local += old_api.pawnAttacks(Side.black, sq).hashCode;
      }
    }
    oldHarnessChecksum += local;
  }
}

class NewLeapersBenchmark extends BenchmarkBase {
  const NewLeapersBenchmark()
      : super('New Leapers (King/Knight/Pawn) [Optimized]');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (int i = 0; i < 500; i++) {
      for (final sq in testSquares) {
        local += new_api.kingAttacks(sq).hashCode;
        local += new_api.knightAttacks(sq).hashCode;
        local += new_api.pawnAttacks(Side.white, sq).hashCode;
        local += new_api.pawnAttacks(Side.black, sq).hashCode;
      }
    }
    newHarnessChecksum += local;
  }
}

// --- 2. SLIDING PIECES (HYPERBOLA MATH) ---

class OldSlidersBenchmark extends BenchmarkBase {
  const OldSlidersBenchmark() : super('Old Sliders (Bishop/Rook/Queen)');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (final sq in testSquares) {
      for (final occ in testOccupancies) {
        local += old_api.bishopAttacks(sq, occ).hashCode;
        local += old_api.rookAttacks(sq, occ).hashCode;
        local += old_api.queenAttacks(sq, occ).hashCode;
      }
    }
    oldHarnessChecksum += local;
  }
}

class NewSlidersBenchmark extends BenchmarkBase {
  const NewSlidersBenchmark()
      : super('New Sliders (Bishop/Rook/Queen) [Optimized]');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (final sq in testSquares) {
      for (final occ in testOccupancies) {
        local += new_api.bishopAttacks(sq, occ).hashCode;
        local += new_api.rookAttacks(sq, occ).hashCode;
        local += new_api.queenAttacks(sq, occ).hashCode;
      }
    }
    newHarnessChecksum += local;
  }
}

// --- 3. GEOMETRY & TRAVERSALS (BETWEEN / RAY) ---

class OldGeometryBenchmark extends BenchmarkBase {
  const OldGeometryBenchmark() : super('Old Geometry (Between/Ray)');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (int i = 0; i < 100; i++) {
      for (final sqA in testSquares) {
        for (final sqB in testSquares) {
          local += old_api.between(sqA, sqB).hashCode;
          local += old_api.ray(sqA, sqB).hashCode;
        }
      }
    }
    oldHarnessChecksum += local;
  }
}

class NewGeometryBenchmark extends BenchmarkBase {
  const NewGeometryBenchmark()
      : super('New Geometry (Between/Ray) [Optimized]');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (int i = 0; i < 100; i++) {
      for (final sqA in testSquares) {
        for (final sqB in testSquares) {
          local += new_api.between(sqA, sqB).hashCode;
          local += new_api.ray(sqA, sqB).hashCode;
        }
      }
    }
    newHarnessChecksum += local;
  }
}

// --- 4. DYNAMIC ROUTER DISPATCH ---

class OldRouterBenchmark extends BenchmarkBase {
  const OldRouterBenchmark() : super('Old Dynamic attacks() Router');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (int i = 0; i < 200; i++) {
      for (final sq in testSquares) {
        for (final occ in testOccupancies) {
          for (final piece in testPieces) {
            local += old_api.attacks(piece, sq, occ).hashCode;
          }
        }
      }
    }
    oldHarnessChecksum += local;
  }
}

class NewRouterBenchmark extends BenchmarkBase {
  const NewRouterBenchmark()
      : super('New Dynamic attacks() Router [Optimized]');
  @override
  void exercise() => run();
  @override
  void run() {
    int local = 0;
    for (int i = 0; i < 200; i++) {
      for (final sq in testSquares) {
        for (final occ in testOccupancies) {
          for (final piece in testPieces) {
            local += new_api.attacks(piece, sq, occ).hashCode;
          }
        }
      }
    }
    newHarnessChecksum += local;
  }
}

// --- EXACT ONE-PASS VERIFICATION ---

void _assertEquivalent(
  dynamic oldVal,
  dynamic newVal,
  String operation,
  Map<String, dynamic> context,
) {
  // Extract canonical primitive values (e.g., the underlying 64-bit integer)
  final oldCanonical = _toCanonical(oldVal);
  final newCanonical = _toCanonical(newVal);

  if (oldCanonical != newCanonical) {
    throw StateError('''
❌ DIVERGENT BEHAVIOR DETECTED!
Operation:          $operation
Context:            $context
Expected (Old API): $oldVal ($oldCanonical)
Received (New API): $newVal ($newCanonical)
''');
  }
}

/// Helper to reduce domain models/extension types to raw primitives for comparison.
dynamic _toCanonical(dynamic val) {
  if (val == null) return null;
  if (val is int || val is String || val is bool) return val;

  // Adjust these property accessors based on your actual SquareSet / Bitboard API
  // e.g., if your set uses .value, .bits, or .toSet()
  try {
    return (val as dynamic).value;
  } catch (_) {
    return val.toString();
  }
}

void executeAuthoritativeVerification() {
  // Use the expanded set for verification only
  final verificationOccupancies = _generateVerificationOccupancies();

  for (final sqA in testSquares) {
    // 1. Leapers
    _assertEquivalent(old_api.kingAttacks(sqA), new_api.kingAttacks(sqA),
        'kingAttacks', {'sqA': sqA});
    _assertEquivalent(old_api.knightAttacks(sqA), new_api.knightAttacks(sqA),
        'knightAttacks', {'sqA': sqA});
    _assertEquivalent(
        old_api.pawnAttacks(Side.white, sqA),
        new_api.pawnAttacks(Side.white, sqA),
        'pawnAttacks (White)',
        {'sqA': sqA});
    _assertEquivalent(
        old_api.pawnAttacks(Side.black, sqA),
        new_api.pawnAttacks(Side.black, sqA),
        'pawnAttacks (Black)',
        {'sqA': sqA});

    // 2. Sliders & Routing (Now iterating over 205 occupancies instead of 5!)
    for (final occ in verificationOccupancies) {
      _assertEquivalent(
          old_api.bishopAttacks(sqA, occ),
          new_api.bishopAttacks(sqA, occ),
          'bishopAttacks',
          {'sqA': sqA, 'occupancy': occ});
      _assertEquivalent(
          old_api.rookAttacks(sqA, occ),
          new_api.rookAttacks(sqA, occ),
          'rookAttacks',
          {'sqA': sqA, 'occupancy': occ});
      _assertEquivalent(
          old_api.queenAttacks(sqA, occ),
          new_api.queenAttacks(sqA, occ),
          'queenAttacks',
          {'sqA': sqA, 'occupancy': occ});

      for (final piece in testPieces) {
        _assertEquivalent(
            old_api.attacks(piece, sqA, occ),
            new_api.attacks(piece, sqA, occ),
            'attacks',
            {'piece': piece, 'sqA': sqA, 'occupancy': occ});
      }
    }

    // 3. Geometry
    for (final sqB in testSquares) {
      _assertEquivalent(old_api.between(sqA, sqB), new_api.between(sqA, sqB),
          'between', {'sqA': sqA, 'sqB': sqB});
      _assertEquivalent(old_api.ray(sqA, sqB), new_api.ray(sqA, sqB), 'ray',
          {'sqA': sqA, 'sqB': sqB});
    }
  }
}

void main() {
  print('--- Checking Logic Integrity ---');
  try {
    executeAuthoritativeVerification();
    print('✅ VERIFICATION PASSED: Logic maps are 100% equivalent.\n');
  } catch (e) {
    print(e);
    io.exit(1);
  }

  print('--- Running Isolation Benchmarks ---');

  print('\n[Category 1: Leapers]');
  const OldLeapersBenchmark().report();
  const NewLeapersBenchmark().report();

  print('\n[Category 2: Sliding Attacks]');
  const OldSlidersBenchmark().report();
  const NewSlidersBenchmark().report();

  print('\n[Category 3: Ray/Between Geometry]');
  const OldGeometryBenchmark().report();
  const NewGeometryBenchmark().report();

  print('\n[Category 4: Attack Router Dispatch]');
  const OldRouterBenchmark().report();
  const NewRouterBenchmark().report();

  // Ensure VM optimization guard rails stay true
  if (oldHarnessChecksum == 0 || newHarnessChecksum == 0) {
    print('\nError: Benchmark traces were dropped.');
  }
}
