import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rumo_quiz/features/prova/domain/models/historico_model.dart';
import 'package:rumo_quiz/features/prova/domain/models/questao_model.dart';
import 'package:rumo_quiz/features/prova/domain/models/revisao_questao_model.dart';
import '../../domain/entities/questao_entity.dart';
import '../../data/repositories/simulado_repository_impl.dart';

final simuladoControllerProvider =
    StateNotifierProvider<SimuladoController, SimuladoState>((ref) {
      return SimuladoController(ref);
    });

// 📋 Essa classe guarda o "estado atual" do simulado na memória do celular
class SimuladoState {
  final List<QuestaoEntity> questoes;
  final int indiceQuestaoAtual;
  final Map<int, int>
  respostasDoAluno; // Chave: índice da questão, Valor: alternativa marcada
  final bool carregando;
  final String? erro;
  final bool finalizado;
  final int notaFinal;

  SimuladoState({
    this.questoes = const [],
    this.indiceQuestaoAtual = 0,
    this.respostasDoAluno = const {},
    this.carregando = false,
    this.erro,
    this.finalizado = false,
    this.notaFinal = 0,
  });

  // Função auxiliar para atualizar o estado respeitando a imutabilidade do Dart
  SimuladoState copyWith({
    List<QuestaoEntity>? questoes,
    int? indiceQuestaoAtual,
    Map<int, int>? respostasDoAluno,
    bool? carregando,
    String? erro,
    bool? finalizado,
    int? notaFinal,
  }) {
    return SimuladoState(
      questoes: questoes ?? this.questoes,
      indiceQuestaoAtual: indiceQuestaoAtual ?? this.indiceQuestaoAtual,
      respostasDoAluno: respostasDoAluno ?? this.respostasDoAluno,
      carregando: carregando ?? this.carregando,
      erro: erro,
      finalizado: finalizado ?? this.finalizado,
      notaFinal: notaFinal ?? this.notaFinal,
    );
  }
}

// 🟢 O GERENCIADOR DE ESTADO (Notifier do Riverpod)
class SimuladoController extends StateNotifier<SimuladoState> {
  final Ref _ref;

  SimuladoController(this._ref) : super(SimuladoState());

  // 🔥 Busca as questões no repositório baseado nos filtros selecionados
  Future<void> iniciarSimulado({
    required String institutionId,
    required String categoriaId,
    String? assuntoId,
  }) async {
    state = state.copyWith(carregando: true, erro: null);
    try {
      final repo = _ref.read(simuladoRepositoryProvider);
      final listaQuestoes = await repo.obterQuestoesDoSimulado(
        institutionId: institutionId,
        categoriaId: categoriaId,
        assuntoId: assuntoId,
      );

      if (listaQuestoes.isEmpty) {
        state = state.copyWith(
          carregando: false,
          erro: 'Nenhuma questão encontrada para este filtro.',
        );
      } else {
        state = state.copyWith(carregando: false, questoes: listaQuestoes);
      }
    } catch (e) {
      state = state.copyWith(carregando: false, erro: e.toString());
    }
  }

  // 📝 Salva a alternativa que o aluno clicou na tela
  void selecionarAlternativa(int alternativaIndex) {
    final novasRespostas = Map<int, int>.from(state.respostasDoAluno);
    novasRespostas[state.indiceQuestaoAtual] = alternativaIndex;
    state = state.copyWith(respostasDoAluno: novasRespostas);
  }

  // ➡️ Avança para a próxima pergunta se houver
  void proximaQuestao() {
    if (state.indiceQuestaoAtual < state.questoes.length - 1) {
      state = state.copyWith(indiceQuestaoAtual: state.indiceQuestaoAtual + 1);
    }
  }

  // ⬅️ Volta para a pergunta anterior se o aluno quiser revisar
  void questaoAnterior() {
    if (state.indiceQuestaoAtual > 0) {
      state = state.copyWith(indiceQuestaoAtual: state.indiceQuestaoAtual - 1);
    }
  }

