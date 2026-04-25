import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:atmos_frontend/core/config/api_config.dart';
import 'package:atmos_frontend/features/weather/domain/weather_models.dart';

class WeatherApiClient {
  /// Fetch current weather for a city name or coordinates. Units = metric (Celsius).
  Future<CurrentWeather> fetchCurrentWeather({String? city, double? lat, double? lon}) async {
    final queryParams = <String, String>{};
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lon != null) queryParams['lon'] = lon.toString();

    final url = Uri.parse('${ApiConfig.baseUrl}/api/weather/current').replace(queryParameters: queryParams);
    
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return CurrentWeather.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('City not found');
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  /// Fetch 5-day / 3-hour forecast then aggregate by day.
  Future<List<ForecastDay>> fetchForecast({String? city, double? lat, double? lon}) async {
    final queryParams = <String, String>{};
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lon != null) queryParams['lon'] = lon.toString();

    final url = Uri.parse('${ApiConfig.baseUrl}/api/weather/forecast').replace(queryParameters: queryParams);

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _aggregateForecast(data['list'] as List);
    } else {
      throw Exception('Failed to load forecast');
    }
  }

  /// Aggregate the 3-hour intervals into daily min/max.
  List<ForecastDay> _aggregateForecast(List items) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in items) {
      final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final key = '${dt.year}-${dt.month}-${dt.day}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item as Map<String, dynamic>);
    }

    // Skip today, take up to 5 upcoming days.
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    final List<ForecastDay> days = [];
    for (final entry in grouped.entries) {
      if (entry.key == todayKey) continue;
      if (days.length >= 5) break;

      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;
      // Use midday reading for the icon/description
      Map<String, dynamic>? midday;
      for (final reading in entry.value) {
        final temp = (reading['main']['temp'] as num).toDouble();
        if (temp < minTemp) minTemp = temp;
        if (temp > maxTemp) maxTemp = temp;
        final hour = DateTime.fromMillisecondsSinceEpoch(
          reading['dt'] * 1000,
        ).hour;
        if (midday == null || (hour - 12).abs() < (DateTime.fromMillisecondsSinceEpoch(midday['dt'] * 1000).hour - 12).abs()) {
          midday = reading;
        }
      }
      final weather = midday!['weather'][0];
      final firstDt = DateTime.fromMillisecondsSinceEpoch(
        entry.value.first['dt'] * 1000,
      );
      days.add(ForecastDay(
        date: firstDt,
        tempMin: minTemp,
        tempMax: maxTemp,
        description: weather['description'] ?? '',
        mainCondition: weather['main'] ?? '',
        iconCode: weather['icon'] ?? '01d',
      ));
    }
    return days;
  }
}
