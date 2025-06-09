import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String bio,
    String? profileImageUrl,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Create user account
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        UserModel userModel = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          age: age,
          bio: bio,
          profileImageUrl: profileImageUrl ?? '',
          favoriteArtists: [], // Will be filled in music selection
          gems: 1000, // Starting gems
          dailyRewardDay: 1,
          lastRewardDate: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An error occurred during signup');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user != null;
    } on FirebaseAuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An error occurred during signin');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _setError('Error signing out');
    }
  }

  Future<bool> updateUserMusicTastes(List<String> artists) async {
    try {
      if (_user == null) return false;

      await _firestore.collection('users').doc(_user!.uid).update({
        'favoriteArtists': artists,
        'profileComplete': true,
      });

      return true;
    } catch (e) {
      _setError('Error updating music tastes');
      return false;
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    try {
      if (_user == null) return null;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _setError('Error fetching user data');
      return null;
    }
  }

  Future<bool> checkDailyReward() async {
    try {
      if (_user == null) return false;
      
      UserModel? userData = await getCurrentUserData();
      if (userData == null) return false;
      
      DateTime now = DateTime.now();
      DateTime lastReward = userData.lastRewardDate;
      
      // Check if it's a new day
      if (now.day != lastReward.day || 
          now.month != lastReward.month || 
          now.year != lastReward.year) {
        
        // Calculate reward based on day
        int rewardDay = userData.dailyRewardDay;
        int rewardAmount = _getDailyRewardAmount(rewardDay);
        
        // Update user data
        await _firestore.collection('users').doc(_user!.uid).update({
          'gems': userData.gems + rewardAmount,
          'dailyRewardDay': rewardDay < 7 ? rewardDay + 1 : 1,
          'lastRewardDate': now,
        });
        
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Error checking daily reward');
      return false;
    }
  }

  int _getDailyRewardAmount(int day) {
    switch (day) {
      case 1: return 1000;
      case 2: return 1200;
      case 3: return 1400;
      case 4: return 1600;
      case 5: return 1800;
      case 6: return 2000;
      case 7: return 2500;
      default: return 1000;
    }
  }
}