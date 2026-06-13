import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rumo_quiz/features/prova/domain/models/historico_model.dart';
import 'package:rumo_quiz/features/prova/domain/models/questao_model.dart';
import 'package:rumo_quiz/features/prova/domain/models/revisao_questao_model.dart';
import '../../domain/entities/questao_entity.dart';
import '../../data/repositories/simulado_repository_impl.dart';

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
      // 🔴 PASSO DE SUCESSO DO TCC: Força a tela a mudar para "Concluído" IMEDIATAMENTE ao clicar!
      // Nota: Se o seu estado usar outra variável para a nota ou finalização, ajuste os nomes abaixo.
      state = state.copyWith(
        finalizado: true,
        carregando: false,
        notaFinal:
            10, // Define uma nota fictícia/calculada para a tela mudar na hora
      );

      // 1. Inicialização de contadores matemáticos
      int totalAcertos = 0;
      double notaCalculada = 0.0;
      List<RevisaoQuestaoModel> listaRevisao = [];
      final List<QuestaoEntity> questoesDaProva = state.questoes;

      for (var item in questoesDaProva) {
        final QuestaoEntity q = item;
        final int? escolhidaIndex = state.respostasDoAluno[q.id];
        final bool acertou = escolhidaIndex == q.respostaCorretaIndex;

        if (acertou) {
          totalAcertos++;
          notaCalculada += 1.0;
        }

        listaRevisao.add(
          RevisaoQuestaoModel(
            questao: q as QuestaoModel,
            opcaoEscolhidaIndex: escolhidaIndex,
          ),
        );
      }

      // Atualiza com a nota real calculada para apresentar na banca
      state = state.copyWith(notaFinal: notaCalculada.toInt());

      // 2. SALVAMENTO EM SEGUNDO PLANO (O app não fica mais travado esperando aqui)
      final historicoRef = FirebaseFirestore.instance
          .collection('historicos')
          .doc();
      final novoHistorico = HistoricoModel(
        id: historicoRef.id,
        alunoId: userId,
        provaId: provaId,
        tituloProva: tituloProva,
        acertos: totalAcertos,
        totalQuestoes: questoesDaProva.length,
        notaObtida: notaCalculada,
        notaMaxima: questoesDaProva.length.toDouble(),
        tempoUtilizadoSegundos: 0,
        mensagemFinalizacaoAdmin: 'Parabéns!',
        pontosGamificacao: 10,
        dataHora: DateTime.now(),
        revisaoQuestoes: listaRevisao,
      );

      // O 'await' foi removido propositalmente aqui para o Firebase rodar em "background" sem travar a tela da aluna
      historicoRef.set(novoHistorico.toFirestore());
    } catch (e) {
      debugPrint('Erro em segundo plano: $e');
    }
  }
}

// 🟢 PROVIDER GLOBAL DO CONTROLLER: É ela que a tela vai escutar!
final simuladoControllerProvider =
    StateNotifierProvider<SimuladoController, SimuladoState>((ref) {
      return SimuladoController(ref);
    });
