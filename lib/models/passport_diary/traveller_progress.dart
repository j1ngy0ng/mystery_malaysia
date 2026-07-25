class PassportStamp {
  const PassportStamp({
    required this.place,
    required this.state,
    required this.emoji,
    required this.earned,
  });

  final String place;
  final String state;
  final String emoji;
  final bool earned;
}

class Achievement {
  const Achievement({
    required this.name,
    required this.description,
    required this.emoji,
  });

  final String name;
  final String description;
  final String emoji;
}

class DiaryMemory {
  const DiaryMemory({
    required this.title,
    required this.date,
    required this.summary,
    required this.emoji,
  });

  final String title;
  final String date;
  final String summary;
  final String emoji;
}
