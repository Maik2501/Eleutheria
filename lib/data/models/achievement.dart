/// Static achievement definitions.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.symbol,
    required this.category,
  });

  final String id;
  final String title;
  final String description;

  /// Symbol used for the wax seal — e.g. 'Σ', 'Ω', '∴'.
  final String symbol;
  final AchievementCategory category;
}

enum AchievementCategory { milestone, mastery, streak, social, hidden }

/// All achievements that can be unlocked.
const kAchievements = <Achievement>[
  Achievement(
    id: 'first_steps',
    title: 'Erste Schritte',
    description: 'Spiele dein erstes Quiz.',
    symbol: 'I',
    category: AchievementCategory.milestone,
  ),
  Achievement(
    id: 'sokrates_student',
    title: 'Schüler des Sokrates',
    description: 'Beantworte 10 Fragen richtig.',
    symbol: 'Σ',
    category: AchievementCategory.milestone,
  ),
  Achievement(
    id: 'platos_apprentice',
    title: 'Platons Geselle',
    description: '50 richtige Antworten gesammelt.',
    symbol: 'Π',
    category: AchievementCategory.milestone,
  ),
  Achievement(
    id: 'aristoteles_logician',
    title: 'Aristoteles\' Logiker',
    description: '100 richtige Antworten.',
    symbol: 'A',
    category: AchievementCategory.milestone,
  ),
  Achievement(
    id: 'streak_3',
    title: 'Kontinuität',
    description: 'Drei Tage in Folge gespielt.',
    symbol: '☼',
    category: AchievementCategory.streak,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Wöchentliche Disziplin',
    description: 'Sieben Tage in Folge gespielt.',
    symbol: '✦',
    category: AchievementCategory.streak,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Stoische Beharrlichkeit',
    description: 'Dreißig Tage in Folge gespielt.',
    symbol: '⚜',
    category: AchievementCategory.streak,
  ),
  Achievement(
    id: 'flawless_classic',
    title: 'Tabula Perfecta',
    description: 'Klassisches Quiz ohne Fehler abschließen.',
    symbol: '✪',
    category: AchievementCategory.mastery,
  ),
  Achievement(
    id: 'sudden_death_10',
    title: 'Phönix',
    description: '10 Fragen am Stück im Sudden Death.',
    symbol: 'Φ',
    category: AchievementCategory.mastery,
  ),
  Achievement(
    id: 'sudden_death_25',
    title: 'Unbeirrbar',
    description: '25 Fragen am Stück im Sudden Death.',
    symbol: 'Ψ',
    category: AchievementCategory.mastery,
  ),
  Achievement(
    id: 'speed_demon',
    title: 'Schnelldenker',
    description: 'Beantworte zehn Fragen in unter drei Sekunden korrekt.',
    symbol: '⚡',
    category: AchievementCategory.mastery,
  ),
  Achievement(
    id: 'first_duel_won',
    title: 'Erster Sieg',
    description: 'Gewinne dein erstes Duell.',
    symbol: '⚔',
    category: AchievementCategory.social,
  ),
  Achievement(
    id: 'duel_streak_5',
    title: 'Eristik',
    description: 'Gewinne fünf Duelle in Folge.',
    symbol: '✠',
    category: AchievementCategory.social,
  ),
  Achievement(
    id: 'all_eras',
    title: 'Reise durch die Zeit',
    description: 'Beantworte richtige Fragen aus allen Epochen.',
    symbol: '⌛',
    category: AchievementCategory.mastery,
  ),
  Achievement(
    id: 'midnight_thinker',
    title: 'Nachtwanderer',
    description: 'Spiele zwischen 0 und 4 Uhr morgens.',
    symbol: '☾',
    category: AchievementCategory.hidden,
  ),
];
