import 'package:benchmark_harness/benchmark_harness.dart';

import '../lib/src/models_old.dart' as old_api;
import '../lib/src/models.dart' as new_api;

const List<new_api.Square> testSquaresNew = new_api.Square.values;
const List<old_api.Square> testSquaresOld = old_api.Square.values;

const List<String> algebraicNames = [
  'a1', 'b1', 'c1', 'd1', 'e1', 'f1', 'g1', 'h1',
  'a2', 'b2', 'c2', 'd2', 'e2', 'f2', 'g2', 'h2',
  'a3', 'b3', 'c3', 'd3', 'e3', 'f3', 'g3', 'h3',
  'a4', 'b4', 'c4', 'd4', 'e4', 'f4', 'g4', 'h4',
  'a5', 'b5', 'c5', 'd5', 'e5', 'f5', 'g5', 'h5',
  'a6', 'b6', 'c6', 'd6', 'e6', 'f6', 'g6', 'h6',
  'a7', 'b7', 'c7', 'd7', 'e7', 'f7', 'g7', 'h7',
  'a8', 'b8', 'c8', 'd8', 'e8', 'f8', 'g8', 'h8'
];

const List<String> testUciMoves = [
  'e2e4', 'g1f3', 'b7b8q', 'e7e8n', 'Q@f7', 'P@c3', 'a7a8r', 'd7d5'
];

const List<String> pieceChars = ['P', 'n', 'B', 'r', 'Q', 'k', 'p', 'N'];

int oldModelsChecksum = 0;
int newModelsChecksum = 0;

// --- SQUARE & COORDINATE BENCHMARKS ---

class OldSquareBenchmark extends BenchmarkBase {
  const OldSquareBenchmark() : super('Old Square Coordinate Operations');

  @override
  void exercise() => run();

  @override
  void run() {
    int localChecksum = 0;

    for (int i = 0; i < 500; i++) {
      for (final name in algebraicNames) {
        final sq1 = old_api.Square.fromName(name);
        final sq2 = old_api.Square.parse(name);
        localChecksum += sq1.hashCode + (sq2?.hashCode ?? 0);
      }
    }

    for (final sq in testSquaresOld) {
      localChecksum += sq.file.hashCode;
      localChecksum += sq.rank.hashCode;
      localChecksum += sq.name.hashCode;
      localChecksum += sq.offset(1).hashCode;
      localChecksum += sq.xor(old_api.Square.h8).hashCode; // Added XOR
      localChecksum += old_api.Square.fromCoords(sq.file, sq.rank).hashCode; // Added fromCoords
    }

    oldModelsChecksum += localChecksum;
  }
}

class NewSquareBenchmark extends BenchmarkBase {
  const NewSquareBenchmark() : super('New Square Coordinate Operations (Optimized)');

  @override
  void exercise() => run();

  @override
  void run() {
    int localChecksum = 0;

    for (int i = 0; i < 500; i++) {
      for (final name in algebraicNames) {
        final sq1 = new_api.Square.fromName(name);
        final sq2 = new_api.Square.parse(name);
        localChecksum += sq1.hashCode + (sq2?.hashCode ?? 0);
      }
    }

    for (final sq in testSquaresNew) {
      localChecksum += sq.file.hashCode;
      localChecksum += sq.rank.hashCode;
      localChecksum += sq.name.hashCode;
      localChecksum += sq.offset(1).hashCode;
      localChecksum += sq.xor(new_api.Square.h8).hashCode; // Added XOR
      localChecksum += new_api.Square.fromCoords(sq.file, sq.rank).hashCode; // Added fromCoords
    }

    newModelsChecksum += localChecksum;
  }
}

// --- PIECE PERFORMANCE BENCHMARKS ---

class OldPieceBenchmark extends BenchmarkBase {
  const OldPieceBenchmark() : super('Old Piece API');

  @override
  void exercise() => run();

