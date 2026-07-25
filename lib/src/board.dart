import 'package:meta/meta.dart';
import './square_set.dart';
import './models.dart';
import './attacks.dart';

/// A board represented by several square sets for each piece.
@immutable
class Board {
  static int pieceAtCalls = 0;
  static int roleAtCalls = 0;
  static int removePieceAtCalls = 0;
  static int setPieceAtCalls = 0;
  const Board({
    required this.occupied,
    required this.promoted,
    required this.white,
    required this.black,
    required this.pawns,
    required this.knights,
    required this.bishops,
    required this.rooks,
    required this.queens,
    required this.kings,
  });

  static int boardCreations = 0;

static Board create({
  required SquareSet occupied,
  required SquareSet promoted,
  required SquareSet white,
  required SquareSet black,
  required SquareSet pawns,
  required SquareSet knights,
  required SquareSet bishops,
  required SquareSet rooks,
  required SquareSet queens,
  required SquareSet kings,
}) {
  boardCreations++;
  return Board(
    occupied: occupied,
    promoted: promoted,
    white: white,
    black: black,
    pawns: pawns,
    knights: knights,
    bishops: bishops,
    rooks: rooks,
    queens: queens,
    kings: kings,
  );
}

  /// All occupied squares.
  final SquareSet occupied;

  /// All squares occupied by pieces known to be promoted.
  final SquareSet promoted;

  /// All squares occupied by white pieces.
  final SquareSet white;

  /// All squares occupied by black pieces.
  final SquareSet black;

  /// All squares occupied by pawns.
  final SquareSet pawns;

  /// All squares occupied by knights.
  final SquareSet knights;

  /// All squares occupied by bishops.
  final SquareSet bishops;

  /// All squares occupied by rooks.
  final SquareSet rooks;

  /// All squares occupied by queens.
  final SquareSet queens;

  /// All squares occupied by kings.
  final SquareSet kings;

  /// Standard chess starting position.
  static const standard = Board(
    occupied: SquareSet(0xffff00000000ffff),
    promoted: SquareSet.empty,
    white: SquareSet(0xffff),
    black: SquareSet(0xffff000000000000),
    pawns: SquareSet(0x00ff00000000ff00),
    knights: SquareSet(0x4200000000000042),
    bishops: SquareSet(0x2400000000000024),
    rooks: SquareSet.corners,
    queens: SquareSet(0x0800000000000008),
    kings: SquareSet(0x1000000000000010),
  );

  /// Racing Kings start position
  static const racingKings = Board(
    occupied: SquareSet(0xffff),
    promoted: SquareSet.empty,
    white: SquareSet(0xf0f0),
    black: SquareSet(0x0f0f),
    pawns: SquareSet.empty,
    knights: SquareSet(0x1818),
    bishops: SquareSet(0x2424),
    rooks: SquareSet(0x4242),
    queens: SquareSet(0x0081),
    kings: SquareSet(0x8100),
  );

  /// Horde start Position
  static const horde = Board(
    occupied: SquareSet(0xffff0066ffffffff),
    promoted: SquareSet.empty,
    white: SquareSet(0x00000066ffffffff),
    black: SquareSet(0xffff000000000000),
    pawns: SquareSet(0x00ff0066ffffffff),
    knights: SquareSet(0x4200000000000000),
    bishops: SquareSet(0x2400000000000000),
    rooks: SquareSet(0x8100000000000000),
    queens: SquareSet(0x0800000000000000),
    kings: SquareSet(0x1000000000000000),
  );

  /// Empty board.
  static const empty = Board(
    occupied: SquareSet.empty,
    promoted: SquareSet.empty,
    white: SquareSet.empty,
    black: SquareSet.empty,
    pawns: SquareSet.empty,
    knights: SquareSet.empty,
    bishops: SquareSet.empty,
    rooks: SquareSet.empty,
    queens: SquareSet.empty,
    kings: SquareSet.empty,
  );

