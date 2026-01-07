import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/utils/contrast_utils.dart';

void main() {
  test('High contrast palette meets WCAG thresholds', () {
    final bg = Colors.black;
    final text = Colors.white;
    final ratio = contrastRatio(text, bg);
    expect(ratio >= 7.0, true);
  });

  test('PrimaryContainer vs onPrimaryContainer meets thresholds', () {
    final cs = const ColorScheme.light();
    final ratio = contrastRatio(cs.onPrimaryContainer, cs.primaryContainer);
    expect(ratio >= 4.5, true);
  });
}

