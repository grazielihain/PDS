class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role; // Master, Admin, Acess2 (Professor), Acess3 (Estudante)
  final String
  institutionId; // Garante o isolamento dos dados para White Label

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.institutionId,
  });

  /// Verifica se o usuário tem permissões administrativas
  bool get isAdminOrMaster => role == 'Admin' || role == 'Master';

  /// Verifica se é um estudante (Acess3)
  bool get isStudent => role == 'Acess3';
}