  /// Parse the board part of a FEN string and returns a Board.
  factory Board.parseFen(String boardFen) {
    Board board = Board.empty;
    int rank = 7;
    int file = 0;
    for (int i = 0; i < boardFen.length; i++) {
      final c = boardFen[i];
      if (c == '/' && file == 8) {
        file = 0;
        rank--;
      } else {
        final code = c.codeUnitAt(0);
        if (code < 57) {
          file += code - 48;
        } else {
          if (file >= 8 || rank < 0) {
            throw const FenException(IllegalFenCause.board);
          }
          final square = Square(file + (rank << 3));
          final promoted = i + 1 < boardFen.length && boardFen[i + 1] == '~';
          final piece = _charToPiece(c, promoted);
          if (piece == null) throw const FenException(IllegalFenCause.board);
          if (promoted) i++;
          board = board.setPieceAt(square, piece);
          file++;
        }
      }
    }
    if (rank != 0 || file != 8) throw const FenException(IllegalFenCause.board);
    return board;
  }

  /// The square set of all rooks and queens.
  @pragma('vm:prefer-inline')
  SquareSet get rooksAndQueens => rooks | queens;

  /// The square set of all bishops and queens.
  @pragma('vm:prefer-inline')
  SquareSet get bishopsAndQueens => bishops | queens;

  /// Board part of the Forsyth-Edwards-Notation.
  String get fen {
    final buffer = StringBuffer();
    int empty = 0;
    for (int rank = 7; rank >= 0; rank--) {
      final rankOffset = rank << 3;
      for (int file = 0; file < 8; file++) {
        final square = Square(file | rankOffset);
        final piece = pieceAt(square);
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            buffer.write(empty);
            empty = 0;
          }
          buffer.write(piece.fenChar);
        }

        if (file == 7) {
          if (empty > 0) {
            buffer.write(empty);
            empty = 0;
          }
          if (rank != 0) buffer.write('/');
        }
      }
    }
    return buffer.toString();
  }

  /// A flat list of each [Piece] associated with its [Square].
  Iterable<(Square, Piece)> get pieces {
    final squares = occupied.toSquareList();
    return List<(Square, Piece)>.generate(
      squares.length,
      (i) {
        final square = squares[i];
        return (square, pieceAt(square)!);
      },
      growable: false,
    );
  }

  /// Gets the number of pieces of each [Role] for the given [Side].
  ByRole<int> materialCount(Side side) {
    final s = bySide(side);
    return {
      Role.pawn: (pawns & s).size,
      Role.knight: (knights & s).size,
      Role.bishop: (bishops & s).size,
      Role.rook: (rooks & s).size,
      Role.queen: (queens & s).size,
      Role.king: (kings & s).size,
    };
  }

  /// A [SquareSet] of all the pieces matching this [Side] and [Role].
  @pragma('vm:prefer-inline')
  SquareSet piecesOf(Side side, Role role) {
    return bySide(side) & byRole(role);
  }

  /// Gets all squares occupied by [Side].
  @pragma('vm:prefer-inline')
  SquareSet bySide(Side side) => side == Side.white ? white : black;

  /// Gets all squares occupied by [Role].
  @pragma('vm:prefer-inline')
  SquareSet byRole(Role role) {
    switch (role) {
      case Role.pawn:
        return pawns;
      case Role.knight:
        return knights;
      case Role.bishop:
        return bishops;
      case Role.rook:
        return rooks;
      case Role.queen:
        return queens;
      case Role.king:
        return kings;
    }
  }

  /// Gets all squares occupied by [Piece].
  @pragma('vm:prefer-inline')
  SquareSet byPiece(Piece piece) {
    return bySide(piece.color) & byRole(piece.role);
  }

  /// Gets the [Side] at this [Square], if any.
  @pragma('vm:prefer-inline')
  Side? sideAt(Square square) {
    if (white.has(square)) return Side.white;
    if (black.has(square)) return Side.black;
    return null;
  }

  /// Gets the [Role] at this [Square], if any.
  @pragma('vm:prefer-inline')
  Role? roleAt(Square square) {
    //roleAtCalls++;
    if (!occupied.has(square)) return null;
    if (pawns.has(square)) return Role.pawn;
    if (knights.has(square)) return Role.knight;
    if (bishops.has(square)) return Role.bishop;
    if (rooks.has(square)) return Role.rook;
    if (queens.has(square)) return Role.queen;
    return Role.king;
  }

  /// Gets the [Piece] at this [Square], if any.
  @pragma('vm:prefer-inline')
