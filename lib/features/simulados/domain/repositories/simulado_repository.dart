import '../entities/questao_entity.dart';

abstract class SimuladoRepository {
  // Define a regra: qualquer um que implementar este repositório 
  // precisa saber buscar uma lista de Questões Limpas (Entities)
  Future<List<QuestaoEntity>> obterQuestoesDoSimulado({
    required String institutionId,
    required String categoriaId,
    String? assuntoId,
  });
}