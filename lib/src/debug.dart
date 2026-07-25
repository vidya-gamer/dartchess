import './board.dart';
import './models.dart';
import './position.dart';
import './square_set.dart';

/// Takes a string and returns a SquareSet. Useful for debugging/testing purposes.
SquareSet makeSquareSet(String rep) {
  SquareSet ret = SquareSet.empty;
  final table = rep
      .split('\n')
      .where((l) => l.isNotEmpty)
      .map((r) => r.split(' '))
      .toList()
      .reversed
      .toList();
  for (int y = 7; y >= 0; y--) {
    for (int x = 0; x < 8; x++) {
      if (table[y][x] == '1') {
        ret = ret.withSquare(Square(x | (y << 3)));
      }
    }
  }
  return ret;
}

/// Prints the square set as a human readable string format
String humanReadableSquareSet(SquareSet sq) {
  final buffer = StringBuffer();
  for (int y = 7; y >= 0; y--) {
    final rankOffset = y << 3;
    for (int x = 0; x < 8; x++) {
      final square = Square(x | rankOffset);
      buffer.write(sq.has(square) ? '1' : '.');
      buffer.write(x < 7 ? ' ' : '\n');
    }
  }
  return buffer.toString();
}

/// Prints the board as a human readable string format
String humanReadableBoard(Board board) {
  final buffer = StringBuffer();
  for (int y = 7; y >= 0; y--) {
    final rankOffset = y << 3;
    for (int x = 0; x < 8; x++) {
      final square = Square(x | rankOffset);
      final p = board.pieceAt(square);
      final col = p != null ? p.fenChar : '.';
      buffer.write(col);
      buffer.write(x < 7 ? (col.length < 2 ? ' ' : '') : '\n');
    }
  }
  return buffer.toString();
}

const _promotionRoles = [Role.queen, Role.rook, Role.knight, Role.bishop];
const _antichessPromotionRoles = [..._promotionRoles, Role.king];

/// Counts legal move paths of a given length.
int perft(Position pos, int depth, {bool shouldLog = false}) {
  if (depth < 1) return 1;

  final promotionRoles =
      pos is Antichess ? _antichessPromotionRoles : _promotionRoles;
  final legalDrops = pos.legalDrops;

  // --- LEAF NODE (DEPTH 1) FAST PATH ---
  if (!shouldLog && depth == 1 && legalDrops.isEmpty) {
    int nodes = 0;
    pos.legalMoves.forEach((from, to) {
      if (to.isEmpty) return;
      nodes += to.size;
      if (pos.board.pawns.has(from)) {
        final backrank = SquareSet.backrankOf(pos.turn.opposite);
        nodes += to.intersect(backrank).size * (promotionRoles.length - 1);
      }
    });
    return nodes;
  }

  // --- RECURSIVE TREE SEARCH ---
int nodes = 0;
  final isWhite = pos.turn == Side.white;
  final pawnRank = isWhite ? 6 : 1;

  pos.legalMoves.forEach((from, dests) {
    if (dests.isEmpty) return;

    final isPawnPromo = from.rank == pawnRank && pos.board.pawns.has(from);

    int destBits = dests.value;
    while (destBits != 0) {
      final to = destBits.lsbSquare;

      if (isPawnPromo) {
        for (int i = 0; i < promotionRoles.length; i++) {
          final move = NormalMove(from: from, to: to, promotion: promotionRoles[i]);
          final child = pos.playUnchecked(move);
          final children = perft(child, depth - 1);
          if (shouldLog) print('${move.uci} $children');
          nodes += children;
        }
      } else {
        final move = NormalMove(from: from, to: to);
        final child = pos.playUnchecked(move);
        final children = perft(child, depth - 1);
        if (shouldLog) print('${move.uci} $children');
        nodes += children;
      }

      destBits &= destBits - 1; // Clear LSB
    }
  });

  if (pos.pockets != null) {
    for (int r = 0; r < Role.values.length; r++) {
      final role = Role.values[r];
      if (pos.pockets!.of(pos.turn, role) > 0) {
        final dropTargets = role == Role.pawn
            ? legalDrops.diff(SquareSet.backranks)
            : legalDrops;

        int dropBits = dropTargets.value;
        while (dropBits != 0) {
          final to = dropBits.lsbSquare;
          final drop = DropMove(role: role, to: to);
          final child = pos.playUnchecked(drop);
          final children = perft(child, depth - 1);
          if (shouldLog) print('${drop.uci} $children');
          nodes += children;

          dropBits &= dropBits - 1;
        }
      }
    }
  }

  return nodes;
}
