import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/questao_entity.dart';
import '../../data/repositories/simulado_repository_impl.dart';

// 📋 Essa classe guarda o "estado atual" do simulado na memória do celular
class SimuladoState {
  final List<QuestaoEntity> questoes;
  final int indiceQuestaoAtual;
  final Map<int, int> respostasDoAluno; // Chave: índice da questão, Valor: alternativa marcada
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
        state = state.copyWith(carregando: false, erro: 'Nenhuma questão encontrada para este filtro.');
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
  void finalizarSimulado() {
    int acertos = 0;
    
    for (int i = 0; i < state.questoes.length; i++) {
      final respostaCorreta = state.questoes[i].respostaCorretaIndex;
      final respostaAluno = state.respostasDoAluno[i];
      
      if (respostaAluno == respostaCorreta) {
        acertos++;
      }
    }

    // Calcula a nota proporcional de 0 a 100
    final notaCalculada = ((acertos / state.questoes.length) * 100).round();

    state = state.copyWith(
      finalizado: true,
      notaFinal: notaCalculada,
    );
  }
}

// 🟢 PROVIDER GLOBAL DO CONTROLLER: É ela que a tela vai escutar!
final simuladoControllerProvider = StateNotifierProvider<SimuladoController, SimuladoState>((ref) {
  return SimuladoController(ref);
});