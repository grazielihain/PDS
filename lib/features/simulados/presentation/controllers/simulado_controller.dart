import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/historico_model.dart';
import '../../data/models/questao_model.dart';
import '../../data/models/revisao_questao_model.dart';
import '../providers/quiz_session_provider.dart';

/// CONTROLLER DO SIMULADO
/// Gerencia a finalização, cálculos de notas, integração com Firebase e persistência de histórico.
class SimuladoController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  SimuladoController(this.ref) : super(const AsyncValue.data(null));

  /// FINALIZAR E GRAVA SIMULADO NO FIREBASE
  /// Realiza a computação de acertos, pontos de gamificação e gera o snapshot imutável para o histórico.
  Future<int> finalizarEGravarSimulado({
    required List<QuestaoModel> questoesDaProva,
    required Map<String, String> respostasAluno,
    required double notaCalculada,
    required int totalAcertos,
    required List<RevisaoQuestaoModel> listaRevisao,
    int tempoUtilizadoSegundos = 0,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';

      // 1. Prepara a referência do documento no Firestore
      final historicoRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId.isEmpty ? 'anonimo' : userId)
          .collection('historico_simulados') // Subcoleção onde os dados reais ficam isolados
          .doc();

      // 2. ACESSO AO ESTADO DO RIVERPOD
      final sessionState = ref.read(quizSessionProvider);

      // EXTRAÇÃO DINÂMICA DA INSTITUIÇÃO
      // Busca instituicaoId diretamente da primeira questão do simulado executado
      String instituicaoIdExtraida = 'instituicao_padrao';
      if (sessionState.questoes.isNotEmpty) {
        final primeiraQuestao = sessionState.questoes.first;
        if (primeiraQuestao is Map) {
          instituicaoIdExtraida = primeiraQuestao['instituicaoId'] ?? 'instituicao_padrao';
        } else if (primeiraQuestao is QuestaoModel) {
          // Ajuste de segurança: Garante a leitura correta se for o modelo estruturado
          instituicaoIdExtraida = primeiraQuestao.instituicaoId.isEmpty 
              ? 'instituicao_padrao' 
              : primeiraQuestao.instituicaoId;
        } else {
          // Fallback genérico caso use outra tipagem em alguma refatoração
          try {
            instituicaoIdExtraida = (primeiraQuestao as dynamic).instituicaoId ?? 'instituicao_padrao';
          } catch (_) {
            instituicaoIdExtraida = 'instituicao_padrao';
          }
        }
      }

      // 3. CONVERSÃO DA LISTA DE REVISÃO
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
            'justificativa': item.questao.justificativa,
          },
        };
      }).toList();

      // 4. BUSCA PONTOS DE GAMIFICAÇÃO NO FIRESTORE
      int pontosGamificacao = 0;
      if (instituicaoIdExtraida != 'instituicao_padrao' && sessionState.categoriaId.isNotEmpty) {
        try {
          final modoGam = sessionState.modoProva == 'assunto' ? 'assunto' : 'completo';
          final gamSnap = await FirebaseFirestore.instance
              .collection('gamificacao')
              .where('instituicaoId', isEqualTo: instituicaoIdExtraida)
              .get();
          for (final doc in gamSnap.docs) {
            final gd = doc.data();
            if (gd['categoriaId'] != sessionState.categoriaId) continue;
            final modo = gd['modo'] as String? ?? '';
            final modoMatch = modo == modoGam || (modoGam == 'completo' && modo == 'completa');
            if (!modoMatch) continue;
            if (sessionState.modoProva == 'assunto') {
              if (gd['assuntoId'] == sessionState.assuntoSelecionado) {
                pontosGamificacao = (gd['pontosBonus'] as num? ?? 0).toInt();
                break;
              }
            } else {
              pontosGamificacao = (gd['pontosBonus'] as num? ?? 0).toInt();
              break;
            }
          }
        } catch (e) {
          debugPrint('Aviso: Erro ao buscar regra de gamificação: $e');
        }
      }

      // Salva o NOME da categoria (não o ID) para exibição legível no histórico e revisão
      final String categoriaNomeParaSalvar = sessionState.categoriaNome.isNotEmpty
          ? sessionState.categoriaNome
          : sessionState.categoriaId.isNotEmpty
              ? sessionState.categoriaId
              : 'Geral';

      // 5. INSTÂNCIA DO MODELO TOTALMENTE CORRIGIDA E COMPATÍVEL
      final novoHistorico = HistoricoModel(
        id: historicoRef.id,
        userId: userId.isEmpty ? 'aluno_anonimo' : userId,
        instituicaoId: instituicaoIdExtraida,
        categoria: categoriaNomeParaSalvar,
        tipoProva: sessionState.modoProva == 'assunto' ? 'Por Assunto' : 'Completa',
        assunto: sessionState.assuntoSelecionado,
        totalQuestoes: questoesDaProva.length,
        acertos: totalAcertos,
        erros: questoesDaProva.length - totalAcertos,
        pontosProva: notaCalculada,
        pontosGamificacao: pontosGamificacao,
        dataConclusao: DateTime.now(),
        revisaoQuestoes: listaRevisaoMapeada,
      );

      // 6. Salva os dados de forma assíncrona no Cloud Firestore
      await historicoRef.set({
        'id': novoHistorico.id,
        'userId': novoHistorico.userId,
        'instituicaoId': novoHistorico.instituicaoId,
        'categoriaId': sessionState.categoriaId,
        'categoria': novoHistorico.categoria, // Nome legível da categoria
        'tipoProva': novoHistorico.tipoProva,
        'assunto': novoHistorico.assunto,
        'totalQuestoes': novoHistorico.totalQuestoes,
        'acertos': novoHistorico.acertos,
        'erros': novoHistorico.erros,
        'notaObtida': novoHistorico.pontosProva,
        'pontosGamificacao': novoHistorico.pontosGamificacao,
        'tempoUtilizadoSegundos': tempoUtilizadoSegundos,
        'dataHora': Timestamp.fromDate(novoHistorico.dataConclusao),
        'revisaoQuestoes': novoHistorico.revisaoQuestoes,
      });

      // 7. Atualiza pontuação acumulada do aluno (incremento atômico)
      if (pontosGamificacao > 0 && userId.isNotEmpty && userId != 'aluno_anonimo') {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .update({'pontuacaoAcumulada': FieldValue.increment(pontosGamificacao)});
      }

      // 8. Reseta o estado do simulado atual após salvar com sucesso
      ref.read(quizSessionProvider.notifier).resetarSimulado();

      state = const AsyncValue.data(null);
      return pontosGamificacao;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return 0;
    }
  }
}

/// PROVIDER GLOBAL DO CONTROLLER DO SIMULADO
final simuladoControllerProvider = StateNotifierProvider<SimuladoController, AsyncValue<void>>((ref) {
  return SimuladoController(ref);
});