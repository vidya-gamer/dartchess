import './models.dart';

/// A finite set of all squares on a chessboard.
///
/// All the squares are represented by a single 64-bit integer, where each bit
/// corresponds to a square, using a little-endian rank-file mapping.
///
/// The set operations are implemented as bitwise operations on the integer.
extension type const SquareSet(int value) {
  /// Creates a [SquareSet] with a single [Square].
  const SquareSet.fromSquare(Square square) : value = 1 << square;

  /// Creates a [SquareSet] from several [Square]s.
  factory SquareSet.fromSquares(Iterable<Square> squares) {
    int mask = 0;
    for (final square in squares) {
      mask |= 1 << square;
    }
    return SquareSet(mask);
  }

  /// Create a [SquareSet] containing all squares of the given rank.
  const SquareSet.fromRank(Rank rank)
      : value = 0xff << (8 * rank),
        assert(rank >= 0 && rank < 8);

  /// Create a [SquareSet] containing all squares of the given file.
  const SquareSet.fromFile(File file)
      : value = 0x0101010101010101 << file,
        assert(file >= 0 && file < 8);

  /// Create a [SquareSet] containing all squares of the given backrank [Side].
  const SquareSet.backrankOf(Side side)
      : value = side == Side.white ? 0xff : 0xff00000000000000;

  static const empty = SquareSet(0);
  static const full = SquareSet(-1); // 0xffffffffffffffff
  static const lightSquares = SquareSet(0x55AA55AA55AA55AA);
  static const darkSquares = SquareSet(0xAA55AA55AA55AA55);
  static const diagonal = SquareSet(0x8040201008040201);
  static const antidiagonal = SquareSet(0x0102040810204080);
  static const corners = SquareSet(0x8100000000000081);
  static const center = SquareSet(0x0000001818000000);
  static const backranks = SquareSet(0xff000000000000ff);
  static const firstRank = SquareSet(0xff);
  static const eighthRank = SquareSet(0xff00000000000000);
  static const aFile = SquareSet(0x0101010101010101);
  static const hFile = SquareSet(0x8080808080808080);

  @pragma('vm:prefer-inline')
  SquareSet shr(int shift) {
    if (shift >= 64) return SquareSet.empty;
    if (shift > 0) {
      return SquareSet((value >>> shift) & 0xffffffffffffffff);
    }
    return this;
  }

  /// Bitwise left shift
  @pragma('vm:prefer-inline')
  SquareSet shl(int shift) {
    if (shift >= 64) return SquareSet.empty;
    if (shift > 0) {
      return SquareSet((value << shift) & 0xffffffffffffffff);
    }
    return this;
  }

  @pragma('vm:prefer-inline')
  SquareSet xor(SquareSet other) => SquareSet(value ^ other.value);

  @pragma('vm:prefer-inline')
  SquareSet operator ^(SquareSet other) => SquareSet(value ^ other.value);

  @pragma('vm:prefer-inline')
  SquareSet union(SquareSet other) => SquareSet(value | other.value);

  @pragma('vm:prefer-inline')
  SquareSet operator |(SquareSet other) => SquareSet(value | other.value);

  @pragma('vm:prefer-inline')
  SquareSet intersect(SquareSet other) => SquareSet(value & other.value);

  @pragma('vm:prefer-inline')
  SquareSet operator &(SquareSet other) => SquareSet(value & other.value);

  @pragma('vm:prefer-inline')
  SquareSet minus(SquareSet other) => SquareSet(value & ~other.value);

  /// This must use arithmetic subtraction rather than set-difference.
  /// The engine uses Hyperbola Quintessence for sliding piece attack rays,
  /// which relies explicitly on standard mathematical borrowing behavior.
  /// For pure set difference, use [minus] or [diff].
  @pragma('vm:prefer-inline')
  SquareSet operator -(SquareSet other) =>
      SquareSet((value - other.value) & 0xffffffffffffffff);

  @pragma('vm:prefer-inline')
  SquareSet complement() => SquareSet(~value);

  @pragma('vm:prefer-inline')
  SquareSet diff(SquareSet other) => SquareSet(value & ~other.value);

  /// Flips the set vertically.
  @pragma('vm:prefer-inline')
  SquareSet flipVertical() {
    const k1 = 0x00FF00FF00FF00FF;
    const k2 = 0x0000FFFF0000FFFF;
    int x = ((value >>> 8) & k1) | ((value & k1) << 8);
    x = ((x >>> 16) & k2) | ((x & k2) << 16);
    x = (x >>> 32) | (x << 32);
    return SquareSet(x);
  }

  /// Flips the set horizontally.
  @pragma('vm:prefer-inline')
  SquareSet mirrorHorizontal() {
    const k1 = 0x5555555555555555;
    const k2 = 0x3333333333333333;
    const k4 = 0x0f0f0f0f0f0f0f0f;
    int x = ((value >>> 1) & k1) | ((value & k1) << 1);
    x = ((x >>> 2) & k2) | ((x & k2) << 2);
    x = ((x >>> 4) & k4) | ((x & k4) << 4);
    return SquareSet(x);
  }

  @pragma('vm:prefer-inline')
  int get size => _popcnt64(value);

  @pragma('vm:prefer-inline')
  bool get isEmpty => value == 0;

  @pragma('vm:prefer-inline')
  bool get isNotEmpty => value != 0;

  @pragma('vm:prefer-inline')
  Square? get first => value == 0 ? null : Square(_ntz64(value));

  @pragma('vm:prefer-inline')
  Square? get last => value == 0 ? null : Square(63 - _nlz64(value));