  // 🏁 Corrige o simulado e calcula a nota (Regra de Negócio)
  Future<void> finalizarSimulado({
    required String userId,
    required String instituicaoId,
    required String provaId,
    required String tituloProva,
  }) async {
    try {
      int totalAcertos = 0;
      double notaCalculada = 0.0;
      List<RevisaoQuestaoModel> listaRevisao = [];
      final List<QuestaoEntity> questoesDaProva = state.questoes;

      for (int i = 0; i < questoesDaProva.length; i++) {
        final QuestaoEntity q = questoesDaProva[i];

        // Tenta buscar pelo ID da questão; se falhar/for nulo devido à nova estrutura, busca pelo índice numérico da posição
        int? escolhidaIndex = state.respostasDoAluno[q.id];
        if (escolhidaIndex == null && state.respostasDoAluno.containsKey(i)) {
          escolhidaIndex = state.respostasDoAluno[i];
        }

        final bool acertou =
            escolhidaIndex != null && escolhidaIndex == q.respostaCorretaIndex;

        if (acertou) {
          totalAcertos++;
          notaCalculada += 1.0;
        }

        // Garante que a revisão não quebre se o modelo QuestaoModel for exigido
        if (q is QuestaoModel) {
          listaRevisao.add(
            RevisaoQuestaoModel(
              questao:
                  q as QuestaoModel, // 🟢 Adicionado 'as QuestaoModel' para eliminar o erro de tipo
              opcaoEscolhidaIndex: escolhidaIndex,
            ),
          );
        }
      }

      // Atualiza o estado visual exigido pela simulado_page.dart (Mantém compatibilidade total)
      state = state.copyWith(
        finalizado: true,
        carregando: false,
        notaFinal:
            totalAcertos, // Atribui como int para evitar o erro de double/int? anterior
      );

      // Gravação na coleção de nível superior 'historicos' conforme o novo escopo do banco
      final historicoRef = FirebaseFirestore.instance
          .collection('historicos')
          .doc();

      final novoHistorico = HistoricoModel(
        id: historicoRef.id,
        alunoId: userId.isEmpty ? 'aluno_anonimo' : userId,
        provaId: provaId,
        tituloProva: tituloProva,
        acertos: totalAcertos,
        totalQuestoes: questoesDaProva.length,
        notaObtida: notaCalculada,
        notaMaxima: questoesDaProva.length.toDouble(),
        tempoUtilizadoSegundos: 0,
        mensagemFinalizacaoAdmin: 'Simulado Concluído com Sucesso',
        pontosGamificacao:
            10, // 🎯 US 12: Gamificação gravada de forma imutável no histórico
        dataHora: DateTime.now(),
        revisaoQuestoes: listaRevisao,
      );

      // Envia os dados estruturados respeitando o seu HistoricoModel original
      await historicoRef.set(novoHistorico.toFirestore());
      debugPrint(
        '🎉 SUCESSO: Histórico registrado na coleção de nível superior!',
      );

      // US 12 (Gamificação): Atualiza a pontuação acumulada diretamente no nó do usuário correspondente
      if (userId.isNotEmpty && userId != 'aluno_anonimo') {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .update({'pontuacaoAcumulada': FieldValue.increment(10)});
        debugPrint(
          '🎯 SUCESSO: +10 pontos de gamificação computados no perfil do aluno.',
        );
      }
    } catch (erro) {
      // Captura e exibe no console o motivo exato caso o Firebase recuse por regras de segurança (Security Rules)
      debugPrint('❌ FALHA NO FIRESTORE: $erro');
    }
  }

  // 🟢 PROVIDER GLOBAL DO CONTROLLER: É ela que a tela vai escutar!
  final simuladoControllerProvider =
      StateNotifierProvider<SimuladoController, SimuladoState>((ref) {
        return SimuladoController(ref);
      });
}
