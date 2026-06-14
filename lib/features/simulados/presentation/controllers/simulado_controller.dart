import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/historico_model.dart';
import '../../data/models/questao_model.dart';
import '../../data/models/revisao_questao_model.dart';
import '../providers/quiz_session_provider.dart';

/// 🧠 CONTROLLER DO SIMULADO
/// Gerencia a finalização, cálculos de notas, integração com Firebase e persistência de histórico.
class SimuladoController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  SimuladoController(this.ref) : super(const AsyncValue.data(null));

  /// 🏁 FINALIZAR E GRAVAR SIMULADO NO FIREBASE
  /// Realiza a computação de acertos, pontos de gamificação e gera o snapshot imutável para o histórico.
  Future<void> finalizarEGravarSimulado({
    required List<QuestaoModel> questoesDaProva,
    required Map<String, String> respostasAluno,
    required double notaCalculada,
    required int totalAcertos,
    required List<RevisaoQuestaoModel> listaRevisao, // Recebe a lista de objetos de revisão
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';

      // 1. Prepara a referência do documento no Firestore
      final historicoRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId.isEmpty ? 'anonimo' : userId)
          .collection('historico_simulados')
          .doc();

      // 🧠 2. ACESSO AO ESTADO DO RIVERPOD (Correção do state.value)
      // Como o quizSessionProvider usa StateNotifier, lemos as propriedades diretamente de 'sessionState'
      final sessionState = ref.read(quizSessionProvider);

      // 🛠️ 3. CONVERSÃO DA LISTA DE REVISÃO (Correção do tipo da listaRevisao)
      // Mapeia a lista de objetos do Flutter para a estrutura de Map exigida pelo HistoricoModel
      final List<Map<String, dynamic>> listaRevisaoMapeada = listaRevisao.map((item) {
        return {
          'opcaoEscolhidaIndex': item.opcaoEscolhidaIndex,
          'questao': {
            'id': item.questao.id,
            'pergunta': item.questao.pergunta,
            'opcoes': item.questao.opcoes,
            'respostaCorretaIndex': item.questao.respostaCorretaIndex,
            'instituicaoId': item.questao.instituicaoId,
            'categoriaId': item.questao.categoriaId,
            'assuntoId': item.questao.assuntoId,
          },
        };
      }).toList();

      // 🛠️ 4. INSTÂNCIA DO MODELO TOTALMENTE CORRIGIDA E COMPATÍVEL
      final novoHistorico = HistoricoModel(
        id: historicoRef.id,
        userId: userId.isEmpty ? 'aluno_anonimo' : userId,
        instituicaoId: sessionState.categoriaId.isEmpty ? 'instituicao_padrao' : 'SUA_INSTITUICAO_AQUI', 
        categoria: sessionState.categoriaId.isEmpty ? 'Geral' : sessionState.categoriaId, 
        tipoProva: sessionState.modoProva == 'assunto' ? 'Por Assunto' : 'Completa', 
        assunto: sessionState.assuntoSelecionado, 
        totalQuestoes: questoesDaProva.length,
        acertos: totalAcertos,
        erros: questoesDaProva.length - totalAcertos, 
        pontosProva: notaCalculada, 
        pontosGamificacao: 10, // 🎯 US 12: Bônus imutável da regra de Gamificação
        dataConclusao: DateTime.now(),
        revisaoQuestoes: listaRevisaoMapeada, // ✅ Passa a lista convertida com sucesso
      );

      // 5. Salva os dados de forma assíncrona no Cloud Firestore
      await historicoRef.set({
        'id': novoHistorico.id,
        'userId': novoHistorico.userId,
        'instituicaoId': novoHistorico.instituicaoId,
        'categoria': novoHistorico.categoria,
        'tipoProva': novoHistorico.tipoProva,
        'assunto': novoHistorico.assunto,
        'totalQuestoes': novoHistorico.totalQuestoes,
        'acertos': novoHistorico.acertos,
        'erros': novoHistorico.erros,
        'pontosProva': novoHistorico.pontosProva,
        'pontosGamificacao': novoHistorico.pontosGamificacao,
        'dataConclusao': Timestamp.fromDate(novoHistorico.dataConclusao),
        'revisaoQuestoes': novoHistorico.revisaoQuestoes,
      });

      // 6. Reseta o estado do simulado atual após salvar com sucesso
      ref.read(quizSessionProvider.notifier).resetarSimulado();

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// 🌍 PROVIDER GLOBAL DO CONTROLLER DO SIMULADO
final simuladoControllerProvider = StateNotifierProvider<SimuladoController, AsyncValue<void>>((ref) {
  return SimuladoController(ref);
});