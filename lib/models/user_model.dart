class UserModel {
  final String id;
  final String? userId;   // Generated ID like "bock1", "bock2"
  final String? hexId;
  final String? username;
  final String? email;
  final String role;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? dob;
  final String? gender;

  const UserModel({
    required this.id,
    this.userId,
    this.hexId,
    this.username,
    this.email,
    this.role = 'USER',
    this.phone,
    this.firstName,
    this.lastName,
    this.dob,
    this.gender,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] ?? '').toString(),
        userId: json['userId']?.toString(),
        hexId: json['hexId']?.toString(),
        username: json['username']?.toString(),
        email: json['email']?.toString(),
        role: _resolveRole(json),
        phone: json['phone']?.toString(),
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        dob: json['dob']?.toString(),
        gender: json['gender']?.toString(),
      );

  static String _resolveRole(Map<String, dynamic> json) {
    final roleValue = json['role'];
    if (roleValue is String && roleValue.trim().isNotEmpty) {
      return roleValue.toUpperCase();
    }

    final isAdminValue = json['isAdmin'];
    if (isAdminValue == true || isAdminValue.toString().toLowerCase() == 'true') {
      return 'ADMIN';
    }

    return 'USER';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'userId': userId,
        if (hexId != null) 'hexId': hexId,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        'role': role,
        'isAdmin': isAdmin,
        if (phone != null) 'phone': phone,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
      };

  UserModel copyWith({
    String? id,
    String? userId,
    String? hexId,
    String? username,
    String? email,
    String? role,
    String? phone,
    String? firstName,
    String? lastName,
    String? dob,
    String? gender,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      hexId: hexId ?? this.hexId,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
    );
  }
}
