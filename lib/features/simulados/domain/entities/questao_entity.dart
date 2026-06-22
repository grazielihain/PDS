class QuestaoEntity {
  final String id;
  final String pergunta;
  final List<String> opcoes;
  final int respostaCorretaIndex;

  const QuestaoEntity({
    required this.id,
    required this.pergunta,
    required this.opcoes,
    required this.respostaCorretaIndex,
  });
}
