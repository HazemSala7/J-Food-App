import 'package:flutter/material.dart';

class RoundedCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Color borderColor;
  final double borderRadius;
  final Color activeColor;
  final Color checkColor;
  RoundedCheckbox({
    required this.value,
    required this.onChanged,
    this.borderColor = Colors.grey,
    this.borderRadius = 8.0,
    this.activeColor = Colors.green,
    required this.checkColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? activeColor : Colors.transparent,
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: value
            ? Icon(
                Icons.check,
                size: 20,
                color: checkColor,
              )
            : null,
      ),
    );
  }
}
