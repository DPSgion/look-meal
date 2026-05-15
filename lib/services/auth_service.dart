import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Hàm đăng nhập
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Bật cửa sổ chọn email
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Người dùng bấm thoát ngang

      // Lấy Token từ Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Đóng gói Token gửi cho Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Xác thực và trả về thông tin User
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Lỗi hệ thống khi đăng nhập Google: $e");
      return null;
    }
  }

  // Hàm đăng xuất
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}