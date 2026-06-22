import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/questao_model.dart';

// 🟢 O INTERFONE (Provider do Riverpod): Permite que o app chame o garçom de qualquer lugar
final simuladoDataSourceProvider = Provider<SimuladoRemoteDataSource>((ref) {
  return SimuladoRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

abstract class SimuladoRemoteDataSource {
  Future<List<QuestaoModel>> buscarQuestoesPorFiltro({
    required String institutionId,
    required String categoriaId,
    String? assuntoId,
  });
}

// 🟢 O GARÇOM (DataSource): Vai no Firebase e traz as questões da escola certa
class SimuladoRemoteDataSourceImpl implements SimuladoRemoteDataSource {
  final FirebaseFirestore _firestore;

  SimuladoRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<List<QuestaoModel>> buscarQuestoesPorFiltro({
    required String institutionId,
    required String categoriaId,
    String? assuntoId,
  }) async {
    try {
      // 1. Iniciamos a query filtrando estritamente pela Instituição e pela Categoria selecionada
      // Nota: Mantemos o mapeamento exato de chaves do seu banco NoSQL desnormalizado (Sprint 2)
      Query query = _firestore
          .collection('questoes')
          .where('instituicaoId', isEqualTo: institutionId)
          .where('categoriaId', isEqualTo: categoriaId);

      // 2. Se o usuário (Acess3) escolheu uma prova "Por Assunto", filtramos também pelo assunto específico
      if (assuntoId != null && assuntoId.isNotEmpty) {
        query = query.where('assuntoId', isEqualTo: assuntoId);
      }

      // ⏱️ Forçamos um limite de 5 segundos. Se o Firebase congelar, ele cancela e avisa!
      final QuerySnapshot querySnapshot = await query.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception(
          'O Firebase demorou muito para responder! Verifique se a instituição e categorias existem no banco.',
        ),
      );

      // 3. Converte os documentos recebidos em lote único para o modelo estruturado QuestaoModel
      return querySnapshot.docs
          .map((doc) => QuestaoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar as questões do simulado no banco: $e');
    }
  }
}
