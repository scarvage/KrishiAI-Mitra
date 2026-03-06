import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String condition;
  final String locationName;

  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.locationName,
  });
}

class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _geocodeUrl = 'https://nominatim.openstreetmap.org/reverse';

  // WMO weather code → description
  static String _conditionFromCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  Future<WeatherData> fetchWeather() async {
    final position = await _getLocation();

    final weatherUri = Uri.parse(
      '$_baseUrl?latitude=${position.latitude}&longitude=${position.longitude}'
      '&current=temperature_2m,weathercode&timezone=auto',
    );
    final weatherRes = await http.get(weatherUri);
    if (weatherRes.statusCode != 200) {
      throw Exception('Weather fetch failed: ${weatherRes.statusCode}');
    }

    final weatherJson = jsonDecode(weatherRes.body) as Map<String, dynamic>;
    final current = weatherJson['current'] as Map<String, dynamic>;
    final temperature = (current['temperature_2m'] as num).toDouble();
    final weatherCode = (current['weathercode'] as num).toInt();

    // Reverse geocode for city name
    String locationName = 'Your Location';
    try {
      final geoUri = Uri.parse(
        '$_geocodeUrl?lat=${position.latitude}&lon=${position.longitude}'
        '&format=json&zoom=10',
      );
      final geoRes = await http.get(
        geoUri,
        headers: {'User-Agent': 'KrishiAI-Mitra/1.0'},
      );
      if (geoRes.statusCode == 200) {
        final geoJson = jsonDecode(geoRes.body) as Map<String, dynamic>;
        final address = geoJson['address'] as Map<String, dynamic>?;
        locationName = address?['city'] as String? ??
            address?['town'] as String? ??
            address?['district'] as String? ??
            locationName;
      }
    } catch (_) {
      // Non-fatal — keep default location name
    }

    return WeatherData(
      temperature: temperature,
      condition: _conditionFromCode(weatherCode),
      locationName: locationName,
    );
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
  }
}