  @override
  void run() {
    int localChecksum = 0;

    for (int i = 0; i < 1000; i++) {
      for (final side in old_api.Side.values) {
        for (final role in old_api.Role.values) {
          final piece = old_api.Piece(color: side, role: role, promoted: i.isEven);

          localChecksum += piece.color.hashCode;
          localChecksum += piece.role.hashCode;
          localChecksum += piece.promoted.hashCode;
          localChecksum += piece.kind.hashCode;
          localChecksum += piece.fenChar.hashCode; // Added FEN char lookup
          localChecksum += piece.toString().hashCode;
          
          // Added copyWith
          final copied = piece.copyWith(promoted: !piece.promoted);
          localChecksum += copied.hashCode;
        }
      }

      // Added Piece.fromChar parsing
      for (final ch in pieceChars) {
        localChecksum += (old_api.Piece.fromChar(ch)?.hashCode ?? 0);
      }
    }

    oldModelsChecksum += localChecksum;
  }
}

class NewPieceBenchmark extends BenchmarkBase {
  const NewPieceBenchmark() : super('New Piece API (Zero-Allocation Bitmask)');

  @override
  void exercise() => run();

  @override
  void run() {
    int localChecksum = 0;

    for (int i = 0; i < 1000; i++) {
      for (final side in new_api.Side.values) {
        for (final role in new_api.Role.values) {
          final piece = new_api.Piece(color: side, role: role, promoted: i.isEven);

          localChecksum += piece.color.hashCode;
          localChecksum += piece.role.hashCode;
          localChecksum += piece.promoted.hashCode;
          localChecksum += piece.kind.hashCode;
          localChecksum += piece.fenChar.hashCode; // Tested new static lookup table
          localChecksum += piece.displayString.hashCode;

          // Added copyWith
          final copied = piece.copyWith(promoted: !piece.promoted);
          localChecksum += copied.hashCode;
        }
      }

      // Added Piece.fromChar parsing
      for (final ch in pieceChars) {
        localChecksum += (new_api.Piece.fromChar(ch)?.hashCode ?? 0);
      }
    }

    newModelsChecksum += localChecksum;
  }
}

// --- MOVE PARSING & GENERATION BENCHMARKS ---

class OldMoveParsingBenchmark extends BenchmarkBase {
  const OldMoveParsingBenchmark() : super('Old Move Parsing & UCI Generation');

  @override
  void exercise() => run();

  @override
  void run() {
    int localChecksum = 0;

    for (int i = 0; i < 1000; i++) {
      for (final uci in testUciMoves) {
        final move = old_api.Move.parse(uci);
        if (move != null) {
          localChecksum += move.hashCode;
          localChecksum += move.uci.hashCode; // Added UCI string output test
        }
      }
    }

    oldModelsChecksum += localChecksum;
  }
}

class NewMoveParsingBenchmark extends BenchmarkBase {
  const NewMoveParsingBenchmark() : super('New Move Parsing & UCI Generation (Optimized)');

  @override
  void exercise() => run();

  @override
  void run() {
    int localChecksum = 0;

    for (int i = 0; i < 1000; i++) {
      for (final uci in testUciMoves) {
        final move = new_api.Move.parse(uci);
        if (move != null) {
          localChecksum += move.hashCode;
          localChecksum += move.uci.hashCode; // Added UCI string output test
        }
      }
    }

    newModelsChecksum += localChecksum;
  }
}

void main() {
  print('--- Starting Comprehensive Models Benchmark ---');

  print('\n=== Evaluating Piece Allocations vs Bitmasks ===');
  const OldPieceBenchmark().report();
  const NewPieceBenchmark().report();

  print('\n=== Evaluating Square Coordinate Operations ===');
  const OldSquareBenchmark().report();
  const NewSquareBenchmark().report();

  print('\n=== Evaluating Move String Parsers & Generators ===');
  const OldMoveParsingBenchmark().report();
  const NewMoveParsingBenchmark().report();

  print('\n[Verification]');
  print('Old Models Checksum: $oldModelsChecksum');
  print('New Models Checksum: $newModelsChecksum');

  if (oldModelsChecksum == 0 || newModelsChecksum == 0) {
    print('Error: State hashes were not calculated properly (potential Dead Code Elimination).');
  } else {
    print('State verification passed. Checksums generated successfully.');
  }
}
