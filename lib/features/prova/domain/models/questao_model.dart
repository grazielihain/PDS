class QuestaoModel {
  final String id;
  final String pergunta;
  final List<String> opcoes;
  final int respostaCorretaIndex;
  final double nota; // Nova propriedade

  QuestaoModel({
    required this.id,
    required this.pergunta,
    required this.opcoes,
    required this.respostaCorretaIndex,
    required this.nota,
  });

  factory QuestaoModel.fromFirestore(Map<String, dynamic> json, String id) {
    return QuestaoModel(
      id: id,
      pergunta: json['pergunta'] ?? '',
      opcoes: List<String>.from(json['opcoes'] ?? []),
      respostaCorretaIndex: json['respostaCorretaIndex'] ?? 0,
      // Garante a conversão correta de num para double, evitando erros no Dart
      nota: (json['nota'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
