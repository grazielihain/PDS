import 'package:cloud_firestore/cloud_firestore.dart';

class HistoricoModel {
  final String id;
  final String userId;
  final String instituicaoId;
  final String categoria;
  final String tipoProva; // 'Completa' ou 'Por Assunto'
  final String? assunto;
  final int totalQuestoes;
  final int acertos;
  final int erros;
  final double pontosProva; // Soma dos pontos das questões acertadas
  final int pontosGamificacao; // Bônus fixo por concluir configurado na Gamificação
  final DateTime dataConclusao;
  final List<Map<String, dynamic>> revisaoQuestoes; // Snapshot completo com respostas do aluno

  HistoricoModel({
    required this.id,
    required this.userId,
    required this.instituicaoId,
    required this.categoria,
    required this.tipoProva,
    this.assunto,
    required this.totalQuestoes,
    required this.acertos,
    required this.erros,
    required this.pontosProva,
    required this.pontosGamificacao,
    required this.dataConclusao,
    required this.revisaoQuestoes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'instituicaoId': instituicaoId,
      'categoria': categoria,
      'tipoProva': tipoProva,
      'assunto': assunto,
      'totalQuestoes': totalQuestoes,
      'acertos': acertos,
      'erros': erros,
      'pontosProva': pontosProva,
      'pontosGamificacao': pontosGamificacao,
      'dataConclusao': Timestamp.fromDate(dataConclusao),
      'revisaoQuestoes': revisaoQuestoes, // Aqui fica blindado contra alterações futuras no banco de questões
    };
  }
}
