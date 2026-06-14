import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 📦 MODELO DE ESTADO DA SESSÃO DO QUIZ
/// Armazena o estado imutável do simulado em execução conforme regras do Figma Make.
class QuizSessionState {
  final bool emExecucao;
  final String categoriaId;
  final String modoProva; // 'assunto' ou 'completa'
  final String? assuntoSelecionado;
  final List<dynamic> questoes; // Lista de Questões filtradas/sorteadas
  final int indiceQuestaoAtual;
  final Map<String, String> respostasSelecionadas; // {questaoId: alternativaSelecionada}
  final int tempoRestanteSegundos;
  final bool tempoEncerrado;
  final bool mostrarAviso5Minutos;

  QuizSessionState({
    this.emExecucao = false,
    this.categoriaId = '',
    this.modoProva = 'completa',
    this.assuntoSelecionado,
    this.questoes = const [],
    this.indiceQuestaoAtual = 0,
    this.respostasSelecionadas = const {},
    this.tempoRestanteSegundos = 0,
    this.tempoEncerrado = false,
    this.mostrarAviso5Minutos = false,
  });

  QuizSessionState copyWith({
    bool? emExecucao,
    String? categoriaId,
    String? modoProva,
    String? asuntoSelecionado,
    List<dynamic>? questoes,
    int? indiceQuestaoAtual,
    Map<String, String>? respostasSelecionadas,
    int? tempoRestanteSegundos,
    bool? tempoEncerrado,
    bool? mostrarAviso5Minutos,
  }) {
    return QuizSessionState(
      emExecucao: emExecucao ?? this.emExecucao,
      categoriaId: categoriaId ?? this.categoriaId,
      modoProva: modoProva ?? this.modoProva,
      assuntoSelecionado: asuntoSelecionado ?? this.assuntoSelecionado,
      questoes: questoes ?? this.questoes,
      indiceQuestaoAtual: indiceQuestaoAtual ?? this.indiceQuestaoAtual,
      respostasSelecionadas: respostasSelecionadas ?? this.respostasSelecionadas,
      tempoRestanteSegundos: tempoRestanteSegundos ?? this.tempoRestanteSegundos,
      tempoEncerrado: tempoEncerrado ?? this.tempoEncerrado,
      mostrarAviso5Minutos: mostrarAviso5Minutos ?? this.mostrarAviso5Minutos,
    );
  }
}

/// 🧠 NOTIFIER: GERENCIADOR DE ESTADO INDEPENDENTE (Clean Architecture)
/// Centraliza a lógica do simulado sem usar BuildContext.
class QuizSessionNotifier extends StateNotifier<QuizSessionState> {
  QuizSessionNotifier() : super(QuizSessionState());

  Timer? _cronometroTimer;

  /// 🚀 1. INICIAR SIMULADO (Com lógica de Sorteio Antirrepetição)
  void iniciarSimulado({
    required String categoriaId,
    required String modoProva,
    String? assunto,
    required List<dynamic> questoesDisponiveisNoBanco,
    required int qtdSolicitada,
    int? tempoMinutos, // nulo se for "Sem Tempo"
  }) {
    // Filtrar questões por Categoria e Assunto (se aplicável)
    List<dynamic> questoesFiltradas = questoesDisponiveisNoBanco.where((q) {
      final bCategoria = q['categoriaId'] == categoriaId;
      if (modoProva == 'assunto' && assunto != null) {
        return bCategoria && q['assuntoId'] == assunto;
      }
      return bCategoria;
    }).toList();

    // 🛡️ REGRA DE NEGÓCIO: Tratamento de Limite Máximo de Questões Cadastradas
    int limiteMaximo = questoesFiltradas.length;
    int qtdFinalAQuizzar = qtdSolicitada > limiteMaximo ? limiteMaximo : qtdSolicitada;

    // 🎲 SISTEMA DE SORTEIO EMBALADO (Não repete na mesma prova)
    questoesFiltradas.shuffle(Random());
    List<dynamic> questoesSorteadas = questoesFiltradas.take(qtdFinalAQuizzar).toList();

    // Configuração inicial do Timer
    int segundosTotais = (tempoMinutos ?? 0) * 60;

    state = QuizSessionState(
      emExecucao: true,
      categoriaId: categoriaId,
      modoProva: modoProva,
      assuntoSelecionado: assunto,
      questoes: questoesSorteadas,
      indiceQuestaoAtual: 0,
      respostasSelecionadas: {},
      tempoRestanteSegundos: segundosTotais,
      tempoEncerrado: false,
      mostrarAviso5Minutos: false,
    );

    // Se tiver tempo configurado, starta o relógio regressivo
    if (tempoMinutos != null && tempoMinutos > 0) {
      _iniciarRelogio();
    }
  }

  /// ⏱️ 2. CONTROLO DO CRONÓMETRO REGRESSIVO
  void _iniciarRelogio() {
    _cronometroTimer?.cancel();
    _cronometroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.tempoRestanteSegundos <= 1) {
        _cronometroTimer?.cancel();
        state = state.copyWith(
          tempoRestanteSegundos: 0,
          tempoEncerrado: true,
        );
        finalizarSimuladoForcado();
      } else {
        int novoTempo = state.tempoRestanteSegundos - 1;
        
        // 🔔 REGRA DOS 5 MINUTOS: Avisa quando faltar exatamente 5 minutos (300 segundos)
        bool aviso5Min = (novoTempo == 300);

        state = state.copyWith(
          tempoRestanteSegundos: novoTempo,
          mostrarAviso5Minutos: aviso5Min,
        );
      }
    });
  }

  /// 🔘 3. SELECIONAR ALTERNATIVA
  void selecionarAlternativa(String questaoId, String alternativaLetra) {
    final novasRespostas = Map<String, String>.from(state.respostasSelecionadas);
    novasRespostas[questaoId] = alternativaLetra;
    
    state = state.copyWith(respostasSelecionadas: novasRespostas);
  }

  /// ⏭️ 4. NAVEGAÇÃO ENTRE QUESTÕES (Avançar / Voltar)
  void proximaQuestao() {
    if (state.indiceQuestaoAtual < state.questoes.length - 1) {
      state = state.copyWith(indiceQuestaoAtual: state.indiceQuestaoAtual + 1);
    }
  }

  void questaoAnterior() {
    if (state.indiceQuestaoAtual > 0) {
      state = state.copyWith(indiceQuestaoAtual: state.indiceQuestaoAtual - 1);
    }
  }

  /// 📴 5. CONSUMIR AVISO DE 5 MINUTOS (Para a mensagem sumir sozinha da tela)
  void limparAviso5Minutos() {
    state = state.copyWith(mostrarAviso5Minutos: false);
  }

  /// 🏁 6. ENCERRAMENTO FORÇADO PELO FIM DO TEMPO
  void finalizarSimuladoForcado() {
    _cronometroTimer?.cancel();
    state = state.copyWith(emExecucao: false);
    // Aqui no futuro dispararemos o mapeamento para levar à tela de resultados
  }

  /// 🛑 7. CANCELAR OU RESETAR SESSÃO
  void resetarSimulado() {
    _cronometroTimer?.cancel();
    state = QuizSessionState();
  }

  @override
  void dispose() {
    _cronometroTimer?.cancel();
    super.dispose();
  }
}

/// 🌍 PROVIDER GLOBAL DISPONÍVEL PARA OS WIDGETS OBSERVADOS
final quizSessionProvider = StateNotifierProvider<QuizSessionNotifier, QuizSessionState>((ref) {
  return QuizSessionNotifier();
});