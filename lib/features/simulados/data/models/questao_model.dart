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

  factory QuestaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final List<dynamic> opcoesRaw = data['opcoes'] ?? [];
    final List<String> opcoesLista = opcoesRaw.map((e) => e.toString()).toList();

    return QuestaoModel(
      id: doc.id,
      pergunta: data['pergunta'] ?? '',
      opcoes: opcoesLista,
      respostaCorretaIndex: (data['respostaCorretaIndex'] as num?)?.toInt() ?? 0,
      instituicaoId: data['instituicaoId'] ?? '',
      categoriaId: data['categoriaId'] ?? '',
      assuntoId: data['assuntoId'] ?? '',
    );
  }
}