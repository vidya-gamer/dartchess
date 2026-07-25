import 'package:benchmark_harness/benchmark_harness.dart';

import '../lib/src/square_set_old.dart' as old_api;
import '../lib/src/square_set.dart' as new_api;

const oldCrowdedBoard = old_api.SquareSet(0x55AA55AA00000000);
const newCrowdedBoard = new_api.SquareSet(0x55AA55AA00000000);

int oldSyncStarChecksum = 0;
int newCustomIteratorChecksum = 0;
int squareListChecksum = 0;
int rawInlineChecksum = 0;

// 1. OLD API: sync* Generator
class SyncStarBenchmark extends BenchmarkBase {
  const SyncStarBenchmark() : super('1. Iteration: Old API (sync*)');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 100; i++) {
      for (final sq in oldCrowdedBoard.squares) {
        total += sq;
      }
    }
    oldSyncStarChecksum += total;
  }
}

// 2. NEW API: Custom Iterator (Our main replacement for sync*)
class CustomIteratorBenchmark extends BenchmarkBase {
  const CustomIteratorBenchmark() : super('2. Iteration: New API (Custom Iterator)');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 100; i++) {
      for (final sq in newCrowdedBoard.squares) {
        total += sq;
      }
    }
    newCustomIteratorChecksum += total;
  }
}

// 3. NEW API: toSquareList()
class ToSquareListBenchmark extends BenchmarkBase {
  const ToSquareListBenchmark() : super('3. Iteration: New API (toSquareList)');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 100; i++) {
      for (final sq in newCrowdedBoard.toSquareList()) {
        total += sq;
      }
    }
    squareListChecksum += total;
  }
}

// 4. ABSOLUTE MAXIMUM: Direct Bitwise Loop
class RawInlineLoopBenchmark extends BenchmarkBase {
  const RawInlineLoopBenchmark() : super('4. Iteration: Raw Bitwise Loop');
  @override
  void run() {
    int total = 0;
    for (int i = 0; i < 100; i++) {
      int bb = newCrowdedBoard.value;
      while (bb != 0) {
        final int sq = _ntz64(bb);
        total += sq;
        bb &= bb - 1; // Direct LSB clearing
      }
    }
    rawInlineChecksum += total;
  }
}

void main() {
  // Verifying Logical Equivalence
  int c1 = 0, c2 = 0, c3 = 0, c4 = 0;

  for (final sq in oldCrowdedBoard.squares) { c1 += sq; }
  for (final sq in newCrowdedBoard.squares) { c2 += sq; }
  for (final sq in newCrowdedBoard.toSquareList()) { c3 += sq; }
  
  int bb = newCrowdedBoard.value;
  while (bb != 0) {
    c4 += _ntz64(bb);
    bb &= bb - 1;
  }

  print('--- Integrity Check ---');
  print('1. Old sync*:          $c1');
  print('2. New Iterator:       $c2');
  print('3. toSquareList():     $c3');
  print('4. Raw Bitwise Loop:   $c4');

  if (c1 != c2 || c2 != c3 || c3 != c4) {
    print('❌ CRITICAL ERROR: Logic mismatch between iteration approaches!');
    return;
  }
  print('✅ LOGICAL PARITY VERIFIED\n');

  print('--- Running Square Iteration Benchmarks ---');
  const SyncStarBenchmark().report();
  const CustomIteratorBenchmark().report();
  const ToSquareListBenchmark().report();
  const RawInlineLoopBenchmark().report();

  // DCE Guard
  print('\n[DCE Guard]: ${oldSyncStarChecksum + newCustomIteratorChecksum + squareListChecksum + rawInlineChecksum}');
}

@pragma('vm:prefer-inline')
int _ntz64(int x) => _ntzLut64[(x & -x) % 131];
const _ntzLut64 = [
  64, 0, 1, -1, 2, 46, -1, -1, 3, 14, 47, 56, -1, 18, -1,
  -1, 4, 43, 15, 35, 48, 38, 57, 23, -1, -1, 19, -1, -1, 51,
  -1, 29, 5, 63, 44, 12, 16, 41, 36, -1, 49, -1, 39, -1, 58,
  60, 24, -1, -1, 62, -1, -1, 20, 26, -1, -1, -1, -1, 52, -1,
  -1, -1, 30, -1, 6, -1, -1, -1, 45, -1, 13, 55, 17, -1, 42,
  34, 37, 22, -1, -1, 50, 28, -1, 11, 40, -1, -1, -1, 59,
  -1, 61, -1, 25, -1, -1, -1, -1, -1, -1, -1, -1, 54, -1,
  33, 21, -1, 27, 10, -1, -1, -1, -1, -1, -1, -1, -1, 53,
  32, -1, 9, -1, -1, -1, -1, 31, 8, -1, -1, 7, -1, -1,
];
