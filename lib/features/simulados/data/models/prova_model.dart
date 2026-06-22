class ProvaModel {
  final String id;
  final String titulo;
  final String descricao;
  final int tempoEmMinutos;
  final String instituicaoId;

  ProvaModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tempoEmMinutos,
    required this.instituicaoId,
  });

  // Transforma o documento do Firebase (Map) para o modelo do Flutter
  factory ProvaModel.fromFirestore(Map<String, dynamic> json, String id) {
    return ProvaModel(
      id: id,
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      tempoEmMinutos: json['tempoEmMinutos'] ?? 0,
      instituicaoId: json['instituicaoId'] ?? '',
    );
  }
}
