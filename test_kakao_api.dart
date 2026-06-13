import 'dart:io';

void main() async {
  var url = Uri.parse('https://dapi.kakao.com/v2/maps/sdk.js?appkey=400771ec937cf5ee0b60ad77ed424e4e&autoload=false');
  var request = await HttpClient().getUrl(url);
  request.headers.add('Referer', 'http://localhost:8080');
  request.headers.add('Origin', 'http://localhost:8080');
  
  var response = await request.close();
  print('Status code: ${response.statusCode}');
  
  var body = await response.transform(const SystemEncoding().decoder).join();
  print('Response body: $body');
}
