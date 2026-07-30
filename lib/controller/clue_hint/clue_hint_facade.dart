import 'package:flutter/foundation.dart';

import 'clue_hint_controller.dart';
import 'clue_hint_facade_interface.dart';
import '../../model/clue_hint/mystery_clue.dart';

class ClueHintFacade extends ChangeNotifier implements IClueHintFacade {
  ClueHintFacade({MysteryClue? initialClue, String? sessionId})
    : _controller = ClueHintController(
        initialClue: initialClue,
        sessionId: sessionId,
      ) {
    _controller.addListener(notifyListeners);
  }

  final ClueHintController _controller;

  @override
  MysteryClue get clue => _controller.clue;
  @override
  bool get isLoading => _controller.isLoading;
  @override
  String? get error => _controller.error;

  @override
  Future<void> recordViewed() => _controller.recordViewed();
  @override
  Future<bool> revealHint() => _controller.revealHint();

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}
