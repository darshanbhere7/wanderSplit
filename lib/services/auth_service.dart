import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get Firestore instance
  FirebaseFirestore get firestore => _firestore;

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

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) return null;

      // Check if user document exists
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      UserModel user;
      
      if (!docSnapshot.exists) {
        // Create new user document if it doesn't exist
        user = UserModel(
          id: userCredential.user?.uid,
          email: userCredential.user?.email ?? '',
          displayName: userCredential.user?.displayName ?? '',
        );
        
        await _firestore.collection('users').doc(user.id).set(user.toMap());
      } else {
        user = UserModel.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
      }
      
      return user;
    } catch (e) {
      print('Error during Google sign in: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      // Update Firebase Auth profile
      if (displayName != null || photoURL != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
} 