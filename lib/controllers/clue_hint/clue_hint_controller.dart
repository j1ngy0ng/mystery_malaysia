import 'package:flutter/foundation.dart';

import '../../models/clue_hint/mystery_clue.dart';

class ClueHintController extends ChangeNotifier {
  MysteryClue clue = const MysteryClue(
    number: 2,
    text:
        'I watch the city through petals of glass. At my feet, old stories and new skylines share the same reflection.',
    hint:
        'Look for a peaceful place of worship near a river confluence and a busy heritage district.',
  );

  void revealHint() {
    if (clue.hintRevealed) return;
    clue = clue.copyWith(hintRevealed: true);
    notifyListeners();
  }
}
