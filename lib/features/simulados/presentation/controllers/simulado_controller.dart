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
          .collection('historico_simulados') // Subcoleção onde os dados reais residem
          .doc();

      // 🧠 2. ACESSO AO ESTADO DO RIVERPOD
      final sessionState = ref.read(quizSessionProvider);

      // 🔍 EXTRAÇÃO DINÂMICA DA INSTITUIÇÃO
      // Buscamos o instituicaoId diretamente da primeira questão do simulado executado
      String instituicaoIdExtraida = 'instituicao_padrao';
      if (sessionState.questoes.isNotEmpty) {
        final primeiraQuestao = sessionState.questoes.first;
        if (primeiraQuestao is Map) {
          instituicaoIdExtraida = primeiraQuestao['instituicaoId'] ?? 'instituicao_padrao';
        } else {
          // Caso seu objeto de questão seja uma classe/modelo estruturado
          instituicaoIdExtraida = primeiraQuestao.instituicaoId ?? 'instituicao_padrao';
        }
      }

      // 🛠️ 3. CONVERSÃO DA LISTA DE REVISÃO
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
        // ✅ CORRIGIDO: Agora usa a variável segura extraída da questão real
        instituicaoId: instituicaoIdExtraida, 
        categoria: sessionState.categoriaId.isEmpty ? 'Geral' : sessionState.categoriaId, 
        tipoProva: sessionState.modoProva == 'assunto' ? 'Por Assunto' : 'Completa', 
        assunto: sessionState.assuntoSelecionado, 
        totalQuestoes: questoesDaProva.length,
        acertos: totalAcertos,
        erros: questoesDaProva.length - totalAcertos, 
        pontosProva: notaCalculada, 
        pontosGamificacao: 10, 
        dataConclusao: DateTime.now(),
        revisaoQuestoes: listaRevisaoMapeada, 
      );

      // 5. Salva os dados de forma assíncrona no Cloud Firestore
      await historicoRef.set({
        'id': novoHistorico.id,
        'userId': novoHistorico.userId,
        'instituicaoId': novoHistorico.instituicaoId, // 🎯 Casado perfeitamente com seu índice composto!
        'categoria': novoHistorico.categoria,
        'tipoProva': novoHistorico.tipoProva,
        'assunto': novoHistorico.assunto,
        'totalQuestoes': novoHistorico.totalQuestoes,
        'acertos': novoHistorico.acertos,
        'erros': novoHistorico.erros,
        'notaObtida': novoHistorico.pontosProva, // 💎 Alinhado com a tela de histórico
        'pontosGamificacao': novoHistorico.pontosGamificacao,
        'dataHora': Timestamp.fromDate(novoHistorico.dataConclusao), // 💎 Casado com o índice do Firestore
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