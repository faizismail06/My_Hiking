import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../api/api_service.dart';
import 'models/homelist_item_model.dart';
import 'widgets/weather_item_widget.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<HomelistItemModel> _mountains = [];

  @override
  void initState() {
    super.initState();
    _fetchMountains();
  }

  Future<void> _fetchMountains() async {
    try {
      final payload = await _apiService.fetchHomeFeedFromServer();
      final List<dynamic> mountainsData = payload['mountains'] ?? [];
      final List<HomelistItemModel> parsedMountains = mountainsData
          .map((data) => HomelistItemModel.fromJson(data as Map<String, dynamic>))
          .toList();

      final recommendedData = payload['recommended'];
      if (recommendedData != null && recommendedData['mountain'] != null) {
        final recommended = HomelistItemModel.fromJson(recommendedData['mountain'] as Map<String, dynamic>);
        parsedMountains.insert(0, recommended);
      }

      if (mounted) {
        setState(() {
          _mountains = parsedMountains;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/backgroundcuaca.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Dark theme base replaced by image
        body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81B59C)),
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildAppBar(context),
                _mountains.isEmpty
                    ? SliverFillRemaining(
                        child: const Center(
                          child: Text('Tidak ada data gunung.', style: TextStyle(color: Colors.white)),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _mountains[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: WeatherItemWidget(mountain: item),
                              );
                            },
                            childCount: _mountains.length,
                          ),
                        ),
                      ),
              ],
            ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent, // Greenish appbar replaced by transparent
      pinned: true,
      elevation: 0,
      expandedHeight: 65.h,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/headercuaca.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.h),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "CUACA GUNUNG INDONESIA",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.fSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            "Pemandu Cuaca Pendakian",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.fSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.white, size: 22.h),
          onPressed: () {
            if (_mountains.isEmpty) return;
            showSearch(
              context: context,
              delegate: _MountainWeatherSearchDelegate(_mountains),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.filter_alt_outlined, color: Colors.white, size: 22.h),
          onPressed: () {},
        ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }
}

class _MountainWeatherSearchDelegate extends SearchDelegate<HomelistItemModel?> {
  _MountainWeatherSearchDelegate(this._mountains);

  final List<HomelistItemModel> _mountains;

  @override
  String get searchFieldLabel => 'Cari item';

  @override
  TextStyle get searchFieldStyle => const TextStyle(color: Colors.black87);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final baseTheme = Theme.of(context);
    return baseTheme.copyWith(
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black54),
        titleTextStyle: const TextStyle(color: Colors.black87),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filterMountains(query);
    return _buildResultsList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = _filterMountains(query);
    return _buildResultsList(results);
  }

  List<HomelistItemModel> _filterMountains(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return _mountains;
    return _mountains.where((item) {
      final name = (item.namaGunung ?? '').toLowerCase();
      final location = (item.province?.name ?? '').toLowerCase();
      return name.contains(normalized) || location.contains(normalized);
    }).toList();
  }

  Widget _buildResultsList(List<HomelistItemModel> results) {
    if (results.isEmpty) {
      return const Center(
        child: Text('Tidak ada hasil.', style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
      itemCount: results.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        return WeatherItemWidget(mountain: results[index]);
      },
    );
  }
}
