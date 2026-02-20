import 'package:flutter/material.dart';

class ButtonWidget extends StatefulWidget {
  double height, width, BorderRaduis;
  Color BorderColor, ButtonColor, NameColor;
  String name;
  Function OnClickFunction;
  ButtonWidget({
    Key? key,
    required this.name,
    required this.height,
    required this.width,
    required this.BorderColor,
    required this.OnClickFunction,
    required this.BorderRaduis,
    required this.ButtonColor,
    required this.NameColor,
  }) : super(key: key);

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: () {
          widget.OnClickFunction();
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
              color: widget.ButtonColor,
              borderRadius: BorderRadius.circular(widget.BorderRaduis),
              border: Border.all(color: widget.BorderColor)),
          child: Center(
            child: Text(
              widget.name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: widget.NameColor),
            ),
          ),
        ),
      ),
    );
  }
}
