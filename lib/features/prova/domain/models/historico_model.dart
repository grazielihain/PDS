import 'package:cloud_firestore/cloud_firestore.dart';
import 'questao_model.dart';
import 'revisao_questao_model.dart';

class HistoricoModel {
  final String id;
  final String alunoId;
  final String provaId; 
  final String tituloProva;
  final int acertos;
  final int totalQuestoes;
  final double notaObtida;
  final double notaMaxima;
  final int tempoUtilizadoSegundos;
  final String mensagemFinalizacaoAdmin;
  final int pontosGamificacao;
  final DateTime dataHora;
  final List<RevisaoQuestaoModel> revisaoQuestoes;

  HistoricoModel({
    required this.id,
    required this.alunoId,
    required this.provaId,
    required this.tituloProva,
    required this.acertos,
    required this.totalQuestoes,
    required this.notaObtida,
    required this.notaMaxima,
    required this.tempoUtilizadoSegundos,
    required this.mensagemFinalizacaoAdmin,
    required this.pontosGamificacao,
    required this.dataHora,
    required this.revisaoQuestoes,
  });

  // CONVERSÃO DE VOLTA (Firestore -> Dart)
  factory HistoricoModel.fromFirestore(Map<String, dynamic> json, String id) {
    List<RevisaoQuestaoModel> listaRevisao = [];
    if (json['revisaoQuestoes'] != null) {
      final listaMapas = json['revisaoQuestoes'] as List<dynamic>;
      listaRevisao = listaMapas.map((item) {
        final q = item['questao'] as Map<String, dynamic>;
        return RevisaoQuestaoModel(
          opcaoEscolhidaIndex: item['opcaoEscolhidaIndex'] ?? -1,
          questao: QuestaoModel(
            id: q['id'] ?? '',
            pergunta: q['pergunta'] ?? '',
            opcoes: List<String>.from(q['opcoes'] ?? []),
            respostaCorretaIndex: q['respostaCorretaIndex'] ?? 0,
            nota: (q['nota'] as num?)?.toDouble() ?? 1.0,
          ),
        );
      }).toList();
    }

    return HistoricoModel(
      id: id,
      alunoId: json['alunoId'] ?? '',
      provaId: json['provaId'] ?? '', 
      tituloProva: json['tituloProva'] ?? '',
      acertos: json['acertos'] ?? 0,
      totalQuestoes: json['totalQuestoes'] ?? 0,
      notaObtida: (json['notaObtida'] as num?)?.toDouble() ?? 0.0,
      notaMaxima: (json['notaMaxima'] as num?)?.toDouble() ?? 10.0,
      tempoUtilizadoSegundos: json['tempoUtilizadoSegundos'] ?? 0,
      mensagemFinalizacaoAdmin: json['mensagemFinalizacaoAdmin'] ?? '',
      pontosGamificacao: json['pontosGamificacao'] ?? 0,
      dataHora: (json['dataHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
      revisaoQuestoes: listaRevisao, 
    );
  }

  // CONVERSÃO DE IDA (Dart -> Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'alunoId': alunoId,
      'provaId': provaId, 
      'acertos': acertos,
      'totalQuestoes': totalQuestoes,
      'notaObtida': notaObtida,
      'notaMaxima': notaMaxima,
      'tempoUtilizadoSegundos': tempoUtilizadoSegundos,
      'mensagemFinalizacaoAdmin': mensagemFinalizacaoAdmin,
      'pontosGamificacao': pontosGamificacao,
      'dataHora': Timestamp.fromDate(dataHora),
      'revisaoQuestoes': revisaoQuestoes
          .map(
            (rq) => {
              'opcaoEscolhidaIndex': rq.opcaoEscolhidaIndex,
              'questao': {
                'id': rq.questao.id,
                'pergunta': rq.questao.pergunta,
                'opcoes': rq.questao.opcoes,
                'respostaCorretaIndex': rq.questao.respostaCorretaIndex,
                'nota': rq.questao.nota,
              },
            },
          )
          .toList(),
    };
  }
}