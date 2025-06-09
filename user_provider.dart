import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserModel? _currentUser;
  List<UserModel> _potentialMatches = [];
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  List<UserModel> get potentialMatches => _potentialMatches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (_auth.currentUser == null) return;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      _setError('Error loading user data');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateGems(int newGemCount) async {
    try {
      if (_auth.currentUser == null || _currentUser == null) return;
      
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'gems': newGemCount});
      
      _currentUser = _currentUser!.copyWith(gems: newGemCount);
      notifyListeners();
    } catch (e) {
      _setError('Error updating gems');
    }
  }

  Future<void> loadPotentialMatches() async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (_currentUser == null) return;
      
      // Get users with similar age restrictions
      Query query = _firestore.collection('users');
      
      // Age-based filtering (under 18 only sees under 18)
      if (_currentUser!.age < 18) {
        query = query.where('age', isLessThan: 18);
      } else {
        query = query.where('age', isGreaterThanOrEqualTo: 18);
      }
      
      QuerySnapshot snapshot = await query
          .where('uid', isNotEqualTo: _currentUser!.uid)
          .limit(20)
          .get();
      
      List<UserModel> allUsers = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => 
              !_currentUser!.likedUsers.contains(user.uid) &&
              !_currentUser!.dislikedUsers.contains(user.uid))
          .toList();
      
      // Sort by music similarity
      allUsers.sort((a, b) => 
          _calculateMusicSimilarity(b).compareTo(_calculateMusicSimilarity(a)));
      
      _potentialMatches = allUsers;
      notifyListeners();
    } catch (e) {
      _setError('Error loading matches');
    } finally {
      _setLoading(false);
    }
  }

  double _calculateMusicSimilarity(UserModel otherUser) {
    if (_currentUser == null) return 0.0;
    
    List<String> currentArtists = _currentUser!.favoriteArtists;
    List<String> otherArtists = otherUser.favoriteArtists;
    
    // Calculate direct artist matches
    int directMatches = currentArtists
        .where((artist) => otherArtists.contains(artist))
        .length;
    
    // If we have direct matches, prioritize them
    if (directMatches > 0) {
      return directMatches / currentArtists.length;
    }
    
    // Otherwise, calculate genre similarity
    List<String> currentGenres = _currentUser!.genres;
    List<String> otherGenres = otherUser.genres;
    
    int genreMatches = currentGenres
        .where((genre) => otherGenres.contains(genre))
        .length;
    
    return genreMatches > 0 ? genreMatches / currentGenres.length * 0.5 : 0.0;
  }

  Future<bool> likeUser(String targetUserId, {String? message}) async {
    try {
      if (_currentUser == null) return false;
      
      int gemCost = message != null ? 250 : 100;
      if (_currentUser!.gems < gemCost) {
        _setError('Not enough gems');
        return false;
      }
      
      // Update current user's liked list and gems
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'likedUsers': FieldValue.arrayUnion([targetUserId]),
        'gems': _currentUser!.gems - gemCost,
      });
      
      // Check if the other user also liked this user
      DocumentSnapshot targetUserDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();
      
      if (targetUserDoc.exists) {
        UserModel targetUser = UserModel.fromMap(
            targetUserDoc.data() as Map<String, dynamic>);
        
        if (targetUser.likedUsers.contains(_currentUser!.uid)) {
          // It's a match! Update both users
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'matches': FieldValue.arrayUnion([targetUserId]),
          });
          
          await _firestore.collection('users').doc(targetUserId).update({
            'matches': FieldValue.arrayUnion([_currentUser!.uid]),
          });
          
          // Create match document for chat
          await _firestore.collection('matches').doc(
              _getMatchId(_currentUser!.uid, targetUserId)).set({
            'users': [_currentUser!.uid, targetUserId],
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'lastMessage': message ?? 'You matched!',
            'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
          });
          
          if (message != null) {
            // Add the initial message
            await _firestore
                .collection('matches')
                .doc(_getMatchId(_currentUser!.uid, targetUserId))
                .collection('messages')
                .add({
              'senderId': _currentUser!.uid,
              'message': message,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }
      
      // Update local user data
      _currentUser = _currentUser!.copyWith(
        likedUsers: [..._currentUser!.likedUsers, targetUserId],
        gems: _currentUser!.gems - gemCost,
      );
      
      // Remove from potential matches
      _potentialMatches.removeWhere((user) => user.uid == targetUserId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error liking user');
      return false;
    }
  }

  Future<void> dislikeUser(String targetUserId) async {
    try {
      if (_currentUser == null) return;
      
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'dislikedUsers': FieldValue.arrayUnion([targetUserId]),
      });
      
      _currentUser = _currentUser!.copyWith(
        dislikedUsers: [..._currentUser!.dislikedUsers, targetUserId],
      );
      
      // Remove from potential matches
      _potentialMatches.removeWhere((user) => user.uid == targetUserId);
      
      notifyListeners();
    } catch (e) {
      _setError('Error disliking user');
    }
  }

  String _getMatchId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<void> addGemsFromAd() async {
    try {
      if (_currentUser == null) return;
      
      int newGemCount = _currentUser!.gems + 250;
      await updateGems(newGemCount);
    } catch (e) {
      _setError('Error adding gems from ad');
    }
  }
}