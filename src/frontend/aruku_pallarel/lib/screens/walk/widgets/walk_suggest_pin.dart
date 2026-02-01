import 'package:flutter/material.dart';

class WalkSuggestPin extends StatelessWidget {
  const WalkSuggestPin({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 色の定義
    const pinBaseColor = Color(0xFF2CFFBC);
    const pinSelectedColor = Color(0xFFAAFF4E);
    final pinColor = isSelected ? pinSelectedColor : pinBaseColor;
    // 影の色（選択時は少し強調）
    final shadowColor = isSelected 
        ? pinColor.withValues(alpha: 0.4) 
        : Colors.black.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0, // 選択時に少し大きく
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: CustomPaint(
            // ピンの描画ロジックを指定
            painter: _LogoPinPainter(
              color: pinColor,
              shadowColor: shadowColor,
            ),
            // ピンのサイズ（少し縦長にする）
            child: const SizedBox(
              width: 34,
              height: 44, 
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPinPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _LogoPinPainter({
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 影の描画設定
    final Paint shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final Path outerPath = _buildOuterPath(size);
    final Path holePath = _buildHolePath(size);

    // ピンの形状から穴の形状を「くり抜く」合成
    final Path finalPath = Path.combine(
      PathOperation.difference,
      outerPath,
      holePath,
    );

    // 1. 影を描画（少し下にずらす）
    canvas.drawPath(finalPath.shift(const Offset(0, 2)), shadowPaint);

    // 2. 本体を描画
    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant _LogoPinPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
  }

  Path _buildOuterPath(Size size) {
    final Path path = Path();

    final double w = size.width;
    final double h = size.height;

    // 円部分の半径（幅の半分）
    final double r = w / 2;

    // パスの開始点（下の尖った部分）
    path.moveTo(w / 2, h);

    // 左下の曲線 (ベジェ曲線)
    // 制御点(x1, y1)を経由して、円の左端(0, r)へ繋ぐ
    path.quadraticBezierTo(0, h * 0.65, 0, r);

    // 上部の円弧
    // 左端から上を通って右端(w, r)まで半円を描く
    path.arcToPoint(
      Offset(w, r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 右下の曲線
    // 円の右端から下の尖った部分へ戻る
    path.quadraticBezierTo(w, h * 0.65, w / 2, h);

    path.close();
    return path;
  }

  Path _buildHolePath(Size size) {
    final double w = size.width;
    final double r = w / 2;
    final double holeRadius = w * 0.18;
    return Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(w / 2, r), // 円部分の中心に穴を空ける
          radius: holeRadius,
        ),
      );
  }
}
