class Dancer {
  final int id; // zamiast String
  final String firstName;
  final String lastName;
  final int groupId;

  Dancer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.groupId,
  });

  factory Dancer.fromMap(Map<String, dynamic> map) {
    return Dancer(
      id: map['id'] as int,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      groupId: map['group_id'] as int,
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
