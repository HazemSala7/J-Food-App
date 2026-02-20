import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';


class ForwardButton extends StatelessWidget {
  final Function() onTap;
  ForwardButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        child: const RotatedBox(
          quarterTurns:  2,
          child: Icon(
            Ionicons.chevron_forward_outline,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
