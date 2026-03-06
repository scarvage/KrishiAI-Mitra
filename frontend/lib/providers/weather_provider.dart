import 'package:flutter/material.dart';
import '../services/weather_service.dart';

enum WeatherStatus { idle, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  WeatherStatus status = WeatherStatus.idle;
  WeatherData? weatherData;
  String? errorMessage;

  Future<void> loadWeather() async {
    if (status == WeatherStatus.loading) return;
    status = WeatherStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      weatherData = await _service.fetchWeather();
      status = WeatherStatus.loaded;
    } catch (e) {
      errorMessage = e.toString();
      status = WeatherStatus.error;
    }
    notifyListeners();
  }
}