Piece? pieceAt(Square square) {
  //pieceAtCalls++;
  if (!occupied.has(square)) return null;

  final role =
      pawns.has(square)
          ? Role.pawn
          : knights.has(square)
              ? Role.knight
              : bishops.has(square)
                  ? Role.bishop
                  : rooks.has(square)
                      ? Role.rook
                      : queens.has(square)
                          ? Role.queen
                          : Role.king;

  return Piece(
    color: white.has(square) ? Side.white : Side.black,
    role: role,
    promoted: promoted.has(square),
  );
}



  /// Finds the unique king [Square] of the given [Side], if any.
  @pragma('vm:prefer-inline')
  Square? kingOf(Side side) {
    return (kings & bySide(side)).singleSquare;
  }

  /// Finds the squares who are attacking `square` by the `attacker` [Side].
  /// Direct bitwise operator evaluation without method-call chaining.
  @pragma('vm:prefer-inline')
  SquareSet attacksTo(Square square, Side attacker, {SquareSet? occupied}) {
    final occ = occupied ?? this.occupied;
    return bySide(attacker) &
        ((rookAttacks(square, occ) & rooksAndQueens) |
            (bishopAttacks(square, occ) & bishopsAndQueens) |
            (knightAttacks(square) & knights) |
            (kingAttacks(square) & kings) |
            (pawnAttacks(attacker.opposite, square) & pawns));
  }

  /// Puts a [Piece] on a [Square] overriding the existing one, if any.
  @useResult
  Board setPieceAt(Square square, Piece piece) {
    //setPieceAtCalls++;
    if (!occupied.has(square)) {
      return Board(
        occupied: occupied.withSquare(square),
        promoted: piece.promoted ? promoted.withSquare(square) : promoted,
        white: piece.color == Side.white ? white.withSquare(square) : white,
        black: piece.color == Side.black ? black.withSquare(square) : black,
        pawns: piece.role == Role.pawn ? pawns.withSquare(square) : pawns,
        knights:
            piece.role == Role.knight ? knights.withSquare(square) : knights,
        bishops:
            piece.role == Role.bishop ? bishops.withSquare(square) : bishops,
        rooks: piece.role == Role.rook ? rooks.withSquare(square) : rooks,
        queens: piece.role == Role.queen ? queens.withSquare(square) : queens,
        kings: piece.role == Role.king ? kings.withSquare(square) : kings,
      );
    }

    final oldRole = roleAt(square)!;
    final isWhite = white.has(square);

    return Board(
      occupied: occupied,
      promoted: piece.promoted
          ? promoted.withSquare(square)
          : (promoted.has(square) ? promoted.withoutSquare(square) : promoted),
      white: piece.color == Side.white
          ? white.withSquare(square)
          : (isWhite ? white.withoutSquare(square) : white),
      black: piece.color == Side.black
          ? black.withSquare(square)
          : (!isWhite ? black.withoutSquare(square) : black),
      pawns: piece.role == Role.pawn
          ? pawns.withSquare(square)
          : (oldRole == Role.pawn ? pawns.withoutSquare(square) : pawns),
      knights: piece.role == Role.knight
          ? knights.withSquare(square)
          : (oldRole == Role.knight ? knights.withoutSquare(square) : knights),
      bishops: piece.role == Role.bishop
          ? bishops.withSquare(square)
          : (oldRole == Role.bishop ? bishops.withoutSquare(square) : bishops),
      rooks: piece.role == Role.rook
          ? rooks.withSquare(square)
          : (oldRole == Role.rook ? rooks.withoutSquare(square) : rooks),
      queens: piece.role == Role.queen
          ? queens.withSquare(square)
          : (oldRole == Role.queen ? queens.withoutSquare(square) : queens),
      kings: piece.role == Role.king
          ? kings.withSquare(square)
          : (oldRole == Role.king ? kings.withoutSquare(square) : kings),
    );
  }

  /// Removes the [Piece] at this [Square] if it exists.
  @useResult
  Board removePieceAt(Square square) {
    //removePieceAtCalls++;
    if (!occupied.has(square)) return this;

    final oldRole = roleAt(square)!;
    final isWhite = white.has(square);

    return Board(
      occupied: occupied.withoutSquare(square),
      promoted:
          promoted.has(square) ? promoted.withoutSquare(square) : promoted,
      white: isWhite ? white.withoutSquare(square) : white,
      black: !isWhite ? black.withoutSquare(square) : black,
      pawns: oldRole == Role.pawn ? pawns.withoutSquare(square) : pawns,
      knights: oldRole == Role.knight ? knights.withoutSquare(square) : knights,
      bishops: oldRole == Role.bishop ? bishops.withoutSquare(square) : bishops,
      rooks: oldRole == Role.rook ? rooks.withoutSquare(square) : rooks,
      queens: oldRole == Role.queen ? queens.withoutSquare(square) : queens,
      kings: oldRole == Role.king ? kings.withoutSquare(square) : kings,
    );
  }

  /// Returns a new board with a new [promoted] square set.
  @useResult
  Board withPromoted(SquareSet promoted) {
    return copyWith(promoted: promoted);
  }

  /// Returns a copy of this board with some fields updated.
  @useResult
  Board copyWith({
    SquareSet? occupied,
    SquareSet? promoted,
    SquareSet? white,
    SquareSet? black,
    SquareSet? pawns,
    SquareSet? knights,
    SquareSet? bishops,
    SquareSet? rooks,
    SquareSet? queens,
    SquareSet? kings,
  }) {
    return Board(
      occupied: occupied ?? this.occupied,
      promoted: promoted ?? this.promoted,
      white: white ?? this.white,
      black: black ?? this.black,
      pawns: pawns ?? this.pawns,
      knights: knights ?? this.knights,
      bishops: bishops ?? this.bishops,
      rooks: rooks ?? this.rooks,
      queens: queens ?? this.queens,
      kings: kings ?? this.kings,
    );
  }

  @override
  String toString() => fen;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Board &&
            other.occupied == occupied &&
            other.promoted == promoted &&
            other.white == white &&
            other.black == black &&
            other.pawns == pawns &&
            other.knights == knights &&
            other.bishops == bishops &&
            other.rooks == rooks &&
            other.queens == queens &&
            other.kings == kings;
  }

  @override
  int get hashCode => Object.hash(occupied, promoted, white, black, pawns,
      knights, bishops, rooks, queens, kings);
}

