import 'package:cloud_firestore/cloud_firestore.dart';

class HistoricoModel {
  final String id;
  final String alunoId;
  final String provaId;
  final String tituloProva;
  final int acertos;
  final int totalQuestoes;
  final double notaObtida; // Alterado/Adicionado
  final double notaMaxima; // Adicionado
  final DateTime dataHora;

  HistoricoModel({
    required this.id,
    required this.alunoId,
    required this.provaId,
    required this.tituloProva,
    required this.acertos,
    required this.totalQuestoes,
    required this.notaObtida,
    required this.notaMaxima,
    required this.dataHora,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'alunoId': alunoId,
      'provaId': provaId,
      'tituloProva': tituloProva,
      'acertos': acertos,
      'totalQuestoes': totalQuestoes,
      'notaObtida': notaObtida,
      'notaMaxima': notaMaxima,
      'dataHora': Timestamp.fromDate(dataHora),
    };
  }

  factory HistoricoModel.fromFirestore(Map<String, dynamic> json, String id) {
    return HistoricoModel(
      id: id,
      alunoId: json['alunoId'] ?? '',
      provaId: json['provaId'] ?? '',
      tituloProva: json['tituloProva'] ?? '',
      acertos: json['acertos'] ?? 0,
      totalQuestoes: json['totalQuestoes'] ?? 0,
      notaObtida: (json['notaObtida'] as num?)?.toDouble() ?? 0.0,
      notaMaxima: (json['notaMaxima'] as num?)?.toDouble() ?? 0.0,
      dataHora: (json['dataHora'] as Timestamp).toDate(),
    );
  }
}
