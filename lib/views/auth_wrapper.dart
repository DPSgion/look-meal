import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_view.dart';
import 'login_view.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang kiểm tra dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
          );
        }
        
        // Đã đăng nhập -> Cho vào màn Home
        if (snapshot.hasData) {
          return const HomeView(); 
        }
        
        // Chưa đăng nhập -> Đẩy ra màn Login
        return const LoginView(); 
      },
    );
  }
}