import 'package:benchmark_harness/benchmark_harness.dart';

import '../lib/src/setup_old.dart' as old_api;
import '../lib/src/setup.dart' as new_api;

// Valid FEN strings for both parsing and serialization testing
final List<String> validFens = [
  'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
  '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
];

// Complete set of FENs (including malformed ones) for parse testing
final List<String> parseBenchmarkFens = [
  ...validFens,
  'rnbqkb1r/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKB1R[Pp] b KQkq - 2 3',
  'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - +3+3 0 1',
];

// Pre-parsed setups created ONLY from valid FENs
final List<old_api.Setup> oldTestSetups =
    validFens.map(old_api.Setup.parseFen).toList();

final List<new_api.Setup> newTestSetups =
    validFens.map(new_api.Setup.parseFen).toList();

int oldBenchmarkChecksum = 0;
int newBenchmarkChecksum = 0;

// --- 1. PARSING ISOLATION BENCHMARKS ---

class OldSetupParseBenchmark extends BenchmarkBase {
  const OldSetupParseBenchmark() : super('Old Setup.parseFen');
  @override void exercise() => run();
  @override
  void run() {
    int localChecksum = 0;
    for (int i = 0; i < 500; i++) {
      for (final fen in parseBenchmarkFens) {
        try {
          localChecksum += old_api.Setup.parseFen(fen).hashCode;
        } catch (_) {
          localChecksum += 1;
        }
      }
    }
    oldBenchmarkChecksum += localChecksum;
  }
}

class NewSetupParseBenchmark extends BenchmarkBase {
  const NewSetupParseBenchmark() : super('New Setup.parseFen (Optimized)');
  @override void exercise() => run();
  @override
  void run() {
    int localChecksum = 0;
    for (int i = 0; i < 500; i++) {
      for (final fen in parseBenchmarkFens) {
        try {
          localChecksum += new_api.Setup.parseFen(fen).hashCode;
        } catch (_) {
          localChecksum += 1;
        }
      }
    }
    newBenchmarkChecksum += localChecksum;
  }
}

// --- 2. SERIALIZATION ISOLATION BENCHMARKS ---

class OldSetupGenerationBenchmark extends BenchmarkBase {
  const OldSetupGenerationBenchmark() : super('Old Setup.fen Getter');
  @override void exercise() => run();
  @override
  void run() {
    int localChecksum = 0;
    for (int i = 0; i < 500; i++) {
      for (final setup in oldTestSetups) {
        localChecksum += setup.fen.hashCode;
      }
    }
    oldBenchmarkChecksum += localChecksum;
  }
}

class NewSetupGenerationBenchmark extends BenchmarkBase {
  const NewSetupGenerationBenchmark() : super('New Setup.fen Getter (Optimized)');
  @override void exercise() => run();
  @override
  void run() {
    int localChecksum = 0;
    for (int i = 0; i < 500; i++) {
      for (final setup in newTestSetups) {
        localChecksum += setup.fen.hashCode;
      }
    }
    newBenchmarkChecksum += localChecksum;
  }
}

// --- VERIFICATION RUNNER ---

(int, int) runVerification() {
  int oldVerify = 0;
  int newVerify = 0;

  for (final fen in parseBenchmarkFens) {
    try {
      final setup = old_api.Setup.parseFen(fen);
      oldVerify += setup.hashCode;
      oldVerify += setup.fen.hashCode;
    } catch (_) { oldVerify += 1; }

    try {
      final setup = new_api.Setup.parseFen(fen);
      newVerify += setup.hashCode;
      newVerify += setup.fen.hashCode;
    } catch (_) { newVerify += 1; }
  }
  return (oldVerify, newVerify);
}

void main() {
  print('--- Verifying Implementation Correctness ---');
  final (oldVerify, newVerify) = runVerification();
  
  if (oldVerify != newVerify) {
    print('WARNING: Checksums DO NOT match! (Old: $oldVerify, New: $newVerify)\n');
  } else {
    print('Verification PASSED! Both implementations produced identical states.\n');
  }

  print('--- Benchmarking FEN String Parsing ---');
  const OldSetupParseBenchmark().report();
  const NewSetupParseBenchmark().report();

  print('\n--- Benchmarking FEN String Generation ---');
  const OldSetupGenerationBenchmark().report();
  const NewSetupGenerationBenchmark().report();

  if (oldBenchmarkChecksum == 0 || newBenchmarkChecksum == 0) {
    print('\nError: Benchmarks did not execute correctly.');
  }
}
