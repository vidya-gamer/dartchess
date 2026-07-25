import 'models.dart';
import 'position.dart';
import 'square_set.dart';

/// Returns all the legal moves of the [Position] in a convenient format.
///
/// Includes both possible representations of castling moves unless `includeAlternateCastlingMoves` is false.
Map<Square, Set<Square>> makeLegalMoves(
  Position pos, {
  bool includeAlternateCastlingMoves = true,
}) {
  final Map<Square, Set<Square>> result = {};
  final turn = pos.turn;
  final kingPos = pos.board.kingOf(turn);

  for (final entry in pos.legalMoves.entries) {
    final SquareSet squareSet = entry.value;
    final int value = squareSet.value;
    if (value == 0) continue; // Skip empty move sets quickly

    final from = entry.key;
    final Set<Square> destSet = {};

    // Ultra-fast bit-scan loop to populate the Destination Set
    for (int i = 0; i < 64; i++) {
      if ((value & (1 << i)) != 0) {
        destSet.add(Square(i));
      }
    }

    // Castling alternate representations logic
    // FIXED: Removed 'from.file == 4' to natively support Chess960 configurations
    if (includeAlternateCastlingMoves && from == kingPos) {
      if ((value & (1 << Square.a1.value)) != 0) destSet.add(Square.c1);
      if ((value & (1 << Square.a8.value)) != 0) destSet.add(Square.c8);
      if ((value & (1 << Square.h1.value)) != 0) destSet.add(Square.g1);
      if ((value & (1 << Square.h8.value)) != 0) destSet.add(Square.g8);
    }

    result[from] = destSet;
  }
  return result;
}
