import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/view/mission_card.dart';

void main() {
  test('uses only context-relevant mystery preview icons', () {
    expect(
      mysteryPreviewIcon('A quiet riverside mangrove trail'),
      Icons.park_rounded,
    );
    expect(
      mysteryPreviewIcon('A family-run coffee and pastry stop'),
      Icons.restaurant_rounded,
    );
    expect(
      mysteryPreviewIcon('An atmospheric surprise with a local story'),
      Icons.explore_rounded,
    );
  });
}
