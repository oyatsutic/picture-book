import 'package:http/http.dart' as http;

class Api {
  Future<String> getBooks() async {
    try {
      final response = await http
          .post(Uri.parse('http://192.168.133.177:5000/api/product/list'));

      return response.body;
    } catch (e) {
      return '';
    }
  }
}
