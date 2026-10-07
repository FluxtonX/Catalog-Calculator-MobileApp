import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['EXPO_PUBLIC_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
  );

  try {
    final response = await Supabase.instance.client.functions.invoke(
      'spotify',
      body: {'query': 'Drake'},
    );
    print(jsonEncode(response.data));
  } catch (e) {
    print('Error: $e');
  }
}
