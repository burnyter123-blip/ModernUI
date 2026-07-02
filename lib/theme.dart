import 'package:flutter/material.dart';

const double kDW = 2424;
const double kDH = 1080;

const bg = Color(0xFFF5F5F5);
const ink = Color(0xFF2B2B2D);
const pill = Color(0xFFF6F6F8);
const mutedInk = Color(0xFF8B8893);

const arcaderRed = Color(0xFFEC5032);
const redLight = Color(0xFFFF6B4A);
const redDark = Color(0xFFD63F29);

const glowCyan = redLight;
const glowBlue = arcaderRed;
const glowPurple = redDark;

const focusGradient = LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [redLight, arcaderRed, redDark],
);

const tileFillGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFDCDCDC), Color(0xFFCFCFCF)],
);
