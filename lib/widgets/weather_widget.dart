import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../api/api_service.dart';
import '../core/app_export.dart';
import '../models/weather_model.dart';

/// Compact weather badge for header - displays icon, temp, and description
/// Navigates to full forecast page when tapped
class WeatherBadge extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String locationName;

  const WeatherBadge({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<WeatherBadge> createState() => _WeatherBadgeState();
}

class _WeatherBadgeState extends State<WeatherBadge> {
  WeatherModel? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (widget.latitude == null || widget.longitude == null) {
      setState(() {
        _isLoading = false;
        _error = 'Koordinat tidak tersedia';
      });
      return;
    }

    try {
      final response = await ApiService().getCurrentWeather(
        widget.latitude!,
        widget.longitude!,
      );

      if (response['success'] == true) {
        setState(() {
          _weather = WeatherModel.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = response['message'] ?? 'Gagal memuat cuaca';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat cuaca';
      });
    }
  }

  void _openForecastPage() {
    if (widget.latitude == null || widget.longitude == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherForecastPage(
          latitude: widget.latitude!,
          longitude: widget.longitude!,
          locationName: widget.locationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.latitude == null || widget.longitude == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _openForecastPage,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20.h),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : _buildWeatherContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      width: 60.h,
      height: 24.h,
      child: Center(
        child: SizedBox(
          width: 16.h,
          height: 16.h,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off,
          color: Colors.grey,
          size: 18.h,
        ),
        SizedBox(width: 4.h),
        Text(
          '--°',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14.fSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _weather!.weatherIcon,
          style: TextStyle(fontSize: 18.fSize),
        ),
        SizedBox(width: 6.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_weather!.temperature.toStringAsFixed(0)}°C',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13.fSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              WeatherModel.getShortDescription(_weather!.weatherCode),
              style: TextStyle(
                color: Colors.black54,
                fontSize: 9.fSize,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Full page weather forecast with 7-day and hourly data
class WeatherForecastPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const WeatherForecastPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<WeatherForecastPage> createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  WeatherForecastModel? _forecast;
  WeatherModel? _currentWeather;
  bool _isLoading = true;
  String? _error;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both current weather and forecast in parallel
      final results = await Future.wait([
        ApiService().getCurrentWeather(widget.latitude, widget.longitude),
        ApiService().getWeatherForecast(widget.latitude, widget.longitude),
      ]);

      final currentResponse = results[0];
      final forecastResponse = results[1];

      WeatherModel? current;
      WeatherForecastModel? forecast;

      if (currentResponse['success'] == true && currentResponse['data'] != null) {
        current = WeatherModel.fromJson(currentResponse['data']);
      }

      if (forecastResponse['success'] == true && forecastResponse['data'] != null) {
        forecast = WeatherForecastModel.fromJson(forecastResponse['data']);
      }

      if (mounted) {
        setState(() {
          _currentWeather = current;
          _forecast = forecast;
          _isLoading = false;
          if (_currentWeather == null && _forecast == null) {
            _error = forecastResponse['message'] ?? 'Gagal memuat data cuaca dari OpenWeather';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat data cuaca ($e)';
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
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF81B59C)),
                      ),
                    )
                  : _error != null
                      ? _buildErrorState()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8.h, // Dikurangi agar lebih ke atas
        bottom: 16.h, // Dikurangi padding bawah agar tidak terlalu lebar
        left: 16.h,
        right: 16.h,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/headercuaca.jpeg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24.h,
              ),
            ),
          ),
          SizedBox(width: 16.h),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prakiraan Cuaca',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.locationName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13.fSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: _fetchData,
            child: Container(
              padding: EdgeInsets.all(8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 24.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64.h,
            color: Colors.white70,
          ),
          SizedBox(height: 16.h),
          Text(
            _error!,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.fSize,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label:
                const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.h),
                side: BorderSide(color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Current weather card
          if (_currentWeather != null) _buildCurrentWeatherCard(),

          SizedBox(height: 16.h),

          // 7-day forecast section
          _buildDailyForecastSection(),

          SizedBox(height: 16.h),

          // Hourly forecast for selected day
          _buildHourlyForecastSection(),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    return Container(
      margin: EdgeInsets.all(16.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.h),
        child: Container(
          padding: EdgeInsets.all(20.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20.h),
            border:
                Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white.withOpacity(0.9),
                      size: 16.h,
                    ),
                    SizedBox(width: 6.h),
                    Text(
                      'Cuaca Saat Ini',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13.fSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentWeather!.weatherIcon,
                      style: TextStyle(fontSize: 64.fSize),
                    ),
                    SizedBox(width: 20.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_currentWeather!.temperature.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48.fSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '°C',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 24.fSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _currentWeather!.weatherDescription,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.fSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildDailyForecastSection() {
    if (_forecast == null || _forecast!.daily.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 20.h,
              ),
              SizedBox(width: 8.h),
              Text(
                'Prakiraan 7 Hari',
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 132.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.h),
            itemCount: _forecast!.daily.length,
            itemBuilder: (context, index) {
              final day = _forecast!.daily[index];
              final isSelected = index == _selectedDayIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: Container(
                  width: 85.h,
                  margin: EdgeInsets.symmetric(horizontal: 4.h),
                  padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.black.withOpacity(0.50)
                        : Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16.h),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          day.isToday ? 'Hari Ini' : day.dayName,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12.fSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.9),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        day.weatherIcon,
                        style: TextStyle(fontSize: 24.fSize),
                      ),
                      SizedBox(height: 2.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${day.maxTemp.toStringAsFixed(0)}°/${day.minTemp.toStringAsFixed(0)}°',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12.fSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.9),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Selected day details
        if (_forecast!.daily.isNotEmpty)
          _buildSelectedDayDetails(_forecast!.daily[
              (_selectedDayIndex < _forecast!.daily.length) ? _selectedDayIndex : 0]),
      ],
    );
  }

  Widget _buildSelectedDayDetails(DailyForecast day) {
    return Container(
      margin: EdgeInsets.all(16.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.h),
        child: Container(
          padding: EdgeInsets.all(16.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16.h),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day.isToday
                          ? 'Hari Ini'
                          : '${day.fullDayName}, ${day.formattedDate}',
                      style: TextStyle(
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      day.weatherIcon,
                      style: TextStyle(fontSize: 32.fSize),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.thermostat,
                        label: 'Maks',
                        value: '${day.maxTemp.toStringAsFixed(1)}°C',
                        color: Colors.red[400]!,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.thermostat_outlined,
                        label: 'Min',
                        value: '${day.minTemp.toStringAsFixed(1)}°C',
                        color: Colors.blue[400]!,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.water_drop,
                        label: 'Hujan',
                        value: '${day.precipitationProbability}%',
                        color: Colors.blue[600]!,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.wb_sunny,
                        label: 'Terbit',
                        value: day.formattedSunrise,
                        color: Colors.orange[400]!,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.wb_twilight,
                        label: 'Terbenam',
                        value: day.formattedSunset,
                        color: Colors.deepOrange[400]!,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.cloud,
                        label: 'Kondisi',
                        value: day.shortDescription,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22.h),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.fSize,
            color: Colors.white70,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.fSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.9),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHourlyForecastSection() {
    if (_forecast == null || _forecast!.daily.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedDay = _forecast!.daily[_selectedDayIndex];
    final hourlyData = _forecast!.getHourlyForDate(selectedDay.date);

    if (hourlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.white,
                size: 20.h,
              ),
              SizedBox(width: 8.h),
              Text(
                'Prakiraan Per Jam',
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 152.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.h),
            itemCount: hourlyData.length,
            itemBuilder: (context, index) {
              final hour = hourlyData[index];
              final isNow = hour.isNow;

              return Container(
                width: 75.h,
                margin: EdgeInsets.symmetric(horizontal: 4.h),
                padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isNow
                      ? Colors.black.withOpacity(0.55)
                      : Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12.h),
                  border: Border.all(
                    color: isNow ? Colors.white : Colors.white.withOpacity(0.3),
                    width: isNow ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isNow ? 'Sekarang' : hour.formattedTime,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11.fSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.9),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      hour.weatherIcon,
                      style: TextStyle(fontSize: 22.fSize),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${hour.temperature.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.9),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (hour.precipitationProbability > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 10.h,
                              color: Colors.lightBlueAccent,
                            ),
                            Text(
                              '${hour.precipitationProbability}%',
                              style: TextStyle(
                                fontSize: 9.fSize,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Keep old WeatherWidget for backward compatibility (deprecated)
@Deprecated('Use WeatherBadge instead')
class WeatherWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String locationName;

  const WeatherWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return WeatherBadge(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );
  }
}
