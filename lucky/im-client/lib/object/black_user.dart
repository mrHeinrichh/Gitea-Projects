class BlackUser {
  dynamic user;
  List<dynamic>? users;
  dynamic dummyData;

  BlackUser({this.user, this.users, this.dummyData});

  factory BlackUser.fromJson({dynamic user, List<dynamic>? list, Map<String, dynamic>? dummy}) => BlackUser(
    user: user,
    users: list,
    dummyData: dummy ?? null
  );
}
