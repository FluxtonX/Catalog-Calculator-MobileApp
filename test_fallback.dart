
import 'dart:convert';
import 'dart:io';

void main() async {
  final query = 'bad bunny';
  const apiKey = 'AIzaSyBvlzgXH5IKpLZFckQu-_KXv_rdMELAdNw';
  final httpClient = HttpClient();
  try {
    final req1 = await httpClient.getUrl(Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&type=channel&q=\&maxResults=1&key=\'));
    final res1 = await req1.close();
    final body1 = await res1.transform(utf8.decoder).join();
    final json1 = jsonDecode(body1);

    if (json1['items'] != null && (json1['items'] as List).isNotEmpty) {
      final channelId = json1['items'][0]['id']['channelId'];
      final req2 = await httpClient.getUrl(Uri.parse('https://www.googleapis.com/youtube/v3/channels?part=statistics&id=\&key=\'));
      final res2 = await req2.close();
      final body2 = await res2.transform(utf8.decoder).join();
      final json2 = jsonDecode(body2);

      if (json2['items'] != null && (json2['items'] as List).isNotEmpty) {
        final item = json2['items'][0];
        print('SUCCESS! Channel: \');
      }
    }
  } catch (e) {
    print('ERROR: \');
  }
}

