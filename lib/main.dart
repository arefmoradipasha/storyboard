import 'package:flutter/material.dart';
import 'package:storyboard/uploads/GalleryPicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // رنگ پس‌زمینه‌ی AppBar مشکی
          foregroundColor: Colors.white, // رنگ متن و آیکون‌ها سفید
        ),
      ),
      home: GalleryScreen(),
    );
  }
}
