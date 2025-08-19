import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color.fromARGB(255, 36, 98, 38),
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(255, 36, 98, 38),
          secondary: Color.fromARGB(255, 53, 146, 101),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(255, 36, 98, 38),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color.fromARGB(255, 36, 98, 38),
          unselectedItemColor: Colors.grey,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 36, 98, 38),
          ),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color.fromARGB(255, 36, 98, 38),
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 36, 98, 38),
          secondary: Colors.greenAccent,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(255, 36, 98, 38),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Color.fromARGB(255, 36, 98, 38),
          unselectedItemColor: Colors.grey,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      );

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Color get bottomNavBarColor => _isDarkMode ? Colors.black : Colors.white;
}
