import 'package:cloud_firestore/cloud_firestore.dart';

class HistoricoModel {
  final String id;
  final String alunoId;
  final String provaId;
  final String tituloProva;
  final int acertos;
  final int totalQuestoes;
  final DateTime dataHora;

  HistoricoModel({
    required this.id,
    required this.alunoId,
    required this.provaId,
    required this.tituloProva,
    required this.acertos,
    required this.totalQuestoes,
    required this.dataHora,
  });

  // Converte o modelo para um formato de mapa (JSON) que o Firestore entende para salvar
  Map<String, dynamic> toFirestore() {
    return {
      'alunoId': alunoId,
      'provaId': provaId,
      'tituloProva': tituloProva,
      'acertos': acertos,
      'totalQuestoes': totalQuestoes,
      'dataHora': Timestamp.fromDate(
        dataHora,
      ), // O Firestore usa Timestamp para datas
    };
  }

  // Caso precise ler o histórico futuramente para listar na tela de desempenho
  factory HistoricoModel.fromFirestore(Map<String, dynamic> json, String id) {
    return HistoricoModel(
      id: id,
      alunoId: json['alunoId'] ?? '',
      provaId: json['provaId'] ?? '',
      tituloProva: json['tituloProva'] ?? '',
      acertos: json['acertos'] ?? 0,
      totalQuestoes: json['totalQuestoes'] ?? 0,
      dataHora: (json['dataHora'] as Timestamp).toDate(),
    );
  }
}
