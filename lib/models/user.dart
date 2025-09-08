class User {
  final String email;
  final String name;
  final String? profilePicture;

  User({
    required this.email,
    required this.name,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      name: json['name'],
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'profilePicture': profilePicture,
    };
  }
}
