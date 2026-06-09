import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/prova_model.dart';
import '../../domain/models/questao_model.dart';
import '../../domain/models/historico_model.dart';
import '../../data/providers/prova_provider.dart';

class QuizRunPage extends ConsumerStatefulWidget {
  final ProvaModel prova;

  const QuizRunPage({super.key, required this.prova});

  @override
  ConsumerState<QuizRunPage> createState() => _QuizRunPageState();
}

class _QuizRunPageState extends ConsumerState<QuizRunPage>
    with SingleTickerProviderStateMixin {
  int _perguntaAtualIndex = 0;
  final Map<int, int> _gabaritoAluno = {};
  late AnimationController _animationController;

  // Lista de controle local para capturar as questões quando o Stream/Future carregar
  List<QuestaoModel> _questoesCarregadas = [];

  late int _tempoRestanteSegundos;
  Timer? _timer;
  bool _alertaCincoMinutosDisparado = false;

  @override
  void initState() {
    super.initState();
    final minutos = widget.prova.tempoEmMinutos > 0
        ? widget.prova.tempoEmMinutos
        : 20;
    _tempoRestanteSegundos = minutos * 60;

    // Inicializa a animação de pulso (vai ficar repetindo de 0.3 a 1.0 de opacidade)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    if (_tempoRestanteSegundos > 0) {
      _iniciarCronometro();
    }
  }

  void _iniciarCronometro() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_tempoRestanteSegundos > 0) {
        setState(() {
          _tempoRestanteSegundos--;
        });

        // REGRA DE NEGÓCIO: Alerta ao chegar em 5 minutos (300 segundos)
        if (_tempoRestanteSegundos == 300 && !_alertaCincoMinutosDisparado) {
          _alertaCincoMinutosDisparado = true;
          _exibirAlertaTempoRestante();
        }
      } else {
        _timer?.cancel();
        // CORREÇÃO: Passa as questões carregadas para computar a opção atual da tela antes de fechar
        _finalizarQuizComCalculo(
          questoes: _questoesCarregadas,
          tempoEsgotado: true,
        );
      }
    });
  }

  void _exibirAlertaTempoRestante() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Atenção: Restam apenas 5 minutos para finalizar a prova!',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }

  String _formatarTempo(int segundosTotais) {
    final minutos = segundosTotais ~/ 60;
    final segundos = segundosTotais % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  void _selecionarOpcao(int indexSelecionado) {
    setState(() {
      _gabaritoAluno[_perguntaAtualIndex] = indexSelecionado;
    });
  }

  void _avancarQuestao() {
    setState(() {
      _perguntaAtualIndex++;
    });
  }

  // REGRA DE NEGÓCIO ATUALIZADA: Computa acertos E soma as pontuações/pesos das notas
  void _finalizarQuizComCalculo({
    required List<QuestaoModel> questoes,
    required bool tempoEsgotado,
  }) async {
    _timer?.cancel();
    int respostasCorretas = 0;
    double notaObtida = 0.0;
    double notaMaximaPossivel = 0.0;

    if (questoes.isNotEmpty) {
      for (int i = 0; i < questoes.length; i++) {
        final escolhaDoAluno = _gabaritoAluno[i];
        final respostaCertaDoBanco = questoes[i].respostaCorretaIndex;

        notaMaximaPossivel += questoes[i].nota;

        if (escolhaDoAluno == respostaCertaDoBanco) {
          respostasCorretas++;
          notaObtida +=
              questoes[i].nota; // Soma o peso específico da questão acertada
        }
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final novoHistorico = HistoricoModel(
          id: '',
          alunoId: user.uid,
          provaId: widget.prova.id,
          tituloProva: widget.prova.titulo,
          acertos: respostasCorretas,
          totalQuestoes: questoes.length,
          notaObtida: notaObtida,
          notaMaxima: notaMaximaPossivel,
          dataHora: DateTime.now(),
        );

        await ref.read(salvarHistoricoProvider)(novoHistorico);
      }
    } catch (e) {
      debugPrint('Erro ao salvar histórico: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(tempoEsgotado ? 'Tempo Esgotado!' : 'Quiz Concluído!'),
        content: Text(
          'Você acertou $respostasCorretas de ${questoes.length} questões.\n'
          'Pontuação Final: ${notaObtida.toStringAsFixed(1)} de ${notaMaximaPossivel.toStringAsFixed(1)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questoesAsyncValue = ref.watch(
      listaQuestoesProvider(widget.prova.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prova.titulo),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                // Cria um fundo arredondado e suave para o cronômetro, estilo "badge" de app premium
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _tempoRestanteSegundos <= 300
                      ? Colors.amber.shade900.withOpacity(
                          0.3,
                        ) // Fundo sutil se o tempo estiver acabando
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Se o tempo for menor que 5 min, o ícone ganha um efeito "pulsante" de opacidade
                    _tempoRestanteSegundos <= 300
                        ? FadeTransition(
                            opacity: _animationController,
                            child: const Icon(
                              Icons.timer,
                              color: Colors.amberAccent,
                              size: 20,
                            ),
                          )
                        : const Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: 20,
                          ),
                    const SizedBox(width: 6),
                    Text(
                      _formatarTempo(_tempoRestanteSegundos),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        // Texto ganha uma cor âmbar suave e iluminada se o tempo estiver no fim
                        color: _tempoRestanteSegundos <= 300
                            ? Colors.amberAccent
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: questoesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Erro ao carregar questões: $err')),
        data: (questoes) {
          if (questoes.isEmpty) {
            return const Center(
              child: Text('Esta prova ainda não possui questões cadastradas.'),
            );
          }

          // Alimenta a nossa lista local para o Timer ter acesso em caso de estouro de tempo
          _questoesCarregadas = questoes;

          final questaoAtual = questoes[_perguntaAtualIndex];
          final opcaoSelecionadaIndex = _gabaritoAluno[_perguntaAtualIndex];
          final ehUltimaQuestao = _perguntaAtualIndex == questoes.length - 1;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questão ${_perguntaAtualIndex + 1} de ${questoes.length}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Exibe o peso/nota da questão atual no topo da pergunta
                    Text(
                      'Valor: ${questaoAtual.nota.toStringAsFixed(1)} pts',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  questaoAtual.pergunta,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: ListView.builder(
                    itemCount: questaoAtual.opcoes.length,
                    itemBuilder: (context, index) {
                      final opcao = questaoAtual.opcoes[index];
                      final ehEstaOpcao = opcaoSelecionadaIndex == index;

                      Color corBotao = Colors.white;
                      Color corBorda = Colors.grey.shade300;

                      if (ehEstaOpcao) {
                        corBotao = Colors.blue.shade50;
                        corBorda = Colors.blue.shade700;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corBotao,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: corBorda,
                                width: ehEstaOpcao ? 2 : 1,
                              ),
                            ),
                          ),
                          onPressed: () => _selecionarOpcao(index),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              opcao,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: ehEstaOpcao
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: opcaoSelecionadaIndex == null
                      ? null
                      : () {
                          if (ehUltimaQuestao) {
                            _finalizarQuizComCalculo(
                              questoes: questoes,
                              tempoEsgotado: false,
                            );
                          } else {
                            _avancarQuestao();
                          }
                        },
                  child: Text(
                    ehUltimaQuestao ? 'Finalizar Prova' : 'Próxima Questão',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
