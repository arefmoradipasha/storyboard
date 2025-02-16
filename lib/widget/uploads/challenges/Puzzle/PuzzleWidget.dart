import 'package:flutter/material.dart';

class PuzzleBottomSheet extends StatefulWidget {
  const PuzzleBottomSheet({Key? key}) : super(key: key);

  @override
  _PuzzleBottomSheetState createState() => _PuzzleBottomSheetState();
}

class _PuzzleBottomSheetState extends State<PuzzleBottomSheet> {
  int? _selectedPieceIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "پازل",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // نمایش قطعات پازل در Row و Column
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPuzzlePiece(0),
                  _buildPuzzlePiece(1),
                  _buildPuzzlePiece(2),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPuzzlePiece(3),
                  _buildPuzzlePiece(4),
                  _buildPuzzlePiece(5),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzlePiece(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPieceIndex = index;
        });
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: PuzzlePainter(index: index),
        ),
      ),
    );
  }
}

class PuzzlePainter extends CustomPainter {
  final int index;

  PuzzlePainter({required this.index});

  @override
  void paint(Canvas canvas, Size size) {
    double s = size.width;
    double knob = 20; // اندازه برجستگی یا فرورفتگی
    Paint paint = Paint()
      ..color = _getPieceColor(index)
      ..style = PaintingStyle.fill;

    Path path = Path();

    // رسم لبه‌های منحنی برای تو رفتگی و برجستگی
    path.moveTo(0, 0);

    // لبه بالا
    if (index == 0) {
      path.lineTo(s - knob, 0);
      path.quadraticBezierTo(s, 0, s, knob); // برجستگی بالا سمت راست
    } else if (index == 1) {
      path.lineTo(s, 0); // ساده
    } else {
      path.lineTo(s - knob, 0);
      path.quadraticBezierTo(s, 0, s, knob); // تو رفتگی بالا سمت راست
    }

    // لبه راست
    if (index == 2 || index == 3) {
      path.lineTo(s, s - knob);
      path.quadraticBezierTo(s, s, s - knob, s); // برجستگی پایین سمت راست
    } else {
      path.lineTo(s, s);
    }

    // لبه پایین
    if (index == 4) {
      path.lineTo(knob, s);
      path.quadraticBezierTo(0, s, 0, s - knob); // تو رفتگی پایین سمت چپ
    } else if (index == 5) {
      path.lineTo(s, s); // ساده
    } else {
      path.lineTo(0, s);
    }

    // لبه چپ
    if (index == 3 || index == 4) {
      path.lineTo(0, knob);
      path.quadraticBezierTo(0, 0, knob, 0); // برجستگی بالا سمت چپ
    } else {
      path.lineTo(0, 0);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  Color _getPieceColor(int index) {
    switch (index % 6) {
      case 0:
        return Colors.redAccent;
      case 1:
        return Colors.blueAccent;
      case 2:
        return Colors.greenAccent;
      case 3:
        return Colors.orangeAccent;
      case 4:
        return Colors.purpleAccent;
      case 5:
        return Colors.yellowAccent;
      default:
        return Colors.white;
    }
  }
}
