import '../entities/questao_entity.dart';

abstract class SimuladoRepository {
  /// Busca a lista de questões disponíveis para a instituição, categoria e assunto.
  /// 
  /// Para proteger o plano gratuito do Firebase, este método traz os dados em lote único,
  /// permitindo que o sorteio, embaralhamento e limite de questões sejam calculados em RAM.
  Future<List<QuestaoEntity>> obterQuestoesDoSimulado({
    required String institutionId,
    required String categoriaId,
    String? assuntoId,
  });
}
