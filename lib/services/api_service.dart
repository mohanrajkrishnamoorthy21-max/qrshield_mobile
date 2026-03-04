import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api/scan/";

  static Future<String> checkUrl(String url) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"url": url}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["prediction"] == "phishing"
            ? "⚠️ Suspicious / Phishing Detected"
            : "✅ Safe URL";
      } else {
        return "Server Error";
      }
    } catch (e) {
      return "Connection Failed";
    }
  }
}