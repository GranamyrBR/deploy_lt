import 'package:flutter/material.dart';
import 'dart:math' as dm;

double _luminance(Color c) {
  double channel(num v) {
    final n = v / 255.0;
    return n <= 0.03928 ? n / 12.92 : dm.pow((n + 0.055) / 1.055, 2.4).toDouble();
  }
  final r = channel((c.r * 255.0).round().clamp(0, 255));
  final g = channel((c.g * 255.0).round().clamp(0, 255));
  final b = channel((c.b * 255.0).round().clamp(0, 255));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
