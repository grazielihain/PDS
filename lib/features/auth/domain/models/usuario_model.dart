class UsuarioModel {
  final String uid;
  final String nome;
  final String email;
  final String avatarEmoji;
  final String instituicao;

  UsuarioModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.avatarEmoji,
    required this.instituicao,
  });

  // Converte um documento do Firestore (Map) para o Modelo
  factory UsuarioModel.fromMap(Map<String, dynamic> map, String id) {
    return UsuarioModel(
      uid: id,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      avatarEmoji: map['avatarEmoji'] ?? '🐱',
      instituicao: map['instituicao'] ?? 'Sua Instituição de Ensino',
    );
  }

  // Converte o Modelo para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'avatarEmoji': avatarEmoji,
      'instituicao': instituicao,
    };
  }
}
