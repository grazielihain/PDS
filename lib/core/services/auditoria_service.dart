import 'package:cloud_firestore/cloud_firestore.dart';

class AuditoriaService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Registra uma atividade no sistema com suporte a auditoria relacional
  static Future<void> registrarLog({
    required String usuarioId,
    required String usuarioNome,
    required String instituicaoId,
    required String acao, // 'CRIAR', 'EDITAR', 'EXCLUIR'
    required String tabela, // 'categorias', 'usuarios', etc.
    required String descricaoAmigavel, // Ex: "O usuário X criou a categoria Y"
    Map<String, dynamic>? dadosAntigos,
    Map<String, dynamic>? dadosNovos,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Referência do Log Global de Auditoria
      final logRef = _db.collection('auditoria_logs').doc();
      batch.set(logRef, {
        'usuarioId': usuarioId,
        'usuarioNome': usuarioNome,
        'instituicaoId': instituicaoId,
        'acao': acao,
        'tabela': tabela,
        'descricaoAmigavel': descricaoAmigavel,
        'dadosAntigos': dadosAntigos,
        'dadosNovos': dadosNovos,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. 🛡️ ATUALIZA CONTROLADORIA (Subtarefa 1.2) - Computa consumo em 1 única escrita
      final estatisticaRef = _db
          .collection('estatisticas_uso')
          .doc(instituicaoId);
      batch.set(estatisticaRef, {
        'totalEscritas': FieldValue.increment(1),
        'totalLeituras': FieldValue.increment(
          1,
        ), // Simulação controlada de leitura associada
        'ultimaAtividade': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      // Grava em log local de segurança em caso de falha de rede
      print('Erro crítico ao registrar log de auditoria: $e');
    }
  }
}
