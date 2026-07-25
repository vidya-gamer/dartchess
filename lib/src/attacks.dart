import './square_set.dart';
import './models.dart';

// Flattened 64x64 matrix using fast bitwise lookups
final List<SquareSet> _betweenTable = List<SquareSet>.generate(4096, (index) {
  final a = index >> 6;
  final b = index & 63;
  return _computeBetweenRaw(a, b);
});

SquareSet _alignedRange(Square a, SquareSet other) {
  final rRange = _rankRange[a];
  if (rRange.isIntersected(other)) return rRange.withSquare(a);
  final adRange = _antiDiagRange[a];
  if (adRange.isIntersected(other)) return adRange.withSquare(a);
  final dRange = _diagRange[a];
  if (dRange.isIntersected(other)) return dRange.withSquare(a);
  final fRange = _fileRange[a];
  if (fRange.isIntersected(other)) return fRange.withSquare(a);
  return SquareSet.empty;
}

SquareSet _computeBetweenRaw(int a, int b) {
  final sqA = Square(a);
  final sqB = Square(b);

  final r = _alignedRange(sqA, SquareSet.fromSquare(sqB));
  return r
      .intersect(SquareSet.full.shl(sqA).xor(SquareSet.full.shl(sqB)))
      .withoutFirst();
}

/// Gets squares attacked or defended by a king on [Square].
@pragma('vm:prefer-inline')
SquareSet kingAttacks(Square square) => _kingAttacks[square];

/// Gets squares attacked or defended by a knight on [Square].
@pragma('vm:prefer-inline')
SquareSet knightAttacks(Square square) => _knightAttacks[square];

/// Gets squares attacked or defended by a pawn of the given [Side] on [Square].
@pragma('vm:prefer-inline')
SquareSet pawnAttacks(Side side, Square square) => _pawnAttacks[side]![square];

/// Gets squares attacked or defended by a bishop on [Square], given `occupied` squares.
@pragma('vm:prefer-inline')
SquareSet bishopAttacks(Square square, SquareSet occupied) {
  final bit = SquareSet.fromSquare(square);
  return _hyperbolaOptimized(bit, _diagRange[square], occupied) ^
      _hyperbolaOptimized(bit, _antiDiagRange[square], occupied);
}

/// Gets squares attacked or defended by a rook on [Square], given `occupied` squares.
@pragma('vm:prefer-inline')
SquareSet rookAttacks(Square square, SquareSet occupied) {
  return _fileAttacks(square, occupied) ^ _rankAttacks(square, occupied);
}

/// Gets squares attacked or defended by a queen on [Square], given `occupied` squares.
@pragma('vm:prefer-inline')
SquareSet queenAttacks(Square square, SquareSet occupied) =>
    bishopAttacks(square, occupied) ^ rookAttacks(square, occupied);

final List<SquareSet Function(Square square, SquareSet occupied)> _routerTable = [
  (square, occupied) => SquareSet.empty,                  // Role.pawn (index 0 - handled manually via color branch)
  (square, occupied) => _knightAttacks[square],           // Role.knight (index 1)
  (square, occupied) => bishopAttacks(square, occupied), // Role.bishop (index 2)
  (square, occupied) => rookAttacks(square, occupied),   // Role.rook (index 3)
  (square, occupied) => _kingAttacks[square],             // Role.king (index 4)
  (square, occupied) => queenAttacks(square, occupied),  // Role.queen (index 5)
];

/// Gets squares attacked or defended by a `piece` on `square`, given `occupied` squares.
@pragma('vm:prefer-inline')
SquareSet attacks(Piece piece, Square square, SquareSet occupied) {
  if (piece.role == Role.pawn) {
    return _pawnAttacks[piece.color]![square];
  }
  return _routerTable[piece.role.index](square, occupied);
}

/// Gets all squares of the rank, file or diagonal with the two squares `a` and `b`.
@pragma('vm:prefer-inline')
SquareSet ray(Square a, Square b) {
  return _alignedRange(a, SquareSet.fromSquare(b));
}

/// Gets all squares between `a` and `b` (bounds not included).
@pragma('vm:prefer-inline')
SquareSet between(Square a, Square b) {
  return _betweenTable[(a * 64) + b];
}

// --- INTERNAL ENGINE COMPUTE ---

SquareSet _computeRange(Square square, List<int> deltas) {
  SquareSet range = SquareSet.empty;
  for (final delta in deltas) {
    final sq = square + delta;
    if (0 <= sq && sq < 64 && (square.file - Square(sq).file).abs() <= 2) {
      range = range.withSquare(Square(sq));
    }
  }
  return range;
}

List<T> _tabulate<T>(T Function(Square square) f) {
  final List<T> table = [];
  for (final square in Square.values) {
    table.insert(square, f(square));
  }
  return table;
}

final _kingAttacks =
    _tabulate((sq) => _computeRange(sq, [-9, -8, -7, -1, 1, 7, 8, 9]));
final _knightAttacks =
    _tabulate((sq) => _computeRange(sq, [-17, -15, -10, -6, 6, 10, 15, 17]));
final _pawnAttacks = {
  Side.white: _tabulate((sq) => _computeRange(sq, [7, 9])),
  Side.black: _tabulate((sq) => _computeRange(sq, [-7, -9])),
};

final _fileRange =
    _tabulate((sq) => SquareSet.fromFile(sq.file).withoutSquare(sq));
final _rankRange =
    _tabulate((sq) => SquareSet.fromRank(sq.rank).withoutSquare(sq));

final _diagRange = _tabulate((sq) {
  final shift = 8 * (sq.rank - sq.file);
  return (shift >= 0
          ? SquareSet.diagonal.shl(shift)
          : SquareSet.diagonal.shr(-shift))
      .withoutSquare(sq);
});

final _antiDiagRange = _tabulate((sq) {
  final shift = 8 * (sq.rank + sq.file - 7);
  return (shift >= 0
          ? SquareSet.antidiagonal.shl(shift)
          : SquareSet.antidiagonal.shr(-shift))
      .withoutSquare(sq);
});

@pragma('vm:prefer-inline')
SquareSet _hyperbolaOptimized(SquareSet bit, SquareSet range, SquareSet occupied) {
  SquareSet forward = occupied & range;
  SquareSet reverse = forward.flipVertical();
  forward = forward - bit;
  reverse = reverse - bit.flipVertical();
  return (forward ^ reverse.flipVertical()) & range;
}

@pragma('vm:prefer-inline')
SquareSet _fileAttacks(Square square, SquareSet occupied) {
  return _hyperbolaOptimized(SquareSet.fromSquare(square), _fileRange[square], occupied);
}

@pragma('vm:prefer-inline')
SquareSet _rankAttacks(Square square, SquareSet occupied) {
  final range = _rankRange[square];
  final bit = SquareSet.fromSquare(square);

  SquareSet forward = occupied & range;
  SquareSet reverse = forward.mirrorHorizontal();
  forward = forward - bit;
  reverse = reverse - bit.mirrorHorizontal();

  return (forward ^ reverse.mirrorHorizontal()) & range;
}
