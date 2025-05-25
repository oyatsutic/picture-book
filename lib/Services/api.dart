import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:picturebook/Services/config.dart';

class Api {
  Future<String> getBooks() async {
    try {
      final apiUrl = dotenv.env['API_URL'];
      console([apiUrl]);
      final response = await http.post(Uri.parse('$apiUrl/api/product/list'));
      return response.body;
    } catch (e) {
      return '';
    }
  }
}
