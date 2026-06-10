import 'questao_model.dart';

class RevisaoQuestaoModel {
  final QuestaoModel questao;
  final int? opcaoEscolhidaIndex; // null se o aluno não respondeu (ex: tempo acabou)

  RevisaoQuestaoModel({
    required this.questao,
    required this.opcaoEscolhidaIndex,
  });
}