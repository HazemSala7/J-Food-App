import 'package:flutter/material.dart';

class ColorManager {
  static Color primary = HexColor.fromHex('#00A592');
  static Color second = HexColor.fromHex('#051917');
  static Color blackBackGround = HexColor.fromHex('#121212');
  static Color labelColor = HexColor.fromHex('#DBF9F5');
  static Color cardColor = HexColor.fromHex('#10211F');
  static Color white = Colors.white;
  static Color black = Colors.black;
}

extension HexColor on Color {
  static Color fromHex(String hexColorString) {
    hexColorString = hexColorString.replaceAll('#', '');
    if (hexColorString.length == 6) {
      hexColorString = "FF$hexColorString";
    }
    return Color(int.parse(hexColorString, radix: 16));
  }
}
