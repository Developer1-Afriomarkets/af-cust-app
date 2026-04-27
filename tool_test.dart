import 'package:http/http.dart' as http;

void main() async {
  var url = Uri.parse('https://eke.afriomarkets.com/store/products?limit=1');
  print('Requesting: $url');
  
  var response = await http.get(url);
  
  print('Status: ${response.statusCode}');
  print('Headers: ${response.headers}');
  print('Body snippet:');
  print(response.body.length > 500 ? response.body.substring(0, 500) : response.body);
}
