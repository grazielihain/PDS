class QuestaoModel {
  final String id;
  final String pergunta;
  final List<String> opcoes;
  final int respostaCorretaIndex;

  QuestaoModel({
    required this.id,
    required this.pergunta,
    required this.opcoes,
    required this.respostaCorretaIndex,
  });

  factory QuestaoModel.fromFirestore(Map<String, dynamic> json, String id) {
    return QuestaoModel(
      id: id,
      pergunta: json['pergunta'] ?? '',
      opcoes: List<String>.from(json['opcoes'] ?? []),
      respostaCorretaIndex: json['respostaCorretaIndex'] ?? 0,
    );
  }
}