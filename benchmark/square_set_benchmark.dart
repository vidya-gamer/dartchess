import 'package:benchmark_harness/benchmark_harness.dart';

import '../lib/src/square_set_old.dart' as old_api;
import '../lib/src/square_set.dart' as new_api;

const oldCrowdedBoard = old_api.SquareSet(0x55AA55AA00000000);
const newCrowdedBoard = new_api.SquareSet(0x55AA55AA00000000);

const oldSparseBoard = old_api.SquareSet(0x0000001818000000);
const newSparseBoard = new_api.SquareSet(0x0000001818000000);

int oldIterationChecksum = 0;
int newIterationChecksum = 0;
int inlineIterationChecksum = 0;
int primitiveOldChecksum = 0;
int primitiveNewChecksum = 0;

// ==========================================
// 1. ITERATOR SHOWDOWN
// ==========================================

class SyncStarIteratorBenchmark extends BenchmarkBase {
  const SyncStarIteratorBenchmark() : super('Iterator: Old API (sync*)');
  @override
  void run() {
    int localChecksum = 0;
    for (int i = 0; i < 100; i++) {
      for (final sq in oldCrowdedBoard.squares) {
        localChecksum += sq;
      }
    }
    oldIterationChecksum += localChecksum;
  }
}

class ToSquareListBenchmark extends BenchmarkBase {
  const ToSquareListBenchmark() : super('Iterator: New API (toSquareList)');
  @override
  void run() {
    int localChecksum = 0;
    for (int i = 0; i < 100; i++) {
      for (final sq in newCrowdedBoard.toSquareList()) {
        localChecksum += sq;
      }
    }
    newIterationChecksum += localChecksum;
  }
}

class RawInlineLoopBenchmark extends BenchmarkBase {
  const RawInlineLoopBenchmark()
      : super('Iterator: The Absolute Win (Raw Inline Loop)');

  @override
  void run() {
    int localChecksum = 0;
    for (int i = 0; i < 100; i++) {
      int bb = newCrowdedBoard.value;
      while (bb != 0) {
        // Fast 1-cycle LSB index via De Bruijn lookup
        final int lsb = bb & -bb;
        final int sq =
            new_api.deBruijnTable[(lsb * new_api.deBruijn64) >>> 58];
        localChecksum += sq;

        // Clear LSB instantly
        bb &= bb - 1;
      }
    }
    inlineIterationChecksum += localChecksum;
  }
}

// ==========================================
// 2. PRIMITIVES & GEOMETRY
// ==========================================

class OldPopCountBenchmark extends BenchmarkBase {
  const OldPopCountBenchmark()
      : super('Primitive: Population Count [Old API]');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 1000; i++) {
      total += oldCrowdedBoard.size;
      total += oldSparseBoard.size;
    }
    primitiveOldChecksum += total;
  }
}

class NewPopCountBenchmark extends BenchmarkBase {
  const NewPopCountBenchmark()
      : super('Primitive: Population Count [New API Optimized]');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 1000; i++) {
      total += newCrowdedBoard.size;
      total += newSparseBoard.size;
    }
    primitiveNewChecksum += total;
  }
}

class OldBitScanBenchmark extends BenchmarkBase {
  const OldBitScanBenchmark() : super('Primitive: Bit Scans [Old API]');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 1000; i++) {
      final f = oldCrowdedBoard.first;
      final l = oldCrowdedBoard.last;
      if (f != null) total += f;
      if (l != null) total += l;
    }
    primitiveOldChecksum += total;
  }
}

class NewBitScanBenchmark extends BenchmarkBase {
  const NewBitScanBenchmark()
      : super('Primitive: Bit Scans [New API Optimized]');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 1000; i++) {
      final f = newCrowdedBoard.first;
      final l = newCrowdedBoard.last;
      if (f != null) total += f;
      if (l != null) total += l;
    }
    primitiveNewChecksum += total;
  }
}

class OldFlipVerticalBenchmark extends BenchmarkBase {
  const OldFlipVerticalBenchmark() : super('Geometry: Flip Vertical [Old API]');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 1000; i++) {
      total += oldCrowdedBoard.flipVertical().value & 0xFF;
    }
    primitiveOldChecksum += total;
  }
}

