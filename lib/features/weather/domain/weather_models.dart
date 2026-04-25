/// Data models for OpenWeatherMap API responses.
library;

class CurrentWeather {
  final String cityName;
  final double lat;
  final double lon;
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final int visibility;
  final String description;
  final String mainCondition;
  final String iconCode;
  final int sunrise;
  final int sunset;
  final int clouds;

  CurrentWeather({
    required this.cityName,
    required this.lat,
    required this.lon,
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.visibility,
    required this.description,
    required this.mainCondition,
    required this.iconCode,
    required this.sunrise,
    required this.sunset,
    required this.clouds,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];
    final sys = json['sys'];
    final coord = json['coord'] ?? {};
    return CurrentWeather(
      cityName: json['name'] ?? '',
      lat: (coord['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (coord['lon'] as num?)?.toDouble() ?? 0.0,
      temp: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      humidity: main['humidity'] ?? 0,
      pressure: main['pressure'] ?? 0,
      windSpeed: (wind['speed'] as num).toDouble(),
      visibility: json['visibility'] ?? 0,
      description: weather['description'] ?? '',
      mainCondition: weather['main'] ?? '',
      iconCode: weather['icon'] ?? '01d',
      sunrise: sys['sunrise'] ?? 0,
      sunset: sys['sunset'] ?? 0,
      clouds: json['clouds']?['all'] ?? 0,
    );
  }
}

class ForecastDay {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final String description;
  final String mainCondition;
  final String iconCode;

  ForecastDay({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.mainCondition,
    required this.iconCode,
  });
}
