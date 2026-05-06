import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cek token saat aplikasi pertama kali dimuat
  final token = await ApiService.getToken();
  
  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaKost Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A56DB),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      // Tentukan halaman awal berdasarkan status login
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}