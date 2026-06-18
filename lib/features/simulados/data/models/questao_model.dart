import 'package:cloud_firestore/cloud_firestore.dart';

class QuestaoModel {
  final String id;
  final String pergunta;
  final List<String> opcoes;
  final int respostaCorretaIndex;
  final String instituicaoId;
  final String categoriaId;
  final String assuntoId;

  QuestaoModel({
    required this.id,
    required this.pergunta,
    required this.opcoes,
    required this.respostaCorretaIndex,
    required this.instituicaoId,
    required this.categoriaId,
    required this.assuntoId,
  });

  // 1️⃣ MÉTODO ADICIONADO: Necessário para o RevisaoQuestaoModel conseguir salvar a questão no Firestore
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pergunta': pergunta,
      'opcoes': opcoes,
      'respostaCorretaIndex': respostaCorretaIndex,
      'instituicaoId': instituicaoId,
      'categoriaId': categoriaId,
      'assuntoId': assuntoId,
    };
  }

  // 2️⃣ CONSTRUTOR ADICIONADO: Permite criar o objeto a partir de um Map puro (usado no fromMap da revisão e do perfil)
  factory QuestaoModel.fromMap(Map<String, dynamic> map, String docId) {
    final List<dynamic> opcoesRaw = map['opcoes'] ?? [];
    final List<String> opcoesLista = opcoesRaw
        .map((e) => e.toString())
        .toList();

    return QuestaoModel(
      id: map['id'] ?? docId,
      pergunta: map['pergunta'] ?? '',
      opcoes: opcoesLista,
      respostaCorretaIndex: (map['respostaCorretaIndex'] as num?)?.toInt() ?? 0,
      instituicaoId: map['instituicaoId'] ?? '',
      categoriaId: map['categoriaId'] ?? '',
      assuntoId: map['assuntoId'] ?? '',
    );
  }

  // Mantido seu método original do Firestore (ele agora pode até reaproveitar o fromMap internamente)
  factory QuestaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QuestaoModel.fromMap(data, doc.id);
  }
}
