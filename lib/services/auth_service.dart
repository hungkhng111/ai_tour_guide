import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final _supabase = Supabase.instance.client;
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool get isAuthenticated {
    return _supabase.auth.currentUser != null;
  }

  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  String? get currentUserId {
    return _supabase.auth.currentUser?.id;
  }

  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }


  
  // Ham dang nhap
  Future<void> signInWithGoogle() async {
    try {
      final String webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.authenticate();
      // if (googleUser == null) return;

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw 'Lỗi Token: Không lấy được ID token';

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      throw Exception('Lỗi đăng nhập, $e');
    }
  }

  Future<void> signOut() async {
    // Dang xuat khoi google
    await GoogleSignIn.instance.signOut();
    // Dang xuat khoi supabase - xoa session hien tai cua user
    await _supabase.auth.signOut();
  }
}