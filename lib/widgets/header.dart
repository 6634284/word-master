import 'package:flutter/material.dart';
import '../constants/colors.dart';

class Header extends StatelessWidget {
  final String title;
  final bool showBack;
  const Header({super.key, required this.title, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.darkModeNotifier,
      builder: (context, _, __) {
        return Container(
          color: AppColors.background,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: showBack ? 8 : 24,
            right: 24,
            bottom: 12,
          ),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 20, color: AppColors.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
