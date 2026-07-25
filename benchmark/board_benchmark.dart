import 'package:benchmark_harness/benchmark_harness.dart';

import '../lib/src/board_old.dart' as old_api;
import '../lib/src/board.dart' as new_api;
import '../lib/src/models.dart';

const List<Square> testSquares = Square.values;

// Setup a realistic test piece (a white knight) to slide across the board
const testPiece = Piece(role: Role.knight, color: Side.white);

// Global accumulators to defeat dead-code elimination (DCE) across all suites
int oldBoardChecksum = 0;
int newBoardChecksum = 0;
int piecesTestChecksum = 0;

// --- 1. OVERALL BOARD OPERATIONS ---

class OldBoardBenchmark extends BenchmarkBase {
  const OldBoardBenchmark() : super('Old Board Code');

  @override
  void exercise() => run();

  @override
  void run() {
    var board = old_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 20; i++) {
      for (final sqA in testSquares) {
        final original = board.pieceAt(sqA);

        board = board.setPieceAt(sqA, testPiece);
        board = board.removePieceAt(sqA);

        if (original != null) {
          board = board.setPieceAt(sqA, original);
        }

        localChecksum += board.pieceAt(sqA).hashCode;
        localChecksum += board.roleAt(sqA).hashCode;
        localChecksum += board.sideAt(sqA).hashCode;

        localChecksum += board.attacksTo(sqA, Side.white).hashCode;
        localChecksum += board.attacksTo(sqA, Side.black).hashCode;
      }
    }
    oldBoardChecksum += localChecksum;
  }
}

class NewBoardBenchmark extends BenchmarkBase {
  const NewBoardBenchmark() : super('New Board Code (Optimized)');

  @override
  void exercise() => run();

  @override
  void run() {
    var board = new_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 20; i++) {
      for (final sqA in testSquares) {
        final original = board.pieceAt(sqA);

        board = board.setPieceAt(sqA, testPiece);
        board = board.removePieceAt(sqA);

        if (original != null) {
          board = board.setPieceAt(sqA, original);
        }

        localChecksum += board.pieceAt(sqA).hashCode;
        localChecksum += board.roleAt(sqA).hashCode;
        localChecksum += board.sideAt(sqA).hashCode;

        localChecksum += board.attacksTo(sqA, Side.white).hashCode;
        localChecksum += board.attacksTo(sqA, Side.black).hashCode;
      }
    }
    newBoardChecksum += localChecksum;
  }
}

// --- 2. KING LOOKUP BENCHMARKS (kingOf) ---

class OldKingOfBenchmark extends BenchmarkBase {
  const OldKingOfBenchmark() : super('Old kingOf (Instantiates Piece)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = old_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 1000; i++) {
      localChecksum += board.kingOf(Side.white).hashCode;
      localChecksum += board.kingOf(Side.black).hashCode;
    }
    oldBoardChecksum += localChecksum;
  }
}

class NewKingOfBenchmark extends BenchmarkBase {
  const NewKingOfBenchmark() : super('New kingOf (Direct Bitwise)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = new_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 1000; i++) {
      localChecksum += board.kingOf(Side.white).hashCode;
      localChecksum += board.kingOf(Side.black).hashCode;
    }
    newBoardChecksum += localChecksum;
  }
}

// --- 3. FEN GENERATION BENCHMARKS ---

class OldFenBenchmark extends BenchmarkBase {
  const OldFenBenchmark() : super('Old fen Generation');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = old_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 200; i++) {
      localChecksum += board.fen.hashCode;
    }
    oldBoardChecksum += localChecksum;
  }
}

class NewFenBenchmark extends BenchmarkBase {
  const NewFenBenchmark() : super('New fen Generation (Optimized Offset)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = new_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 200; i++) {
      localChecksum += board.fen.hashCode;
    }
    newBoardChecksum += localChecksum;
  }
}

// --- 4. ATTACKS-TO ISOLATION BENCHMARKS ---

class OldAttacksToBenchmark extends BenchmarkBase {
  const OldAttacksToBenchmark() : super('Old attacksTo (Chained Methods)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = old_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 100; i++) {
      for (final sq in testSquares) {
        localChecksum += board.attacksTo(sq, Side.white).hashCode;
        localChecksum += board.attacksTo(sq, Side.black).hashCode;
      }
    }
    oldBoardChecksum += localChecksum;
  }
}

class NewAttacksToBenchmark extends BenchmarkBase {
  const NewAttacksToBenchmark() : super('New attacksTo (Direct Operators)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = new_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 100; i++) {
      for (final sq in testSquares) {
        localChecksum += board.attacksTo(sq, Side.white).hashCode;
        localChecksum += board.attacksTo(sq, Side.black).hashCode;
      }
    }
    newBoardChecksum += localChecksum;
  }
}

