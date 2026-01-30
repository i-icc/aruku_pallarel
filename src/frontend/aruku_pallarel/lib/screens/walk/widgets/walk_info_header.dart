import 'package:flutter/material.dart';

class WalkInfoHeader extends StatelessWidget {
  const WalkInfoHeader({
    super.key,
    required this.distanceKm,
    required this.elapsedMinutes,
  });

  final double? distanceKm;
  final int? elapsedMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme.titleMedium;
    final scaledFontSize =
        (baseTextStyle?.fontSize != null ? baseTextStyle!.fontSize! * 1.2 : 19.0);
    const iconColor = Colors.grey;
    final distanceText =
        distanceKm == null ? '-- km' : '${distanceKm!.toStringAsFixed(1)}km';
    final minutesText =
        elapsedMinutes == null ? '--分' : '${elapsedMinutes!.toString()}分';

    return Align(
      alignment: Alignment.topCenter,
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_walk,
                      color: iconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      distanceText,
                      style: baseTextStyle?.copyWith(
                            fontSize: scaledFontSize,
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            fontSize: scaledFontSize,
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: iconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      minutesText,
                      style: baseTextStyle?.copyWith(
                            fontSize: scaledFontSize,
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            fontSize: scaledFontSize,
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
