import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dartchess/dartchess.dart';

/// Base class to handle reset and logging of Board calls
abstract class PerftBenchmark extends BenchmarkBase {
  PerftBenchmark(String name) : super(name);

  void resetCounters() {
    Board.pieceAtCalls = 0;
    Board.roleAtCalls = 0;
    Board.removePieceAtCalls = 0;
    Board.setPieceAtCalls = 0;
    Board.boardCreations = 0;
  }

  void printCounters() {
    print('  pieceAt: ${Board.pieceAtCalls}');
    print('  roleAt: ${Board.roleAtCalls}');
    print('  removePieceAt: ${Board.removePieceAtCalls}');
    print('  setPieceAt: ${Board.setPieceAtCalls}');
    print('  boardCreations: ${Board.boardCreations}');
  }

  @override
  void setup() {
    resetCounters();
  }

  @override
  void teardown() {
    resetCounters();
    run();
    printCounters();  }
}

// Individual benchmark implementations

class InitialPerftBenchmark extends PerftBenchmark {
  InitialPerftBenchmark() : super('Initial position perft at depth 5');

  @override
  void run() {
    perft(Chess.initial, 5);
  }
}

class CrazyhousePerftBenchmark extends PerftBenchmark {
  CrazyhousePerftBenchmark() : super('Crazyhouse position perft at depth 5');

  @override
  void run() {
    perft(Crazyhouse.initial, 5);
  }
}

class HordePerftBenchmark extends PerftBenchmark {
  HordePerftBenchmark() : super('Horde position perft at depth 5');

  @override
  void run() {
    perft(Horde.initial, 5);
  }
}

class RacingKingsPerftBenchmark extends PerftBenchmark {
  RacingKingsPerftBenchmark() : super('RacingKings position perft at depth 5');

  @override
  void run() {
    perft(RacingKings.initial, 5);
  }
}

class AtomicPerftBenchmark extends PerftBenchmark {
  AtomicPerftBenchmark() : super('Atomic position perft at depth 5');

  @override
  void run() {
    perft(Atomic.initial, 5);
  }
}

class AntichessPerftBenchmark extends PerftBenchmark {
  AntichessPerftBenchmark() : super('Antichess position perft at depth 5');

  @override
  void run() {
    perft(Antichess.initial, 5);
  }
}

class ThreeCheckPerftBenchmark extends PerftBenchmark {
  ThreeCheckPerftBenchmark() : super('ThreeCheck position perft at depth 5');

  @override
  void run() {
    perft(ThreeCheck.initial, 5);
  }
}

void main() {
  InitialPerftBenchmark().report();
  CrazyhousePerftBenchmark().report();
  HordePerftBenchmark().report();
  RacingKingsPerftBenchmark().report();
  AtomicPerftBenchmark().report();
  AntichessPerftBenchmark().report();
  ThreeCheckPerftBenchmark().report();
}
