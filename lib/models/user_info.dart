class UserInfo {
  int idUser;
  String username;
  String name;
  String email;
  String imageURL;
  String userType;

  UserInfo(this.idUser, this.username, this.name, this.email, this.imageURL,
      this.userType);

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    int _parseIntFromJson(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is String) {
        return int.tryParse(value) ?? 0; // Default to 0 if parsing fails
      } else {
        return 0; // Default to 0 for unexpected types
      }
    }

    return UserInfo(
      _parseIntFromJson(
          json['idUser']), //idk why json['username'] as int, doesn't work
      json['username'] as String,
      json['name'] as String,
      json['email'] as String,
      json['imageURL'] as String,
      json['userType'] as String,
    );
  }

  void printUser() {
    print(idUser);
  }
}
