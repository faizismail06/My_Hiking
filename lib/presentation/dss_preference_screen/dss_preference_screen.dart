import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhiking/api/api_service.dart';

// ─── Persistence helper ──────────────────────────────────────────────────────

/// Thin wrapper around SharedPreferences for DSS slider values.
///
/// Keys are namespaced under `dss_pref_` so they never collide with other
/// SharedPreferences keys in the app.
class _DssPrefsStorage {
  static const String _namespace = 'dss_pref_';

  /// Load all saved slider values. Returns an empty map if nothing is saved.
  static Future<Map<String, double>> load(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, double>{};
    for (final key in keys) {
      final saved = prefs.getDouble('$_namespace$key');
      if (saved != null) result[key] = saved;
    }
    return result;
  }

  /// Persist the current slider values.
  static Future<void> save(Map<String, double> values) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in values.entries) {
      await prefs.setDouble('$_namespace${entry.key}', entry.value);
    }
  }

  /// Remove all saved DSS preference keys (used on reset).
  static Future<void> clear(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in keys) {
      await prefs.remove('$_namespace$key');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Screen where users set their hiking priorities before requesting recommendations.
///
/// Each slider maps to a backend priority weight key.
/// Sliders range from 1 (tidak penting) to 5 (sangat penting).
/// Default value is 3 (netral) for every criterion.
///
/// Slider values are **persisted** via SharedPreferences so the user's last
/// selection is restored on the next visit instead of resetting to neutral.
///
/// Flow:
///   Home → DssPreferenceScreen → navigates back with Map<String, double>
///   HomeInitialPage reads the result and calls fetchRecommendations(weights: ...).
class DssPreferenceScreen extends StatefulWidget {
  const DssPreferenceScreen({super.key});

  @override
  State<DssPreferenceScreen> createState() => _DssPreferenceScreenState();
}

/// Definition of a single preference slider item.
class _PrefItem {
  final String weightKey;      // backend query param key
  final String question;       // shown above the slider
  final String lowLabel;       // label at value = 1
  final String highLabel;      // label at value = 5
  final IconData icon;
  final CriteriaType type;     // 'cost' or 'benefit'

  const _PrefItem({
    required this.weightKey,
    required this.question,
    required this.lowLabel,
    required this.highLabel,
    required this.icon,
    required this.type,
  });
}

/// Enum untuk tipe kriteria
enum CriteriaType {
  cost,      // semakin rendah semakin baik (biaya, jarak, durasi, dll)
  benefit,   // semakin tinggi semakin baik (panorama, fasilitas, keamanan, dll)
}

class _DssPreferenceScreenState extends State<DssPreferenceScreen>
    with SingleTickerProviderStateMixin {
  // ─── Slider definitions ───────────────────────────────────────────────────

  static const List<_PrefItem> _items = [
    // ─── COST CRITERIA (semakin rendah semakin baik) ─────────────────────
    _PrefItem(
      weightKey: 'priority_cost',
      question: 'Seberapa penting biaya perjalanan?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.payments_outlined,
      type: CriteriaType.cost,
    ),
    _PrefItem(
      weightKey: 'priority_distance',
      question: 'Seberapa penting jarak tempuh?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.straighten_outlined,
      type: CriteriaType.cost,
    ),
    _PrefItem(
      weightKey: 'priority_duration',
      question: 'Seberapa penting durasi pendakian?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.timer_outlined,
      type: CriteriaType.cost,
    ),
    _PrefItem(
      weightKey: 'priority_difficulty',
      question: 'Seberapa penting tingkat kesulitan jalur?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.terrain_outlined,
      type: CriteriaType.cost,
    ),
    _PrefItem(
      weightKey: 'priority_elevation',
      question: 'Seberapa penting ketinggian / elevasi jalur?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.height_outlined,
      type: CriteriaType.cost,
    ),
    // ─── BENEFIT CRITERIA (semakin tinggi semakin baik) ─────────────────
    _PrefItem(
      weightKey: 'priority_panorama',
      question: 'Seberapa penting panorama / pemandangan?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.landscape_outlined,
      type: CriteriaType.benefit,
    ),
    _PrefItem(
      weightKey: 'priority_fasilitas',
      question: 'Seberapa penting fasilitas di jalur?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.cabin_outlined,
      type: CriteriaType.benefit,
    ),
    _PrefItem(
      weightKey: 'priority_crowd_level',
      question: 'Seberapa penting tingkat keramaian jalur?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.people_outline,
      type: CriteriaType.benefit,
    ),
    _PrefItem(
      weightKey: 'priority_popularity',
      question: 'Seberapa penting popularitas jalur?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.trending_up_outlined,
      type: CriteriaType.benefit,
    ),
    _PrefItem(
      weightKey: 'priority_safety',
      question: 'Seberapa penting keamanan jalur?',
      lowLabel: 'Tak peduli',
      highLabel: 'Sangat penting',
      icon: Icons.shield_outlined,
      type: CriteriaType.benefit,
    ),
  ];

  // ─── State ────────────────────────────────────────────────────────────────

  /// Slider values keyed by weightKey. Default = 3 (equal / neutral).
  late Map<String, double> _values;

  /// True while loading saved preferences from SharedPreferences.
  bool _isLoading = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final ApiService _apiService;

  static const double _defaultValue = 3;
  static const Color _primary = Color(0xFF127857);
  static const Color _primaryLight = Color(0xFFE8F5EE);

  @override
  void initState() {
    super.initState();

    // Initialise with defaults first so the UI has something to render.
    _values = {for (final item in _items) item.weightKey: _defaultValue};

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _apiService = ApiService();

    // Load persisted preferences and then start the fade-in animation.
    _loadSavedPrefs();
  }

  /// Loads persisted slider values from SharedPreferences.
  /// Falls back to default (3.0) for any key that has no saved value.
  Future<void> _loadSavedPrefs() async {
    final keys = _items.map((e) => e.weightKey).toList();
    final saved = await _DssPrefsStorage.load(keys);

    if (!mounted) return;

    setState(() {
      for (final item in _items) {
        _values[item.weightKey] = saved[item.weightKey] ?? _defaultValue;
      }
      _isLoading = false;
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Converts the integer slider value (1–5) into a descriptive label.
  String _valueLabel(double v) {
    switch (v.round()) {
      case 1:
        return 'Tidak penting';
      case 2:
        return 'Kurang penting';
      case 3:
        return 'Netral';
      case 4:
        return 'Penting';
      default:
        return 'Sangat penting';
    }
  }

  /// Returns true only if all sliders are still at the default value,
  /// so we know whether the user actually customised anything.
  bool get _isAllDefault =>
      _values.values.every((v) => v == _defaultValue);

  Future<void> _reset() async {
    setState(() {
      for (final key in _values.keys) {
        _values[key] = _defaultValue;
      }
    });

    // Erase persisted data so next open also starts neutral.
    await _DssPrefsStorage.clear(_items.map((e) => e.weightKey).toList());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferensi direset ke nilai awal'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    // Persist current values before leaving the screen.
    await _DssPrefsStorage.save(_values);

    // Only return keys where the user actually deviated from the default.
    // Sending all-equal weights (all = 3.0) is mathematically identical to
    // sending no weights — the backend normalises them to 1/n either way.
    // By stripping default-value keys we make the backend's `weights_applied`
    // flag meaningful AND ensure ranking visibly changes when sliders are moved.
    final customised = Map<String, double>.fromEntries(
      _values.entries.where((e) => e.value != _defaultValue),
    );

    if (!mounted) return;

    // Async sync to backend (non-blocking, doesn't delay return to previous screen)
    _apiService.saveDssPreferences(_values).catchError((e) {
      print('DSS preferences backend sync error: $e');
    });

    Navigator.of(context).pop(customised);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primary,
                strokeWidth: 2.5,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // ── "Tersimpan" chip — shown when prefs differ from default ──
                  if (!_isAllDefault) _buildSavedBanner(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildSectionHeader(
                          'Kriteria Efisiensi',
                          'Semakin tinggi, semakin cari yang MURAH, DEKAT, dan CEPAT',
                          CriteriaType.cost,
                        ),
                        const SizedBox(height: 12),
                        ..._items
                            .where((item) => item.type == CriteriaType.cost)
                            .map(_buildSliderCard),
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          'Kriteria Kualitas',
                          'Semakin tinggi, semakin cari yang LEBIH BAGUS',
                          CriteriaType.benefit,
                        ),
                        const SizedBox(height: 12),
                        ..._items
                            .where((item) => item.type == CriteriaType.benefit)
                            .map(_buildSliderCard),
                        const SizedBox(height: 8),
                        _buildResetButton(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  _buildSubmitBar(),
                ],
              ),
            ),
    );
  }

  // ─── Saved banner ─────────────────────────────────────────────────────────
  /// Small top banner indicating that the displayed values are the user's
  /// last-saved preferences (not the app defaults).
  Widget _buildSavedBanner() {
    return Container(
      width: double.infinity,
      color: _primary.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.bookmark_rounded, color: _primary, size: 15),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Menampilkan preferensi terakhir Anda',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                color: _primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header dengan Info Button ──────────────────────────────────

  Widget _buildSectionHeader(
    String title,
    String description,
    CriteriaType type,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _showCriteriaExplanation(type),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primary.withOpacity(0.15),
              border: Border.all(color: _primary.withOpacity(0.3), width: 1.5),
            ),
            child: const Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tampilkan dialog penjelasan tentang cost vs benefit criteria
  void _showCriteriaExplanation(CriteriaType type) {
    showDialog(
      context: context,
      builder: (context) {
        if (type == CriteriaType.cost) {
          return _buildCostExplanationDialog();
        } else {
          return _buildBenefitExplanationDialog();
        }
      },
    );
  }

  /// Dialog untuk menjelaskan COST criteria
  Widget _buildCostExplanationDialog() {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outlined, color: Color(0xFF127857)),
          SizedBox(width: 8),
          Text(
            'Kriteria Efisiensi',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF127857).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Semakin tinggi slider, semakin sistem cari jalur yang HEMAT dan PRAKTIS',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF127857),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            'Biaya',
            'Slider tinggi = cari rute yang MURAH, Slider rendah = abaikan harga',
          ),
          const SizedBox(height: 12),
          _buildExplanationItem(
            'Jarak',
            'Slider tinggi = cari rute yang DEKAT, Slider rendah = abaikan jarak jauh',
          ),
          const SizedBox(height: 12),
          _buildExplanationItem(
            'Durasi',
            'Slider tinggi = cari rute yang CEPAT, Slider rendah = abaikan waktu lama',
          ),
          const SizedBox(height: 12),
          _buildExplanationItem(
            'Kesulitan',
            'Slider tinggi = cari rute yang GAMPANG, Slider rendah = boleh rute sulit',
          ),
          const SizedBox(height: 12),
          _buildExplanationItem(
            'Elevasi',
            'Slider tinggi = cari rute dengan ketinggian RENDAH, Slider rendah = boleh tinggi',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text(
            'Mengerti',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Color(0xFF127857),
            ),
          ),
        ),
      ],
    );
  }

  /// Dialog untuk menjelaskan BENEFIT criteria
  Widget _buildBenefitExplanationDialog() {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outlined, color: Color(0xFF127857)),
          SizedBox(width: 8),
          Text(
            'Kriteria Kualitas',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF127857).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Semakin tinggi slider, semakin sistem cari jalur dengan kualitas TERBAIK',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF127857),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            'Panorama',
            'Slider tinggi = cari rute dengan pemandangan BAGUS, Slider rendah = abaikan keindahan',
          ),
          const SizedBox(height: 12),
          _buildExplanationItem(
            'Fasilitas',
            'Slider tinggi = cari rute dengan fasilitas LENGKAP, Slider rendah = abaikan fasilitas',
          ),
          const SizedBox(height: 12),
          _buildExplanationItem(
            'Keramaian',
            'Slider tinggi = cari rute yang SEPI, Slider rendah = tidak masalah ramai',
          ),
          const SizedBox(height: 12),
          _buildExplanationItem(
            'Popularitas',
            'Slider tinggi = cari rute yang POPULER/terkenal, Slider rendah = boleh yang jarang',
          ),
          const SizedBox(height: 12),
          _buildExplanationItem(
            'Keamanan',
            'Slider tinggi = cari rute yang AMAN, Slider rendah = abaikan risiko',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text(
            'Mengerti',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Color(0xFF127857),
            ),
          ),
        ),
      ],
    );
  }

  /// Helper untuk membuat satu item penjelasan
  Widget _buildExplanationItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF127857),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Atur Preferensi Pendakian',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: Colors.white,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Lewati',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header section ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF127857), Color(0xFF0A4F39)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesuaikan kriteria rekomendasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Preferensi Anda disimpan otomatis.\nJalur terbaik akan dihitung secara otomatis.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Slider Card ──────────────────────────────────────────────────────────

  Widget _buildSliderCard(_PrefItem item) {
    final value = _values[item.weightKey]!;
    final isCustomised = value != _defaultValue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCustomised ? _primary.withOpacity(0.35) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Question
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.question,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Value badge
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          key: ValueKey(value.round()),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _valueColor(value).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _valueLabel(value),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _valueColor(value),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _primary,
                inactiveTrackColor: const Color(0xFFD9EBE3),
                thumbColor: _primary,
                overlayColor: _primary.withOpacity(0.12),
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 18),
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                value: value,
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) {
                  setState(() => _values[item.weightKey] = v);
                },
              ),
            ),

            // Low / high labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.lowLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      color: Colors.grey[500],
                    ),
                  ),
                  // Dot indicators
                  Row(
                    children: List.generate(5, (i) {
                      final filled = (i + 1) <= value.round();
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: filled ? 7 : 5,
                        height: filled ? 7 : 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? _primary
                              : Colors.grey.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                  Text(
                    item.highLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Maps slider value 1-5 to a colour from grey → green.
  Color _valueColor(double value) {
    if (value <= 1) return Colors.grey;
    if (value <= 2) return Colors.blueGrey;
    if (value <= 3) return const Color(0xFF2E7D32);
    if (value <= 4) return _primary;
    return const Color(0xFF064E3A);
  }

  // ─── Reset button ─────────────────────────────────────────────────────────

  Widget _buildResetButton() {
    return Center(
      child: AnimatedOpacity(
        opacity: _isAllDefault ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: TextButton.icon(
          onPressed: _isAllDefault ? null : _reset,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text(
            'Reset ke nilai awal',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
          ),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
        ),
      ),
    );
  }

  // ─── Submit bar ───────────────────────────────────────────────────────────

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Tampilkan Rekomendasi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
