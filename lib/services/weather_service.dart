import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/network/app_http_client.dart';
import '../core/exceptions/app_exception.dart';

class WeatherService {
  final AppHttpClient _http;

  WeatherService({AppHttpClient? httpClient}) : _http = httpClient ?? AppHttpClient();

  Future<Map<String, dynamic>> getCurrentWeather() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw ConfigException('Dịch vụ vị trí bị tắt.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw ConfigException('Quyền vị trí bị từ chối.');
      }
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw ConfigException('Không tìm thấy API Key trong file .env');

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=${position.latitude}&lon=${position.longitude}'
      '&appid=$apiKey&units=metric&lang=vi',
    );

    // GET — idempotent, AppHttpClient sẽ tự retry tối đa 2 lần nếu lỗi mạng.
    final response = await _http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ServerException('Không thể tải dữ liệu thời tiết.', statusCode: response.statusCode);
  }
}