import 'package:dartchess/src/attacks_old.dart' as old_attacks;
import 'package:dartchess/src/attacks.dart' as new_attacks;
import 'package:dartchess/src/models.dart';
import 'package:dartchess/src/square_set_old.dart' as old_set show SquareSet;
import 'package:dartchess/src/square_set.dart' as new_set show SquareSet;
import 'package:dartchess/src/setup_old.dart' as old_setup show Setup;
import 'package:dartchess/src/setup.dart' as new_setup show Setup;

void main() {
  int mismatchCount = 0;

  // Build old and new identical occupancy lists for cross-parity testing
  final oldOccupancies = [
    old_set.SquareSet.empty,
    old_set.SquareSet.full,
    old_set.SquareSet.fromRank(Rank.second) |
        old_set.SquareSet.fromRank(Rank.seventh),
    old_set.SquareSet.fromFile(File.a) | old_set.SquareSet.fromFile(File.h),
    ...Square.values.map((s) => old_set.SquareSet.fromSquare(s)),
    old_set.SquareSet(_generateDeterministicBits(0x12345678)),
    old_set.SquareSet(_generateDeterministicBits(0xABCDEF12)),
    old_set.SquareSet(_generateDeterministicBits(0x98765432)),
  ];

  final newOccupancies = [
    new_set.SquareSet.empty,
    new_set.SquareSet.full,
    new_set.SquareSet.fromRank(Rank.second) |
        new_set.SquareSet.fromRank(Rank.seventh),
    new_set.SquareSet.fromFile(File.a) | new_set.SquareSet.fromFile(File.h),
    ...Square.values.map((s) => new_set.SquareSet.fromSquare(s)),
    new_set.SquareSet(_generateDeterministicBits(0x12345678)),
    new_set.SquareSet(_generateDeterministicBits(0xABCDEF12)),
    new_set.SquareSet(_generateDeterministicBits(0x98765432)),
  ];

  print('--- Phase 1: Verifying Attacks & Rays Parity ---');
  for (final sqA in Square.values) {
    // Verify King, Knight, and Pawn paths
    if (old_attacks.kingAttacks(sqA).value !=
        new_attacks.kingAttacks(sqA).value) mismatchCount++;
    if (old_attacks.knightAttacks(sqA).value !=
        new_attacks.knightAttacks(sqA).value) mismatchCount++;
    if (old_attacks.pawnAttacks(Side.white, sqA).value !=
        new_attacks.pawnAttacks(Side.white, sqA).value) mismatchCount++;
    if (old_attacks.pawnAttacks(Side.black, sqA).value !=
        new_attacks.pawnAttacks(Side.black, sqA).value) mismatchCount++;

    // Verify Sliders
    for (int i = 0; i < oldOccupancies.length; i++) {
      // Since both old_attacks and new_attacks expect the production (new) SquareSet,
      // we use newOcc for both calls to verify they return identical bitmask values.
      final occ = newOccupancies[i];

      if (old_attacks.bishopAttacks(sqA, occ).value !=
          new_attacks.bishopAttacks(sqA, occ).value) {
        mismatchCount++;
      }
      if (old_attacks.rookAttacks(sqA, occ).value !=
          new_attacks.rookAttacks(sqA, occ).value) {
        mismatchCount++;
      }
    }

    // Verify Between Raycast Table
    for (final sqB in Square.values) {
      if (old_attacks.between(sqA, sqB).value !=
          new_attacks.between(sqA, sqB).value) {
        print('Mismatch found on between(${sqA.name}, ${sqB.name})');
        mismatchCount++;
      }
    }
  }

  print('--- Phase 2: Verifying SquareSet Internal Parity ---');
  final oldSetFromSquares = old_set.SquareSet.fromSquares(Square.values);
  final newSetFromSquares = new_set.SquareSet.fromSquares(Square.values);
  if (oldSetFromSquares.value != newSetFromSquares.value) mismatchCount++;

  for (int i = 0; i < oldOccupancies.length; i++) {
    final oldS = oldOccupancies[i];
    final newS = newOccupancies[i];

    // Fundamental structural property parity
    if (oldS.size != newS.size) mismatchCount++;
    if (oldS.isEmpty != newS.isEmpty) mismatchCount++;
    if (oldS.isNotEmpty != newS.isNotEmpty) mismatchCount++;
    if (oldS.moreThanOne != newS.moreThanOne) mismatchCount++;
    if (oldS.first != newS.first) mismatchCount++;
    if (oldS.last != newS.last) mismatchCount++;
    if (oldS.singleSquare != newS.singleSquare) mismatchCount++;

    // Transposition and Shift parity
    if (oldS.flipVertical().value != newS.flipVertical().value) mismatchCount++;
    if (oldS.mirrorHorizontal().value != newS.mirrorHorizontal().value)
      mismatchCount++;
    if (oldS.shl(4).value != newS.shl(4).value) mismatchCount++;
    if (oldS.shr(4).value != newS.shr(4).value) mismatchCount++;
    if (oldS.withoutFirst().value != newS.withoutFirst().value) mismatchCount++;

    // Element extraction list parity
    final oldSquares = oldS.squares.toList();
    final newSquaresList = newS.toSquareList();
    if (oldSquares.length != newSquaresList.length) {
      mismatchCount++;
    } else {
      for (int j = 0; j < oldSquares.length; j++) {
        if (oldSquares[j] != newSquaresList[j]) mismatchCount++;
      }
    }

    // Secondary deep verification loops matching set against target sets
    for (int j = 0; j < oldOccupancies.length; j++) {
      final oldTarget = oldOccupancies[j];
      final newTarget = newOccupancies[j];

      if ((oldS & oldTarget).value != (newS & newTarget).value) mismatchCount++;
      if ((oldS | oldTarget).value != (newS | newTarget).value) mismatchCount++;
      if ((oldS ^ oldTarget).value != (newS ^ newTarget).value) mismatchCount++;
      if ((oldS - oldTarget).value != (newS - newTarget).value) mismatchCount++;
      if (oldS.isIntersected(oldTarget) != newS.isIntersected(newTarget))
        mismatchCount++;
      if (oldS.isDisjoint(oldTarget) != newS.isDisjoint(newTarget))
        mismatchCount++;
    }
  }

  print('--- Phase 3: Verifying FEN Parser Parity ---');
  final testFens = [
    // --- Proper FENs ---
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', // Standard initial
    'r1bqkbnr/ppp2Qpp/2np4/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4', // Checkmate
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', // Space separator
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR_w_KQkq_-_0_1', // Underscore separator
    'rnbqkb1r/pppp1ppp/8/4p3/3Pn3/8/PPPB1PPP/RN1QKBNR w KQkq - 1 4', // Typical mid-game
    'r8/8/8/8/8/8/8/R3K2R w KQ - 0 1', // Castling setup
    'rnbqkb1r/pppp1ppp/8/4p3/3Pn3/8/PPPB1PPP/RN1QKBNR w KQkq - 1 4',

    // Variant-specific: Crazyhouse (Pockets)
    'r2qk2r/ppp1bppp/2np1nb1/4p3/4P1P1/2NP1N1P/PPP1BP2/R1BQK2R[pq] w KQkq - 0 1', // Pocket syntax with brackets
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR/ w KQkq - 0 1', // Pocket with slash separator
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR/pP w KQkq - 0 1', // Pocket with pieces

    // Variant-specific: Three-check (Remaining checks)
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1 +3+3', // Remaining checks syntax

    // --- Malformed/Edge-Case FENs (To test exception/boundary parity) ---
    ' rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', // Leading space
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1 ', // Trailing space
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR  w KQkq - 0 1', // Double internal space
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR\tw\tKQkq\t-\t0\t1', // Tabs instead of spaces
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR_ w _KQkq - 0 1', // Mixed spaces and underscores
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR', // Missing components entirely
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1\n', // Trailing newline
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR[ w KQkq - 0 1', // Unclosed bracket
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR] w KQkq - 0 1', // Unopened bracket
    '/', // Empty boundary FEN split equivalent
  ];

  for (final fen in testFens) {
    old_setup.Setup? oldResult;
    new_setup.Setup? newResult;
    Object? oldException;
    Object? newException;

    // Run old parser
    try {
      oldResult = old_setup.Setup.parseFen(fen);
    } catch (e) {
      oldException = e;
    }

    // Run new parser
    try {
      newResult = new_setup.Setup.parseFen(fen);
    } catch (e) {
      newException = e;
    }

    // Both should have either failed or succeeded
    if ((oldException == null) != (newException == null)) {
      print('PARITY FAIL (Success mismatch) on FEN: "$fen"');
      print('  Old Parser: ${oldException ?? "Success"}');
      print('  New Parser: ${newException ?? "Success"}');
      mismatchCount++;
      continue;
    }

    if (oldException != null && newException != null) {
      // If both threw, verify they threw the exact same exception cause
      if (oldException is FenException && newException is FenException) {
        if (oldException.cause != newException.cause) {
          print('PARITY FAIL (Exception Cause Mismatch) on FEN: "$fen"');
          print('  Old: ${oldException.cause}, New: ${newException.cause}');
          mismatchCount++;
        }
      } else {
        print('PARITY WARNING: Non-FenException thrown on FEN: "$fen"');
        mismatchCount++;
      }
    } else if (oldResult != null && newResult != null) {
      // Both parsed successfully; verify deep structural parity of the outputs
      final bool boardMatch = oldResult.board == newResult.board;
      final bool turnMatch = oldResult.turn == newResult.turn;
      final bool castlingMatch =
          oldResult.castlingRights.value == newResult.castlingRights.value;
      final bool epMatch = oldResult.epSquare == newResult.epSquare;
      final bool halfMatch = oldResult.halfmoves == newResult.halfmoves;
      final bool fullMatch = oldResult.fullmoves == newResult.fullmoves;
      final bool remainingChecksMatch =
          oldResult.remainingChecks == newResult.remainingChecks;

// Basic pockets check utilizing deep value properties instead of reference identity
      final bool pocketsMatch;
      if (oldResult.pockets == null && newResult.pockets == null) {
        pocketsMatch = true;
      } else if (oldResult.pockets != null && newResult.pockets != null) {
        final oldP = oldResult.pockets!;
        final newP = newResult.pockets!;

        // Verify that the count of each role for both sides matches perfectly
        bool countsMatch = true;
        for (final side in Side.values) {
          for (final role in Role.values) {
            if (oldP.of(side, role) != newP.of(side, role)) {
              // Or oldP.count(role) if applicable
              countsMatch = false;
              break;
            }
          }
        }
        pocketsMatch = countsMatch && (oldP.size == newP.size);
      } else {
        pocketsMatch = false;
      }

      if (!boardMatch ||
          !turnMatch ||
          !castlingMatch ||
          !epMatch ||
          !halfMatch ||
          !fullMatch ||
          !pocketsMatch ||
          !remainingChecksMatch) {
        print('PARITY FAIL (Parsed State Mismatch) on FEN: "$fen"');
        print('  Old Pockets: ${oldResult.pockets}');
        print('  New Pockets: ${newResult.pockets}');
        print('  Old Board:   ${oldResult.board}');
        print('  New Board:   ${newResult.board}');
        mismatchCount++;
      }
    }
  }

  print('--- Verification Complete ---');
  if (mismatchCount == 0) {
    print(
        'SUCCESS! The optimized engine core, SquareSet, and Setup parsers match 100% identically.');
  } else {
    print(
        'WARNING: Found $mismatchCount logic mismatches. Check implementation.');
  }
}

int _generateDeterministicBits(int seed) {
  int bits = seed;
  int boardValue = 0;
  for (int i = 0; i < 64; i++) {
    bits = (bits * 1103515245 + 12345) & 0xFFFFFFFF;
    if ((bits & 0x80000000) != 0) {
      boardValue |= 1 << i;
    }
  }
  return boardValue;
}