  /// Returns the squares in the set as an iterable.
  Iterable<Square> get squares => _SquareIterable(value);

  /// Returns the squares in the set as an iterable in reverse order.
  Iterable<Square> get squaresReversed => _SquareReversedIterable(value);

  @pragma('vm:prefer-inline')
  List<Square> toSquareList() {
    final count = size;
    final list = List<Square>.filled(count, const Square(0));

    int bb = value;
    int index = 0;
    while (bb != 0) {
      final int sq = _ntz64(bb);
      list[index++] = Square(sq);
      bb &= bb - 1;
    }
    return list;
  }

  @pragma('vm:prefer-inline')
  bool get moreThanOne => value != 0 && (value & (value - 1)) != 0;

  @pragma('vm:prefer-inline')
  Square? get singleSquare => moreThanOne ? null : last;

  @pragma('vm:prefer-inline')
  bool has(Square square) => (value & (1 << square)) != 0;

  @pragma('vm:prefer-inline')
  bool isIntersected(SquareSet other) => (value & other.value) != 0;

  @pragma('vm:prefer-inline')
  bool isDisjoint(SquareSet other) => (value & other.value) == 0;

  @pragma('vm:prefer-inline')
  SquareSet withSquare(Square square) => SquareSet(value | (1 << square));

  @pragma('vm:prefer-inline')
  SquareSet withoutSquare(Square square) => SquareSet(value & ~(1 << square));

  @pragma('vm:prefer-inline')
  SquareSet toggleSquare(Square square) => SquareSet(value ^ (1 << square));

  /// Instantly clears the lowest set bit using standard bitwise masking.
  @pragma('vm:prefer-inline')
  SquareSet withoutFirst() {
    final f = first;
    return f != null ? withoutSquare(f) : empty;
  }

  /// Returns the hexadecimal string representation of the bitboard value.
  String toHexString() {
    final buffer = StringBuffer();
    for (int square = 63; square >= 0; square--) {
      buffer.write(has(Square(square)) ? '1' : '0');
    }
    final b = buffer.toString();
    final firstPart = int.parse(b.substring(0, 32), radix: 2)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');
    final lastPart = int.parse(b.substring(32, 64), radix: 2)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');
    final stringVal = '$firstPart$lastPart';
    if (stringVal == '0000000000000000') {
      return '0';
    }
    return '0x$firstPart$lastPart';
  }
}

@pragma('vm:prefer-inline')
int _popcnt64(int n) {
  final count2 = n - ((n >>> 1) & 0x5555555555555555);
  final count4 =
      (count2 & 0x3333333333333333) + ((count2 >>> 2) & 0x3333333333333333);
  final count8 = (count4 + (count4 >>> 4)) & 0x0f0f0f0f0f0f0f0f;
  return (count8 * 0x0101010101010101) >>> 56;
}

@pragma('vm:prefer-inline')
int _nlz64(int x) {
  int r = x;
  r |= r >>> 1;
  r |= r >>> 2;
  r |= r >>> 4;
  r |= r >>> 8;
  r |= r >>> 16;
  r |= r >>> 32;
  return 64 - _popcnt64(r);
}

@pragma('vm:prefer-inline')
int _ntz64(int x) => _ntzLut64[(x & -x) % 131];
const _ntzLut64 = [
  64, 0, 1, -1, 2, 46, -1, -1, 3, 14, 47, 56, -1, 18, -1, //
  -1, 4, 43, 15, 35, 48, 38, 57, 23, -1, -1, 19, -1, -1, 51,
  -1, 29, 5, 63, 44, 12, 16, 41, 36, -1, 49, -1, 39, -1, 58,
  60, 24, -1, -1, 62, -1, -1, 20, 26, -1, -1, -1, -1, 52, -1,
  -1, -1, 30, -1, 6, -1, -1, -1, 45, -1, 13, 55, 17, -1, 42,
  34, 37, 22, -1, -1, 50, 28, -1, 11, 40, -1, -1, -1, 59,
  -1, 61, -1, 25, -1, -1, -1, -1, -1, -1, -1, -1, 54, -1,
  33, 21, -1, 27, 10, -1, -1, -1, -1, -1, -1, -1, -1, 53,
  32, -1, 9, -1, -1, -1, -1, 31, 8, -1, -1, 7, -1, -1,
];

class _SquareIterable extends Iterable<Square> {
  final int bits;
  const _SquareIterable(this.bits);

  @override
  Iterator<Square> get iterator => _SquareIterator(bits);
}

class _SquareIterator implements Iterator<Square> {
  int _bits;
  Square _current = const Square(0);

  _SquareIterator(this._bits);

  @override
  Square get current => _current;

  @override
  bool moveNext() {
    if (_bits == 0) return false;
    _current = Square(_ntz64(_bits));
    _bits &= _bits - 1; // Clear LSB
    return true;
  }
}

class _SquareReversedIterable extends Iterable<Square> {
  final int bits;
  const _SquareReversedIterable(this.bits);

  @override
  Iterator<Square> get iterator => _SquareReversedIterator(bits);
}

class _SquareReversedIterator implements Iterator<Square> {
  int _bits;
  Square _current = const Square(0);

  _SquareReversedIterator(this._bits);

  @override
  Square get current => _current;

  @override
  bool moveNext() {
    if (_bits == 0) return false;
    final int sq = 63 - _nlz64(_bits);
    _current = Square(sq);
    _bits ^= 1 << sq; // Clear MSB
    return true;
  }
}
