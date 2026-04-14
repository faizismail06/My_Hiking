import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import '../../../core/app_export.dart';
import '../../../api/api_service.dart';
import '../../../models/weather_model.dart';
import '../models/homelist_item_model.dart';
import '../../../widgets/weather_widget.dart' show WeatherForecastPage;

class WeatherItemWidget extends StatefulWidget {
  final HomelistItemModel mountain;

  const WeatherItemWidget({super.key, required this.mountain});

  @override
  State<WeatherItemWidget> createState() => _WeatherItemWidgetState();
}

class _WeatherItemWidgetState extends State<WeatherItemWidget> {
  WeatherModel? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (widget.mountain.latitude == null || widget.mountain.longitude == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Koordinat (-)';
        });
      }
      return;
    }

    try {
      final response = await ApiService().getCurrentWeather(
        widget.mountain.latitude!,
        widget.mountain.longitude!,
      );

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _weather = WeatherModel.fromJson(response['data']);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Gagal (-)';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error (-)';
        });
      }
    }
  }

  void _openForecast() {
    if (widget.mountain.latitude == null || widget.mountain.longitude == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherForecastPage(
          latitude: widget.mountain.latitude!,
          longitude: widget.mountain.longitude!,
          locationName: widget.mountain.namaGunung ?? 'Gunung',
        ),
      ),
    );
  }

  String _formatKetinggian(int? k) {
    if (k == null) return "- mdpl";
    final s = k.toString();
    if (s.length > 3) {
      return '${s.substring(0, s.length - 3)}.${s.substring(s.length - 3)} mdpl';
    }
    return '$s mdpl';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mountain;
    final ketinggianText = _formatKetinggian(m.ketinggian);

    return GestureDetector(
      onTap: _openForecast,
      child: Container(
        height: 180.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.h),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.h),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.mountain.gambar ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: const Color(0xFF2E3D36)),
                errorWidget: (context, url, error) => Container(color: const Color(0xFF2E3D36)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 20.h,
                left: 20.h,
                right: 150.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mountain.namaGunung?.toUpperCase() ?? '-',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        color: Colors.white,
                        fontSize: 20.fSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 6, offset: const Offset(1, 2))
                        ]
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      widget.mountain.province?.name ?? '-',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13.fSize,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4, offset: const Offset(1, 1))
                        ]
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16.h,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGlassBox(
                         width: 120.h,
                         height: 50.h,
                         child: _buildKetinggianContent(ketinggianText),
                      ),
                      SizedBox(height: 12.h),
                      _buildGlassBox(
                         width: 120.h,
                         height: 80.h,
                         child: _buildWeatherGlassBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBox({required Widget child, required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.h),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: 4.h, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16.h),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildKetinggianContent(String ketinggianText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Ketinggian:",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9), 
            fontSize: 10.fSize, 
            fontWeight: FontWeight.w500
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          ketinggianText,
          style: TextStyle(
            color: Colors.white, 
            fontSize: 13.fSize, 
            fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherGlassBox() {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20.h,
          height: 20.h,
          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: Colors.white, fontSize: 10.fSize)),
      );
    }

    if (_weather != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_weather!.temperature.toStringAsFixed(0)}°C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.fSize,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))]
                ),
              ),
              SizedBox(width: 8.h),
              Text(
                _weather!.weatherIcon,
                style: TextStyle(fontSize: 24.fSize),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            WeatherModel.getShortDescription(_weather!.weatherCode),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12.fSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
