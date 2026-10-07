import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  dotenv.testLoad(fileInput: File('.env').readAsStringSync());
  final url = '${dotenv.env['EXPO_PUBLIC_SUPABASE_URL']}/functions/v1/spotify';
  final anonKey = dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'];
  
  final res = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $anonKey',
    },
    body: jsonEncode({'query': 'Drake'}),
  );
  
  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
}