Piece? _charToPiece(String ch, bool promoted) {
  final role = Role.fromChar(ch);
  if (role != null) {
    return Piece(
        role: role,
        color: ch == ch.toLowerCase() ? Side.black : Side.white,
        promoted: promoted);
  }
  return null;
}

extension BoardMoving on Board {
  /// Fast single-pass move execution using bitwise XOR masks for Dart 3.x.
  Board movePiece(
    Square from,
    Square to,
    Piece piece,
    Piece? capturedPiece,
  ) {
    // 1. Pre-calculate XOR move mask to toggle 'from' and 'to' in a single bitwise operation
    final moveMask = SquareSet.fromSquare(from) | SquareSet.fromSquare(to);
    final toMask = SquareSet.fromSquare(to);

    // 2. Update Side Bitboards
    final isWhite = piece.color == Side.white;
    final newWhite = isWhite
        ? (white ^ moveMask)
        : (capturedPiece != null ? white.withoutSquare(to) : white);
    final newBlack = !isWhite
        ? (black ^ moveMask)
        : (capturedPiece != null ? black.withoutSquare(to) : black);

    // 3. Update Promoted Bitboard
    SquareSet newPromoted = promoted.withoutSquare(from);
    newPromoted = piece.promoted 
        ? newPromoted.withSquare(to) 
        : newPromoted.withoutSquare(to);

    // 4. Update Piece-Type Bitboards
    var pawns = this.pawns;
    var knights = this.knights;
    var bishops = this.bishops;
    var rooks = this.rooks;
    var queens = this.queens;
    var kings = this.kings;

    // Remove captured piece at 'to' (if any)
    if (capturedPiece != null) {
      switch (capturedPiece.role) {
        case Role.pawn: pawns ^= toMask;
        case Role.knight: knights ^= toMask;
        case Role.bishop: bishops ^= toMask;
        case Role.rook: rooks ^= toMask;
        case Role.queen: queens ^= toMask;
        case Role.king: kings ^= toMask;
      }
    }

    // Move piece from 'from' to 'to'
    switch (piece.role) {
      case Role.pawn: pawns ^= moveMask;
      case Role.knight: knights ^= moveMask;
      case Role.bishop: bishops ^= moveMask;
      case Role.rook: rooks ^= moveMask;
      case Role.queen: queens ^= moveMask;
      case Role.king: kings ^= moveMask;
    }

    return Board(
      occupied: (occupied ^ moveMask) | (capturedPiece != null ? toMask : SquareSet.empty),
      promoted: newPromoted,
      white: newWhite,
      black: newBlack,
      pawns: pawns,
      knights: knights,
      bishops: bishops,
      rooks: rooks,
      queens: queens,
      kings: kings,
    );
  }
}