// --- 5. MATERIAL COUNT BENCHMARKS ---

class OldMaterialCountBenchmark extends BenchmarkBase {
  const OldMaterialCountBenchmark()
      : super('Old materialCount (Map.fromEntries)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = old_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 100; i++) {
      final first = i.isEven ? Side.white : Side.black;
      final second = i.isEven ? Side.black : Side.white;

      localChecksum += board.materialCount(first).hashCode;
      localChecksum += board.materialCount(second).hashCode;
    }
    oldBoardChecksum += localChecksum;
  }
}

class NewMaterialCountBenchmark extends BenchmarkBase {
  const NewMaterialCountBenchmark()
      : super('New materialCount (Direct Bit Counts)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = new_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 100; i++) {
      final first = i.isEven ? Side.white : Side.black;
      final second = i.isEven ? Side.black : Side.white;

      localChecksum += board.materialCount(first).hashCode;
      localChecksum += board.materialCount(second).hashCode;
    }
    newBoardChecksum += localChecksum;
  }
}

// --- 6. THREE-WAY PIECES GETTER BENCHMARKS ---

Iterable<(Square, Piece)> getPiecesSync(new_api.Board board) sync* {
  for (final square in board.occupied.squares) {
    yield (square, board.pieceAt(square)!);
  }
}

Iterable<(Square, Piece)> getPiecesEager(new_api.Board board) {
  final squares = board.occupied.toSquareList();
  return List<(Square, Piece)>.generate(
    squares.length,
    (i) {
      final square = squares[i];
      return (square, board.pieceAt(square)!);
    },
    growable: false,
  );
}

Iterable<(Square, Piece)> getPiecesLazy(new_api.Board board) {
  return board.occupied.squares
      .map((square) => (square, board.pieceAt(square)!));
}

class PiecesSyncBenchmark extends BenchmarkBase {
  const PiecesSyncBenchmark() : super('pieces (1. sync* Generator)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = new_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 100; i++) {
      for (final item in getPiecesSync(board)) {
        localChecksum += item.$1.hashCode ^ item.$2.hashCode;
      }
    }
    piecesTestChecksum += localChecksum;
  }
}

class PiecesEagerBenchmark extends BenchmarkBase {
  const PiecesEagerBenchmark() : super('pieces (2. Eager List.generate)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = new_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 100; i++) {
      for (final item in getPiecesEager(board)) {
        localChecksum += item.$1.hashCode ^ item.$2.hashCode;
      }
    }
    piecesTestChecksum += localChecksum;
  }
}

class PiecesLazyBenchmark extends BenchmarkBase {
  const PiecesLazyBenchmark() : super('pieces (3. Lazy map one-liner)');

  @override
  void exercise() => run();

  @override
  void run() {
    final board = new_api.Board.standard;
    int localChecksum = 0;

    for (int i = 0; i < 100; i++) {
      for (final item in getPiecesLazy(board)) {
        localChecksum += item.$1.hashCode ^ item.$2.hashCode;
      }
    }
    piecesTestChecksum += localChecksum;
  }
}

void main() {
  print('--- Starting Board Benchmark (Warming up JIT Compiler) ---');

  print('\n[Category 1: Overall Board Mutation & Access]');
  const OldBoardBenchmark().report();
  const NewBoardBenchmark().report();

  print('\n[Category 2: kingOf Lookup]');
  const OldKingOfBenchmark().report();
  const NewKingOfBenchmark().report();

  print('\n[Category 3: attacksTo Calculation]');
  const OldAttacksToBenchmark().report();
  const NewAttacksToBenchmark().report();

  print('\n[Category 4: FEN Serialization]');
  const OldFenBenchmark().report();
  const NewFenBenchmark().report();

  print('\n[Category 5: materialCount Evaluation]');
  const OldMaterialCountBenchmark().report();
  const NewMaterialCountBenchmark().report();

  print('\n[Category 6: 3-Way pieces Getter Comparison]');
  const PiecesSyncBenchmark().report();
  const PiecesEagerBenchmark().report();
  const PiecesLazyBenchmark().report();

  // --- INTEGRITY & ANTI-DCE CHECKS ---
  print('\n[Verification]');
  print('Old Board Master Checksum: $oldBoardChecksum');
  print('New Board Master Checksum: $newBoardChecksum');
  print('Pieces Getter Test Checksum: $piecesTestChecksum');

  if (oldBoardChecksum == 0 ||
      newBoardChecksum == 0 ||
      piecesTestChecksum == 0) {
    print(
        'Error: State hashes were not calculated properly (potential Dead Code Elimination).');
  } else {
    print('State verification passed. Checksums generated successfully.');
  }
}
