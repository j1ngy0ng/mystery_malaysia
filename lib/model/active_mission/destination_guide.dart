import '../clue_hint/mystery_clue.dart';

class DestinationGuide {
  const DestinationGuide({
    required this.name,
    required this.state,
    required this.city,
    required this.categories,
    required this.facts,
    required this.visitorInformation,
    required this.accessibility,
    this.weeklyHours = const [],
    this.culturalEtiquette = const [],
    this.safetyNotes = const [],
    this.educationalSources = const [],
    this.formattedAddress,
    this.primaryType,
    this.googleRating,
    this.googleUserRatingCount,
    this.googleMapsUri,
    this.openNow,
    this.safetyScore,
    this.educationalSource,
    this.summaryDisclosure,
    this.imageUrl,
    this.photoAttributions = const [],
  });

  final String name;
  final String state;
  final String city;
  final List<String> categories;
  final List<String> facts;
  final Map<String, dynamic> visitorInformation;
  final Map<String, dynamic> accessibility;
  final List<String> weeklyHours;
  final List<String> culturalEtiquette;
  final List<String> safetyNotes;
  final List<GuideSource> educationalSources;
  final String? formattedAddress;
  final String? primaryType;
  final double? googleRating;
  final int? googleUserRatingCount;
  final String? googleMapsUri;
  final bool? openNow;
  final double? safetyScore;
  final String? educationalSource;
  final String? summaryDisclosure;
  final String? imageUrl;
  final List<String> photoAttributions;

  factory DestinationGuide.fromJson(Map<String, dynamic> json) {
    final openingHours = _map(json['opening_hours']);
    final visitorInformation = _map(json['visitor_information']);
    final culturalEtiquette = _strings(
      visitorInformation['cultural_etiquette'],
    );
    final safetyNotes = _strings(visitorInformation['safety_notes']);
    return DestinationGuide(
      name: json['name'] as String,
      state: json['state'] as String? ?? 'Malaysia',
      city: json['city'] as String? ?? '',
      categories: _strings(json['categories']),
      facts: _strings(json['facts']),
      visitorInformation: visitorInformation,
      accessibility: _map(json['accessibility']),
      weeklyHours: _strings(openingHours['weekdayDescriptions']),
      culturalEtiquette: culturalEtiquette.isEmpty
          ? const [
              'Follow posted rules and ask before photographing people.',
              'Respect staff, residents, worshippers and other visitors.',
            ]
          : culturalEtiquette,
      safetyNotes: safetyNotes.isEmpty
          ? const [
              'Visit during published hours and follow current site notices.',
              'Keep valuables secure and remain in public visitor areas.',
              'Automated suitability checks do not guarantee personal safety.',
            ]
          : safetyNotes,
      educationalSources: _sources(visitorInformation['educational_sources']),
      formattedAddress: json['formatted_address'] as String?,
      primaryType: json['primary_type'] as String?,
      googleRating: (json['google_rating'] as num?)?.toDouble(),
      googleUserRatingCount: (json['google_user_rating_count'] as num?)
          ?.round(),
      googleMapsUri: json['google_maps_uri'] as String?,
      openNow: openingHours['openNow'] as bool?,
      safetyScore: (json['safety_score'] as num?)?.toDouble(),
      educationalSource: visitorInformation['educational_source'] as String?,
      summaryDisclosure: visitorInformation['summary_disclosure'] as String?,
      imageUrl: visitorInformation['image_url'] as String?,
      photoAttributions: _attributions(
        visitorInformation['photo_attributions'],
      ),
    );
  }

  String get learningSummary {
    if (facts.isNotEmpty) return facts.first;
    final type = (primaryType ?? categories.firstOrNull ?? 'local attraction')
        .replaceAll('_', ' ');
    return '$name is a $type in ${city.isEmpty ? state : city}. '
        'Take time to notice the local setting, design and community around it.';
  }

  List<String> get visitorNotes {
    final notes = <String>[
      ?formattedAddress,
      ...visitorInformation.entries
          .where(
            (entry) =>
                entry.value != null &&
                !{
                  'formatted_address',
                  'verification',
                  'cultural_etiquette',
                  'safety_notes',
                  'educational_source',
                  'educational_sources',
                  'summary_disclosure',
                  'photo_name',
                  'photo_attributions',
                  'image_url',
                }.contains(entry.key),
          )
          .where((entry) => entry.value is String || entry.value is num)
          .map((entry) => '${_label(entry.key)}: ${entry.value}'),
    ].where((note) => note.isNotEmpty);
    return notes.toSet().toList(growable: false);
  }

  List<String> get accessibilityNotes => accessibility.entries
      .where((entry) => entry.value == true)
      .map((entry) => _label(entry.key))
      .toList(growable: false);

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static List<String> _strings(dynamic value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  static List<GuideSource> _sources(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((source) => GuideSource.fromJson(Map.from(source)))
            .where((source) => source.uri.isNotEmpty)
            .toList(growable: false)
      : const [];

  static List<String> _attributions(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => item['displayName'] as String?)
            .whereType<String>()
            .toList(growable: false)
      : const [];

  static String _label(String value) {
    final spaced = value
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceAll('_', ' ');
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}

class GuideSource {
  const GuideSource({required this.title, required this.uri});

  final String title;
  final String uri;

  factory GuideSource.fromJson(Map<dynamic, dynamic> json) => GuideSource(
    title: json['title'] as String? ?? 'Source',
    uri: json['uri'] as String? ?? '',
  );
}

class ArrivalResult {
  const ArrivalResult({
    required this.arrived,
    required this.message,
    this.guide,
    this.missionCompleted = false,
    this.waitingForMembers = false,
    this.completedStage,
    this.nextStage,
    this.totalStages,
    this.nextClue,
  });

  final bool arrived;
  final String message;
  final DestinationGuide? guide;
  final bool missionCompleted;
  final bool waitingForMembers;
  final int? completedStage;
  final int? nextStage;
  final int? totalStages;
  final MysteryClue? nextClue;

  factory ArrivalResult.fromJson(Map<String, dynamic> json) {
    final destination = json['destination'];
    final clue = json['next_clue'];
    return ArrivalResult(
      arrived: json['arrived'] == true,
      message: json['message'] as String? ?? '',
      guide: destination is Map
          ? DestinationGuide.fromJson(Map<String, dynamic>.from(destination))
          : null,
      missionCompleted: json['mission_completed'] == true,
      waitingForMembers: json['waiting_for_members'] == true,
      completedStage: (json['completed_stage'] as num?)?.round(),
      nextStage: (json['next_stage'] as num?)?.round(),
      totalStages: (json['total_stages'] as num?)?.round(),
      nextClue: clue is Map
          ? MysteryClue(
              number: (clue['number'] as num).round(),
              text: clue['text'] as String,
              hint: clue['hint'] as String? ?? '',
            )
          : null,
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
