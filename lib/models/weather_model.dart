/// Weather models for Open-Meteo API
/// WMO Weather interpretation codes (WW)
/// Reference: https://open-meteo.com/en/docs

class WeatherModel {
  final double temperature;
  final int weatherCode;
  final String weatherDescription;
  final String weatherIcon;

  WeatherModel({
    required this.temperature,
    required this.weatherCode,
    required this.weatherDescription,
    required this.weatherIcon,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final weatherCode = current['weather_code'] ?? 0;
    
    return WeatherModel(
      temperature: (current['temperature_2m'] ?? 0).toDouble(),
      weatherCode: weatherCode,
      weatherDescription: getWeatherDescription(weatherCode),
      weatherIcon: getWeatherIcon(weatherCode),
    );
  }

  /// WMO Weather interpretation codes (WW)
  /// 0: Clear sky
  /// 1, 2, 3: Mainly clear, partly cloudy, and overcast
  /// 45, 48: Fog and depositing rime fog
  /// 51, 53, 55: Drizzle: Light, moderate, and dense intensity
  /// 56, 57: Freezing Drizzle: Light and dense intensity
  /// 61, 63, 65: Rain: Slight, moderate and heavy intensity
  /// 66, 67: Freezing Rain: Light and heavy intensity
  /// 71, 73, 75: Snow fall: Slight, moderate, and heavy intensity
  /// 77: Snow grains
  /// 80, 81, 82: Rain showers: Slight, moderate, and violent
  /// 85, 86: Snow showers slight and heavy
  /// 95: Thunderstorm: Slight or moderate
  /// 96, 99: Thunderstorm with slight and heavy hail
  static String getWeatherDescription(int code) {
    switch (code) {
      // Clear sky
      case 0:
        return 'Cerah';
      
      // Mainly clear, partly cloudy, overcast
      case 1:
        return 'Cerah Berawan';
      case 2:
        return 'Berawan Sebagian';
      case 3:
        return 'Mendung';
      
      // Fog
      case 45:
        return 'Berkabut';
      case 48:
        return 'Kabut Tebal';
      
      // Drizzle
      case 51:
        return 'Gerimis Ringan';
      case 53:
        return 'Gerimis Sedang';
      case 55:
        return 'Gerimis Lebat';
      
      // Freezing drizzle
      case 56:
        return 'Gerimis Dingin Ringan';
      case 57:
        return 'Gerimis Dingin Lebat';
      
      // Rain
      case 61:
        return 'Hujan Ringan';
      case 63:
        return 'Hujan Sedang';
      case 65:
        return 'Hujan Lebat';
      
      // Freezing rain
      case 66:
        return 'Hujan Es Ringan';
      case 67:
        return 'Hujan Es Lebat';
      
      // Snow
      case 71:
        return 'Salju Ringan';
      case 73:
        return 'Salju Sedang';
      case 75:
        return 'Salju Lebat';
      case 77:
        return 'Butiran Salju';
      
      // Rain showers
      case 80:
        return 'Hujan Singkat Ringan';
      case 81:
        return 'Hujan Singkat Sedang';
      case 82:
        return 'Hujan Deras';
      
      // Snow showers
      case 85:
        return 'Hujan Salju Ringan';
      case 86:
        return 'Hujan Salju Lebat';
      
      // Thunderstorm
      case 95:
        return 'Badai Petir';
      case 96:
        return 'Petir + Hujan Es Ringan';
      case 99:
        return 'Petir + Hujan Es Lebat';
      
      default:
        return 'Tidak Diketahui';
    }
  }

  /// Get weather icon emoji based on WMO code
  static String getWeatherIcon(int code) {
    switch (code) {
      // Clear sky
      case 0:
        return '☀️';
      
      // Mainly clear, partly cloudy
      case 1:
      case 2:
        return '⛅';
      
      // Overcast
      case 3:
        return '☁️';
      
      // Fog
      case 45:
      case 48:
        return '🌫️';
      
      // Drizzle
      case 51:
      case 53:
      case 55:
        return '🌦️';
      
      // Freezing drizzle
      case 56:
      case 57:
        return '🌧️';
      
      // Rain
      case 61:
      case 63:
      case 65:
        return '🌧️';
      
      // Freezing rain
      case 66:
      case 67:
        return '🌨️';
      
      // Snow
      case 71:
      case 73:
      case 75:
      case 77:
        return '❄️';
      
      // Rain showers
      case 80:
      case 81:
      case 82:
        return '⛈️';
      
      // Snow showers
      case 85:
      case 86:
        return '🌨️';
      
      // Thunderstorm
      case 95:
      case 96:
      case 99:
        return '⛈️';
      
      default:
        return '🌡️';
    }
  }

  /// Get short weather description for compact display
  static String getShortDescription(int code) {
    switch (code) {
      case 0:
        return 'Cerah';
      case 1:
      case 2:
        return 'Berawan';
      case 3:
        return 'Mendung';
      case 45:
      case 48:
        return 'Berkabut';
      case 51:
      case 53:
      case 55:
        return 'Gerimis';
      case 56:
      case 57:
        return 'Gerimis Dingin';
      case 61:
      case 63:
      case 65:
        return 'Hujan';
      case 66:
      case 67:
        return 'Hujan Es';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Salju';
      case 80:
      case 81:
      case 82:
        return 'Hujan Deras';
      case 85:
      case 86:
        return 'Hujan Salju';
      case 95:
      case 96:
      case 99:
        return 'Badai';
      default:
        return '-';
    }
  }
}

/// Model for 7-day weather forecast with hourly data
class WeatherForecastModel {
  final List<DailyForecast> daily;
  final List<HourlyForecast> hourly;

