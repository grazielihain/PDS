import 'questao_model.dart';

class RevisaoQuestaoModel {
  final QuestaoModel questao;
  final int? opcaoEscolhidaIndex; // null se o aluno não respondeu

  RevisaoQuestaoModel({
    required this.questao,
    required this.opcaoEscolhidaIndex,
  });

  // 🛡️ CORRIGIDO: Utiliza Map.from para garantir a conversão segura do mapa interno do Firestore
  factory RevisaoQuestaoModel.fromMap(Map<String, dynamic> map) {
    return RevisaoQuestaoModel(
      questao: QuestaoModel.fromMap(
        Map<String, dynamic>.from(map['questao'] as Map),
        '', // Passando o ID vazio conforme sua implementação original
      ),
      opcaoEscolhidaIndex: map['opcaoEscolhidaIndex'] as int?,
    );
  }

  // CORRIGIDO: Força explicitamente o mapa de retorno a ser do tipo <String, dynamic>
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'questao': questao.toMap(),
      'opcaoEscolhidaIndex': opcaoEscolhidaIndex,
    };
  }
}
