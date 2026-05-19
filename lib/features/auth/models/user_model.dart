class UserModel {
  final String token;
  final String username;
  final String nama;
  final String level;

  const UserModel({
    required this.token,
    required this.username,
    required this.nama,
    required this.level,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        token: json['token'] ?? '',
        username: json['username'] ?? '',
        nama: json['nama'] ?? '',
        level: json['level'] ?? 'viewer',
      );

  bool get isOperator => level == 'operator' || level == 'admin';
}
