import 'package:flutter/foundation.dart';

import '../../model/clue_hint/mystery_clue.dart';

abstract interface class IClueHintFacade implements Listenable {
  MysteryClue get clue;
  bool get isLoading;
  String? get error;

  Future<void> recordViewed();
  Future<bool> revealHint();
  void dispose();
}
