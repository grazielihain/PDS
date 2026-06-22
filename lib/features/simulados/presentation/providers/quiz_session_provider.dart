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
  final DateTime? horarioTermino; // 🔥 Adicionado para cálculo de tempo absoluto anti-fraude

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
    this.horarioTermino,
  });

  QuizSessionState copyWith({
    bool? emExecucao,
    String? categoriaId,
    String? modoProva,
    String? assuntoSelecionado, // 🐛 Corrigido erro de digitação de 'asunto' para 'assunto'
    List<dynamic>? questoes,
    int? indiceQuestaoAtual,
    Map<String, String>? respostasSelecionadas,
    int? tempoRestanteSegundos,
    bool? tempoEncerrado,
    bool? mostrarAviso5Minutos,
    DateTime? horarioTermino,
  }) {
    return QuizSessionState(
      emExecucao: emExecucao ?? this.emExecucao,
      categoriaId: categoriaId ?? this.categoriaId,
      modoProva: modoProva ?? this.modoProva,
      assuntoSelecionado: assuntoSelecionado ?? this.assuntoSelecionado,
      questoes: questoes ?? this.questoes,
      indiceQuestaoAtual: indiceQuestaoAtual ?? this.indiceQuestaoAtual,
      respostasSelecionadas: respostasSelecionadas ?? this.respostasSelecionadas,
      tempoRestanteSegundos: tempoRestanteSegundos ?? this.tempoRestanteSegundos,
      tempoEncerrado: tempoEncerrado ?? this.tempoEncerrado,
      mostrarAviso5Minutos: mostrarAviso5Minutos ?? this.mostrarAviso5Minutos,
      horarioTermino: horarioTermino ?? this.horarioTermino,
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
    int? tempoMinutos,
  }) {
    List<dynamic> questoesFiltradas = questoesDisponiveisNoBanco.where((q) {
      final String qCategoriaId = (q is Map) ? (q['categoriaId'] ?? '') : (q.categoriaId ?? '');
      final String qAssuntoId = (q is Map) ? (q['assuntoId'] ?? '') : (q.assuntoId ?? '');

      final bCategoria = qCategoriaId.toLowerCase() == categoriaId.toLowerCase();

      if (modoProva == 'assunto' && assunto != null) {
        return bCategoria && qAssuntoId.toLowerCase() == assunto.toLowerCase();
      }
      return bCategoria;
    }).toList();

    int limiteMaximo = questoesFiltradas.length;
    int qtdFinalAQuizzar = qtdSolicitada > limiteMaximo ? limiteMaximo : qtdSolicitada;

    questoesFiltradas.shuffle(Random());
    List<dynamic> questoesSorteadas = questoesFiltradas.take(qtdFinalAQuizzar).toList();

    DateTime? limiteTermino;
    int segundosTotais = 0;
    if (tempoMinutos != null && tempoMinutos > 0) {
      segundosTotais = tempoMinutos * 60;
      limiteTermino = DateTime.now().add(Duration(minutes: tempoMinutos));
    }

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
      horarioTermino: limiteTermino,
    );

    if (limiteTermino != null) {
      _iniciarRelogioAbsoluto();
    }
  }

  /// 💾 2. RESTAURAÇÃO ATÔMICA LOCAL
  /// Injeta as respostas e o índice de uma vez só para evitar múltiplos salvamentos concorrentes.
  void restaurarEstadoCompleto({
    required Map<String, String> respostas,
    required int indiceAtual,
  }) {
    state = state.copyWith(
      respostasSelecionadas: respostas,
      indiceQuestaoAtual: indiceAtual.clamp(0, state.questoes.isNotEmpty ? state.questoes.length - 1 : 0),
    );
    
    // Se houver um horário de término fixado previamente, reinicia o timer absoluto de segurança
    if (state.horarioTermino != null && _cronometroTimer == null) {
      _iniciarRelogioAbsoluto();
    }
  }

  /// ⏱️ 3. CONTROLE DO CRONÔMETRO REGRESSIVO INALTERÁVEL
  void _iniciarRelogioAbsoluto() {
    _cronometroTimer?.cancel();

    _cronometroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final fim = state.horarioTermino;
      if (fim == null) {
        _cronometroTimer?.cancel();
        return;
      }

      final agora = DateTime.now();

      if (agora.isAfter(fim)) {
        _cronometroTimer?.cancel();
        state = state.copyWith(tempoRestanteSegundos: 0, tempoEncerrado: true);
        finalizarSimuladoForcado();
      } else {
        final diferenca = fim.difference(agora);
        int novosSegundosRestantes = diferenca.inSeconds;

        bool aviso5Min = (novosSegundosRestantes <= 300 && !state.mostrarAviso5Minutos);

        state = state.copyWith(
          tempoRestanteSegundos: novosSegundosRestantes,
          mostrarAviso5Minutos: aviso5Min ? true : state.mostrarAviso5Minutos,
        );
      }
    });
  }

  /// 🔘 4. SELECIONAR ALTERNATIVA
  void selecionarAlternativa(String questaoId, String alternativaLetra) {
    final novasRespostas = Map<String, String>.from(state.respostasSelecionadas);
    novasRespostas[questaoId] = alternativaLetra;
    state = state.copyWith(respostasSelecionadas: novasRespostas);
  }

  /// ⏭️ 5. NAVEGAÇÃO ENTRE QUESTÕES (Avançar / Voltar)
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

  /// 📴 6. CONSUMIR AVISO DE 5 MINUTOS
  void limpiarAviso5Minutos() {
    state = state.copyWith(mostrarAviso5Minutos: false);
  }

  /// 🏁 7. ENCERRAMENTO FORÇADO PELO FIM DO TEMPO
  void finalizarSimuladoForcado() {
    _cronometroTimer?.cancel();
    _cronometroTimer = null;
    state = state.copyWith(emExecucao: false);
  }

  /// 🛑 8. CANCELAR OU RESETAR SESSÃO
  void resetarSimulado() {
    _cronometroTimer?.cancel();
    _cronometroTimer = null;
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
