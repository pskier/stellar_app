class Dancer {
  final String id;
  final String firstName;
  final String lastName;
  final String groupId;

  Dancer({required this.id, required this.firstName, required this.lastName, required this.groupId});

  factory Dancer.fromMap(Map<String, dynamic> map) {
    return Dancer(
      id: map['id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      groupId: map['group_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'group_id': groupId,
    };
  }
}
