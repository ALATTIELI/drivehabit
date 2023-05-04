class UserData {
  final displayName;
  final email;
  final id;
  final photoURL;

  UserData(
      {required this.displayName,
      required this.email,
      required this.id,
      required this.photoURL});
}

class UserStorage {
  static UserData? _userData;

  static UserData? get userData => _userData;

  static void saveUserData(UserData data) {
    _userData = data;
  }

  static void clearUserData() {
    _userData = null;
  }
}
