import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';

class NumberPicker extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<int> options;
  final int currentValue;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  const NumberPicker({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.currentValue,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<NumberPicker> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  late int selected;
  String customValue = '';

  @override
  void initState() {
    super.initState();
    selected = widget.currentValue;
  }

  void _handleConfirm() {
    if (customValue.isNotEmpty) {
      final num = int.tryParse(customValue);
      if (num == null || num < 1) {
        _showAlert(AppStrings.validNumber);
        return;
      }
      if (num > 1000) {
        _showAlert(AppStrings.maxCount);
        return;
      }
      widget.onSelect(num);
    } else {
      widget.onSelect(selected);
    }
    widget.onClose();
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.hint),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface)),
            const SizedBox(height: 4),
            Text(widget.subtitle,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.outline)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.options.map((count) {
                final isActive = selected == count && customValue.isEmpty;
                return GestureDetector(
                  onTap: () => setState(() {
                    selected = count;
                    customValue = '';
                  }),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.surfaceLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.surfaceContainerHighest,
                      ),
                      boxShadow: isActive
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(AppStrings.customCount,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant)),
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: AppStrings.enterCustomCount,
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (text) => setState(() {
                customValue = text;
                if (text.isNotEmpty) selected = 0;
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onClose,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLow,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(AppStrings.cancel,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      shadowColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    child: const Text(AppStrings.confirm,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
