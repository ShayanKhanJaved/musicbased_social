class UserModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String bio;
  final String profileImageUrl;
  final List<String> favoriteArtists;
  final List<String> genres;
  final int gems;
  final int dailyRewardDay;
  final DateTime lastRewardDate;
  final DateTime createdAt;
  final bool profileComplete;
  final List<String> likedUsers;
  final List<String> dislikedUsers;
  final List<String> matches;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.bio,
    required this.profileImageUrl,
    required this.favoriteArtists,
    this.genres = const [],
    required this.gems,
    required this.dailyRewardDay,
    required this.lastRewardDate,
    required this.createdAt,
    this.profileComplete = false,
    this.likedUsers = const [],
    this.dislikedUsers = const [],
    this.matches = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'age': age,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'favoriteArtists': favoriteArtists,
      'genres': genres,
      'gems': gems,
      'dailyRewardDay': dailyRewardDay,
      'lastRewardDate': lastRewardDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'profileComplete': profileComplete,
      'likedUsers': likedUsers,
      'dislikedUsers': dislikedUsers,
      'matches': matches,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 18,
      bio: map['bio'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      favoriteArtists: List<String>.from(map['favoriteArtists'] ?? []),
      genres: List<String>.from(map['genres'] ?? []),
      gems: map['gems'] ?? 1000,
      dailyRewardDay: map['dailyRewardDay'] ?? 1,
      lastRewardDate: DateTime.fromMillisecondsSinceEpoch(
        map['lastRewardDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      profileComplete: map['profileComplete'] ?? false,
      likedUsers: List<String>.from(map['likedUsers'] ?? []),
      dislikedUsers: List<String>.from(map['dislikedUsers'] ?? []),
      matches: List<String>.from(map['matches'] ?? []),
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    int? age,
    String? bio,
    String? profileImageUrl,
    List<String>? favoriteArtists,
    List<String>? genres,
    int? gems,
    int? dailyRewardDay,
    DateTime? lastRewardDate,
    DateTime? createdAt,
    bool? profileComplete,
    List<String>? likedUsers,
    List<String>? dislikedUsers,
    List<String>? matches,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      favoriteArtists: favoriteArtists ?? this.favoriteArtists,
      genres: genres ?? this.genres,
      gems: gems ?? this.gems,
      dailyRewardDay: dailyRewardDay ?? this.dailyRewardDay,
      lastRewardDate: lastRewardDate ?? this.lastRewardDate,
      createdAt: createdAt ?? this.createdAt,
      profileComplete: profileComplete ?? this.profileComplete,
      likedUsers: likedUsers ?? this.likedUsers,
      dislikedUsers: dislikedUsers ?? this.dislikedUsers,
      matches: matches ?? this.matches,
    );
  }
}

// Artist model for music selection
class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> genres;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.genres,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'genres': genres,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      genres: List<String>.from(map['genres'] ?? []),
    );
  }
}