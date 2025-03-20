class UserInfo {
  int id;
  String name;
  String email;
  String imageURL;

  UserInfo(this.id, this.name, this.email, this.imageURL);

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
      _parseIntFromJson(json['id']),
      json['name'] as String,
      json['email'] as String,
      json['imageURL'] as String,
    );
  }

  void printUser() {
    print(id);
  }
}
