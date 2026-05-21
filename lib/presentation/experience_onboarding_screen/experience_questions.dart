class ExperienceQuestionOption {
  final String id;
  final String title;
  final int score;

  const ExperienceQuestionOption({
    required this.id,
    required this.title,
    required this.score,
  });
}

class ExperienceQuestion {
  final String id;
  final String title;
  final int weight;
  final List<ExperienceQuestionOption> options;

  const ExperienceQuestion({
    required this.id,
    required this.title,
    required this.weight,
    required this.options,
  });
}

const List<ExperienceQuestion> kExperienceQuestions = [
  ExperienceQuestion(
    id: 'frequency',
    title: 'Dalam 12 bulan terakhir, berapa kali Anda mendaki?',
    weight: 25,
    options: [
      ExperienceQuestionOption(id: '0', title: '0 kali', score: 0),
      ExperienceQuestionOption(id: '1_2', title: '1-2 kali', score: 1),
      ExperienceQuestionOption(id: '3_5', title: '3-5 kali', score: 2),
      ExperienceQuestionOption(id: '6_9', title: '6-9 kali', score: 3),
      ExperienceQuestionOption(id: '10_plus', title: '10+ kali', score: 4),
    ],
  ),
  ExperienceQuestion(
    id: 'technical',
    title: 'Medan tersulit yang pernah Anda selesaikan sendiri?',
    weight: 20,
    options: [
      ExperienceQuestionOption(
        id: 'easy_tourist',
        title: 'Jalur wisata ringan',
        score: 0,
      ),
      ExperienceQuestionOption(
        id: 'standard_forest',
        title: 'Jalur hutan standar',
        score: 1,
      ),
      ExperienceQuestionOption(
        id: 'long_elevation',
        title: 'Jalur panjang dengan elevasi tinggi',
        score: 2,
      ),
      ExperienceQuestionOption(
        id: 'steep_exposed',
        title: 'Jalur curam atau berbatu dengan eksposur',
        score: 3,
      ),
      ExperienceQuestionOption(
        id: 'technical_scramble',
        title: 'Jalur teknikal dengan manajemen risiko',
        score: 4,
      ),
    ],
  ),
  ExperienceQuestion(
    id: 'navigation',
    title: 'Seberapa mandiri Anda dalam navigasi saat jalur tidak jelas?',
    weight: 15,
    options: [
      ExperienceQuestionOption(
        id: 'always_follow',
        title: 'Selalu ikut orang lain',
        score: 0,
      ),
      ExperienceQuestionOption(
        id: 'basic_marker',
        title: 'Bisa baca penanda dasar',
        score: 1,
      ),
      ExperienceQuestionOption(
        id: 'digital_map_signal',
        title: 'Bisa pakai peta digital jika ada sinyal',
        score: 2,
      ),
      ExperienceQuestionOption(
        id: 'offline_map_compass',
        title: 'Bisa pakai offline map dan kompas',
        score: 3,
      ),
      ExperienceQuestionOption(
        id: 'independent_orientation',
        title: 'Bisa orientasi mandiri dan ambil keputusan rute',
        score: 4,
      ),
    ],
  ),
  ExperienceQuestion(
    id: 'risk',
    title: 'Jika cuaca memburuk di tengah pendakian, keputusan Anda biasanya?',
    weight: 15,
    options: [
      ExperienceQuestionOption(
        id: 'keep_going',
        title: 'Tetap lanjut agar cepat summit',
        score: 0,
      ),
      ExperienceQuestionOption(
        id: 'wait_without_plan',
        title: 'Menunggu tanpa evaluasi jelas',
        score: 1,
      ),
      ExperienceQuestionOption(
        id: 'team_discussion',
        title: 'Diskusi dengan tim lalu lanjut jika memungkinkan',
        score: 2,
      ),
      ExperienceQuestionOption(
        id: 'objective_evaluation',
        title: 'Evaluasi objektif dan siap putar balik',
        score: 3,
      ),
      ExperienceQuestionOption(
        id: 'turnaround_rule',
        title: 'Konsisten menerapkan turnaround rule',
        score: 4,
      ),
    ],
  ),
  ExperienceQuestion(
    id: 'fitness',
    title:
        'Dalam 3 bulan terakhir, bagaimana kebugaran fisik Anda untuk aktivitas menanjak 45-90 menit?',
    weight: 25,
    options: [
      ExperienceQuestionOption(
        id: 'rare_exercise',
        title: 'Jarang olahraga, cepat lelah saat tanjakan ringan',
        score: 0,
      ),
      ExperienceQuestionOption(
        id: 'light_once_week',
        title: 'Olahraga ringan 1x per minggu',
        score: 1,
      ),
      ExperienceQuestionOption(
        id: 'regular_2_3',
        title: 'Olahraga rutin 2-3x per minggu',
        score: 2,
      ),
      ExperienceQuestionOption(
        id: 'regular_4_plus',
        title: 'Olahraga rutin 4x per minggu, kuat trek panjang',
        score: 3,
      ),
      ExperienceQuestionOption(
        id: 'endurance_trained',
        title: 'Terlatih endurance dan recovery baik',
        score: 4,
      ),
    ],
  ),
];