class NewFlipVerticalBenchmark extends BenchmarkBase {
  const NewFlipVerticalBenchmark()
      : super('Geometry: Flip Vertical [New API Optimized]');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 1000; i++) {
      total += newCrowdedBoard.flipVertical().value & 0xFF;
    }
    primitiveNewChecksum += total;
  }
}

class OldMirrorHorizontalBenchmark extends BenchmarkBase {
  const OldMirrorHorizontalBenchmark()
      : super('Geometry: Mirror Horizontal [Old API]');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 1000; i++) {
      total += oldCrowdedBoard.mirrorHorizontal().value & 0xFF;
    }
    primitiveOldChecksum += total;
  }
}

class NewMirrorHorizontalBenchmark extends BenchmarkBase {
  const NewMirrorHorizontalBenchmark()
      : super('Geometry: Mirror Horizontal [New API Optimized]');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 1000; i++) {
      total += newCrowdedBoard.mirrorHorizontal().value & 0xFF;
    }
    primitiveNewChecksum += total;
  }
}

class OldSetAlgebraBenchmark extends BenchmarkBase {
  const OldSetAlgebraBenchmark() : super('Math: Set Algebra [Old API]');
  @override
  void run() {
    int total = 0;
    final other = oldSparseBoard;
    for (int i = 0; i < 1000; i++) {
      final combined = (oldCrowdedBoard & other) | (oldCrowdedBoard ^ other);
      final rayBorrow = oldCrowdedBoard - other;
      total += (combined.value & 0xFF) + (rayBorrow.value & 0xFF);
    }
    primitiveOldChecksum += total;
  }
}

class NewSetAlgebraBenchmark extends BenchmarkBase {
  const NewSetAlgebraBenchmark()
      : super('Math: Set Algebra [New API Optimized]');
  @override
  void run() {
    int total = 0;
    final other = newSparseBoard;
    for (int i = 0; i < 1000; i++) {
      final combined = (newCrowdedBoard & other) | (newCrowdedBoard ^ other);
      final rayBorrow = newCrowdedBoard - other;
      total += (combined.value & 0xFF) + (rayBorrow.value & 0xFF);
    }
    primitiveNewChecksum += total;
  }
}

void main() {
  int oldCheck = 0;
  int newCheck = 0;
  int inlineCheck = 0;

  for (final sq in oldCrowdedBoard.squares) {
    oldCheck += sq;
  }
  for (final sq in newCrowdedBoard.toSquareList()) {
    newCheck += sq;
  }

  int bb = newCrowdedBoard.value;
  while (bb != 0) {
    final int lsb = bb & -bb;
    final int sq = new_api.deBruijnTable[(lsb * new_api.deBruijn64) >>> 58];
    inlineCheck += sq;
    bb &= bb - 1;
  }

  print('--- Integrity Check ---');
  print('Old Pass Total:    $oldCheck');
  print('New Pass Total:    $newCheck');
  print('Inline Pass Total: $inlineCheck');

  if (oldCheck != newCheck || newCheck != inlineCheck) {
    print('❌ CRITICAL ERROR: Iterator logic mismatch detected!');
    return;
  }
  print(
      '✅ LOGICAL PARITY VERIFIED: All three strategies read identical square indices.\n');

  print('--- Starting Granular Performance Analysis ---');
  const SyncStarIteratorBenchmark().report();
  const ToSquareListBenchmark().report();
  const RawInlineLoopBenchmark().report();

  print('\n--- Primitives Performance Comparison ---');
  const OldPopCountBenchmark().report();
  const NewPopCountBenchmark().report();
  print('---');
  const OldBitScanBenchmark().report();
  const NewBitScanBenchmark().report();

  print('\n--- Structural Geometry Performance Comparison ---');
  const OldFlipVerticalBenchmark().report();
  const NewFlipVerticalBenchmark().report();
  print('---');
  const OldMirrorHorizontalBenchmark().report();
  const NewMirrorHorizontalBenchmark().report();
  print('---');
  const OldSetAlgebraBenchmark().report();
  const NewSetAlgebraBenchmark().report();

  print('\n[DCE Guard Verification - Ignore Values]: '
      '${oldIterationChecksum + newIterationChecksum + inlineIterationChecksum + primitiveOldChecksum + primitiveNewChecksum}');
}
