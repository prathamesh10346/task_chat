class User {
  final int id;
  final String username;
  final String name;
  bool isOnline;

  User({
    required this.id,
    required this.username,
    required this.name,
    this.isOnline = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      isOnline: json['online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'online': isOnline,
    };
  }
}