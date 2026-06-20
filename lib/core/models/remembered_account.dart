class RememberedAccount {
  final String uid;
  final String displayName;
  final String email;
  final String profileImageUrl;
  final String role;

  const RememberedAccount({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.profileImageUrl,
    required this.role,
  });

  String get username {
    final name = displayName.trim();
    final normalizedEmail = email.trim();
    if (name.isNotEmpty && name.toLowerCase() != normalizedEmail.toLowerCase()) {
      return name;
    }

    if (normalizedEmail.contains('@')) {
      return normalizedEmail.split('@').first;
    }
    return normalizedEmail.isEmpty ? 'Saved account' : normalizedEmail;
  }

  String get initial {
    final label = username.trim();
    return label.isEmpty ? '?' : label[0].toUpperCase();
  }

  factory RememberedAccount.fromJson(Map<String, dynamic> json) {
    return RememberedAccount(
      uid: (json['uid'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      profileImageUrl: (json['profileImageUrl'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'role': role,
    };
  }
}
