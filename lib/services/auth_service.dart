import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email & password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user account in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Set display name for the user
      await userCredential.user?.updateDisplayName(displayName);
      
      // Create user document in Firestore
      final user = UserModel(
        id: userCredential.user?.uid,
        email: email,
        displayName: displayName,
      );
      
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      
      return user;
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    }
  }

  // Sign in with email & password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get user data from Firestore
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();
      
      if (docSnapshot.exists) {
        return UserModel.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
      }
      
      return null;
    } catch (e) {
      print('Error during sign in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }
} 