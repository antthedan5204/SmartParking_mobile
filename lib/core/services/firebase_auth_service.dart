import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '25170468815-1besfmkk6prjergnado9tamuk6u2qvq4.apps.googleusercontent.com',
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled the sign-in

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Get ID Token
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
