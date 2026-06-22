import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/questao_entity.dart';
import '../../domain/repositories/simulado_repository.dart';
import '../datasources/simulado_remote_data_source.dart';

// 🟢 O INTERFONE DO REPOSITÓRIO (Provider do Riverpod): 
// É ele que as telas e os controllers vão chamar para pedir as questões!
final simuladoRepositoryProvider = Provider<SimuladoRepository>((ref) {
  final dataSource = ref.read(simuladoDataSourceProvider);
  return SimuladoRepositoryImpl(dataSource: dataSource);
});

class SimuladoRepositoryImpl implements SimuladoRepository {
  final SimuladoRemoteDataSource _dataSource;

  SimuladoRepositoryImpl({required SimuladoRemoteDataSource dataSource}) : _dataSource = dataSource;

  @override
  Future<List<QuestaoEntity>> obterQuestoesDoSimulado({
    required String institutionId,
    required String categoriaId,
    String? assuntoId,
  }) async {
    try {
      // 1. Chama o garçom (DataSource) para buscar os modelos brutos do Firebase
      final modelos = await _dataSource.buscarQuestoesPorFiltro(
        institutionId: institutionId,
        categoriaId: categoriaId,
        assuntoId: assuntoId,
      );

      // Proteção preventiva: Se o servidor retornar uma lista vazia ou nula
      if (modelos.isEmpty) {
        return [];
      }

      // 2. Transforma (mapeia) cada QuestaoModel em uma QuestaoEntity limpa
      return modelos.map((model) {
        return QuestaoEntity(
          id: model.id,
          pergunta: model.pergunta,
          opcoes: model.opcoes,
          respostaCorretaIndex: model.respostaCorretaIndex, 
        );
      }).toList();
      
    } catch (e) {
      throw Exception('Erro no repositório ao processar simulado: $e');
    }
  }
}
