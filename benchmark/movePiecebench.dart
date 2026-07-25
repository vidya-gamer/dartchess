import 'package:dartchess/dartchess.dart';
// Adjust relative path if needed based on your package structure
//import '../lib/src/board.dart'; 

void main() {
  // 1. Setup initial state
  final Square from = Square.e2;
  final Square to = Square.e4;
  final Piece piece = Piece(role: Role.pawn, color: Side.white);
  final Piece? captured = null;

  // Initial board with a piece at 'from' (e2)
Board initialBoard = Board.standard;

  // Warmup run to let the JIT compiler optimize both paths
  _benchmarkRemoveAndSet(initialBoard, from, to, piece, 1000);
  _benchmarkMovePiece(initialBoard, from, to, piece, captured, 1000);

  const iterations = 10000000;

  // 2. Benchmark removePieceAt + setPieceAt
  final sw1 = Stopwatch()..start();
  _benchmarkRemoveAndSet(initialBoard, from, to, piece, iterations);
  sw1.stop();
  print('removePieceAt + setPieceAt : ${sw1.elapsedMilliseconds} ms');

  // 3. Benchmark movePiece
  final sw2 = Stopwatch()..start();
  _benchmarkMovePiece(initialBoard, from, to, piece, captured, iterations);
  sw2.stop();
  print('movePiece                  : ${sw2.elapsedMilliseconds} ms');
}

@pragma('vm:never-inline')
Board _benchmarkRemoveAndSet(Board start, Square from, Square to, Piece piece, int count) {
  Board b = start;
  for (int i = 0; i < count; i++) {
    // Alternating toggles prevent dead-code elimination & mirror move churn
    final src = (i % 2 == 0) ? from : to;
    final dst = (i % 2 == 0) ? to : from;
    b = b.removePieceAt(src).setPieceAt(dst, piece);
  }
  return b;
}

@pragma('vm:never-inline')
Board _benchmarkMovePiece(Board start, Square from, Square to, Piece piece, Piece? captured, int count) {
  Board b = start;
  for (int i = 0; i < count; i++) {
    final src = (i % 2 == 0) ? from : to;
    final dst = (i % 2 == 0) ? to : from;
    b = b.movePiece(src, dst, piece, captured);
  }
  return b;
}
