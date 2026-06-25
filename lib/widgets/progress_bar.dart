import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final Color color;

  const ProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.color = AppColors.ctaButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total > 0 ? current / total : 0,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          '$current / $total',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
