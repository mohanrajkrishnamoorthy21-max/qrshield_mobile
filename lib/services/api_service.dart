import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String apiUrl = "http://10.0.2.2:8000/api/scan/";

  static Future<Map<String, dynamic>> checkUrl(String url) async {

    try {

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "url": url
        }),
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        return {
          "prediction": data["prediction"],
          "risk_score": data["risk_score"],
          "confidence": data["confidence"]
        };

      } else {

        throw Exception("Server error");

      }

    } catch (e) {

      return {
        "prediction": "error",
        "risk_score": 0,
        "confidence": 0
      };

    }

  }
}