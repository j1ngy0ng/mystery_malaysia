class MysteryClue {
  const MysteryClue({
    required this.number,
    required this.text,
    required this.hint,
    this.hintRevealed = false,
  });

  final int number;
  final String text;
  final String hint;
  final bool hintRevealed;

  MysteryClue copyWith({bool? hintRevealed}) {
    return MysteryClue(
      number: number,
      text: text,
      hint: hint,
      hintRevealed: hintRevealed ?? this.hintRevealed,
    );
  }
}
