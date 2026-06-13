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
      // 💡 Temporariamente filtramos APENAS por instituicaoId para o teste.
      // Se houver qualquer questão dessa instituição no banco, ela vai carregar!
      Query query = _firestore
          .collection('questoes')
          .where('instituicaoId', isEqualTo: institutionId);

      // ⏱️ Forçamos um limite de 5 segundos. Se o Firebase congelar, ele cancela e avisa!
      final QuerySnapshot querySnapshot = await query.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception(
          'O Firebase demorou muito para responder! Verifique se o ID da instituição confere no banco.',
        ),
      );

      return querySnapshot.docs
          .map((doc) => QuestaoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar as questões do simulado: $e');
    }
  }
}
