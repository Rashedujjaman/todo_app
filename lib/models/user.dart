class User {
  String id;
  String email;
  String name = '';
  String photoURL = '';
  DateTime? createdAt;
  String uid = '';

  User(
      {required this.id,
      required this.email,
      this.name = '',
      this.photoURL = '',
      this.createdAt,
      this.uid = ''});
}
