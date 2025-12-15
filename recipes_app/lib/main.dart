import 'package:flutter/material.dart';
import 'package:recipes_app/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://semxpgbedyebgqixxtkp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlbXhwZ2JlZHllYmdxaXh4dGtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMjM4NjksImV4cCI6MjA4MDU5OTg2OX0.aDWS-HSijMK1M0CCHcUK9pou6oudiG5axnIpIB48kVY',
  );

  runApp(const RecipesApp());
}
