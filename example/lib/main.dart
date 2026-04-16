import 'package:flutter/material.dart';
import './screens/home_screen.dart';

void main() => runApp(const MyApp());

final ThemeData theme = ThemeData(
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.white10,
  fontFamily: 'PTSans',
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo View Example App',
      theme: theme,
      home: const Scaffold(
        body: HomeScreen(),
      ),
    );
  }
}