  WeatherForecastModel({
    required this.daily,
    required this.hourly,
  });

  factory WeatherForecastModel.fromJson(Map<String, dynamic> json) {
    final dailyData = json['daily'];
    final hourlyData = json['hourly'];
    
    final List<DailyForecast> dailyForecasts = [];
    final List<HourlyForecast> hourlyForecasts = [];
    
    // Parse daily data
    if (dailyData != null) {
      final times = dailyData['time'] as List? ?? [];
      final maxTemps = dailyData['temperature_2m_max'] as List? ?? [];
      final minTemps = dailyData['temperature_2m_min'] as List? ?? [];
      final weatherCodes = dailyData['weather_code'] as List? ?? [];
      final precipProb = dailyData['precipitation_probability_max'] as List?;
      final sunrise = dailyData['sunrise'] as List?;
      final sunset = dailyData['sunset'] as List?;

      for (int i = 0; i < times.length; i++) {
        dailyForecasts.add(DailyForecast(
          date: DateTime.parse(times[i]),
          maxTemp: (maxTemps.length > i ? maxTemps[i] : 0)?.toDouble() ?? 0.0,
          minTemp: (minTemps.length > i ? minTemps[i] : 0)?.toDouble() ?? 0.0,
          weatherCode: weatherCodes.length > i ? weatherCodes[i] ?? 0 : 0,
          precipitationProbability: precipProb != null && precipProb.length > i 
              ? precipProb[i] ?? 0 
              : 0,
          sunrise: sunrise != null && sunrise.length > i 
              ? DateTime.tryParse(sunrise[i] ?? '') 
              : null,
          sunset: sunset != null && sunset.length > i 
              ? DateTime.tryParse(sunset[i] ?? '') 
              : null,
        ));
      }
    }
    
    // Parse hourly data
    if (hourlyData != null) {
      final times = hourlyData['time'] as List? ?? [];
      final temps = hourlyData['temperature_2m'] as List? ?? [];
      final weatherCodes = hourlyData['weather_code'] as List? ?? [];
      final humidity = hourlyData['relative_humidity_2m'] as List?;
      final precipProb = hourlyData['precipitation_probability'] as List?;
      final windSpeed = hourlyData['wind_speed_10m'] as List?;

      for (int i = 0; i < times.length; i++) {
        hourlyForecasts.add(HourlyForecast(
          dateTime: DateTime.parse(times[i]),
          temperature: (temps.length > i ? temps[i] : 0)?.toDouble() ?? 0.0,
          weatherCode: weatherCodes.length > i ? weatherCodes[i] ?? 0 : 0,
          humidity: humidity != null && humidity.length > i 
              ? humidity[i] ?? 0 
              : 0,
          precipitationProbability: precipProb != null && precipProb.length > i 
              ? precipProb[i] ?? 0 
              : 0,
          windSpeed: windSpeed != null && windSpeed.length > i 
              ? (windSpeed[i] ?? 0).toDouble() 
              : 0.0,
        ));
      }
    }

    return WeatherForecastModel(
      daily: dailyForecasts,
      hourly: hourlyForecasts,
    );
  }

  /// Get hourly forecasts for a specific date
  List<HourlyForecast> getHourlyForDate(DateTime date) {
    return hourly.where((h) => 
      h.dateTime.year == date.year && 
      h.dateTime.month == date.month && 
      h.dateTime.day == date.day
    ).toList();
  }
}

/// Daily forecast model
class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
  final int precipitationProbability;
  final DateTime? sunrise;
  final DateTime? sunset;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
    required this.precipitationProbability,
    this.sunrise,
    this.sunset,
  });

  String get weatherDescription => WeatherModel.getWeatherDescription(weatherCode);
  String get weatherIcon => WeatherModel.getWeatherIcon(weatherCode);
  String get shortDescription => WeatherModel.getShortDescription(weatherCode);

  String get dayName {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }

  String get fullDayName {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[date.weekday - 1];
  }

  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]}';
  }

  String get formattedSunrise {
    if (sunrise == null) return '-';
    return '${sunrise!.hour.toString().padLeft(2, '0')}:${sunrise!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedSunset {
    if (sunset == null) return '-';
    return '${sunset!.hour.toString().padLeft(2, '0')}:${sunset!.minute.toString().padLeft(2, '0')}';
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}

/// Hourly forecast model
class HourlyForecast {
  final DateTime dateTime;
  final double temperature;
  final int weatherCode;
  final int humidity;
  final int precipitationProbability;
  final double windSpeed;

  HourlyForecast({
    required this.dateTime,
    required this.temperature,
    required this.weatherCode,
    required this.humidity,
    required this.precipitationProbability,
    required this.windSpeed,
  });

  String get weatherDescription => WeatherModel.getWeatherDescription(weatherCode);
  String get weatherIcon => WeatherModel.getWeatherIcon(weatherCode);
  String get shortDescription => WeatherModel.getShortDescription(weatherCode);

  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:00';
  }

  bool get isNow {
    final now = DateTime.now();
    return dateTime.year == now.year && 
           dateTime.month == now.month && 
           dateTime.day == now.day &&
           dateTime.hour == now.hour;
  }
}
