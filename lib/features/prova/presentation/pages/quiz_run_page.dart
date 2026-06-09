import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/prova_model.dart';
import '../../domain/models/questao_model.dart';
import '../../data/providers/prova_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/historico_model.dart';

class QuizRunPage extends ConsumerStatefulWidget {
  final ProvaModel prova;

  const QuizRunPage({super.key, required this.prova});

  @override
  ConsumerState<QuizRunPage> createState() => _QuizRunPageState();
}

class _QuizRunPageState extends ConsumerState<QuizRunPage> {
  int _perguntaAtualIndex = 0;

  // REGRA DE NEGÓCIO: Armazena o gabarito escolhido pelo aluno para cada questão.
  // A chave (key) é o índice da pergunta, o valor (value) é a alternativa que ele escolheu.
  final Map<int, int> _gabaritoAluno = {};

  // Variáveis do Cronômetro
  late int _tempoRestanteSegundos;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final minutos = widget.prova.tempoEmMinutos > 0
        ? widget.prova.tempoEmMinutos
        : 20;
    _tempoRestanteSegundos = minutos * 60;
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
      } else {
        _timer?.cancel();
        // Se o tempo esgotar, passamos uma lista vazia ou buscamos as questões para computar o que deu tempo
        _finalizarQuizComCalculo(questoes: [], tempoEsgotado: true);
      }
    });
  }

  String _formatarTempo(int segundosTotais) {
    final minutos = segundosTotais ~/ 60;
    final segundos = segundosTotais % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  // Aluno escolhe ou troca a resposta da questão atual livremente
  void _selecionarOpcao(int indexSelecionado) {
    setState(() {
      _gabaritoAluno[_perguntaAtualIndex] = indexSelecionado;
    });
  }

  // Avança para a próxima tela sem somar pontos ainda
  void _avancarQuestao() {
    setState(() {
      _perguntaAtualIndex++;
    });
  }

  // REGRA DE NEGÓCIO ATUALIZADA: Calcula e grava o histórico no Firebase automaticamente
  void _finalizarQuizComCalculo({
    required List<QuestaoModel> questoes,
    required bool tempoEsgotado,
  }) async {
    _timer?.cancel();
    int respostasCorretas = 0;

    // 1. Faz o cálculo dos acertos igualzinho estava antes
    if (questoes.isNotEmpty) {
      for (int i = 0; i < questoes.length; i++) {
        final escolhaDoAluno = _gabaritoAluno[i];
        final respostaCertaDoBanco = questoes[i].respostaCorretaIndex;

        if (escolhaDoAluno == respostaCertaDoBanco) {
          respostasCorretas++;
        }
      }
    }

    // 2. NOVIDADE: Recupera o aluno logado e envia o histórico para o banco
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final novoHistorico = HistoricoModel(
          id: '', // O Firebase vai gerar o ID automático
          alunoId: user.uid,
          provaId: widget.prova.id,
          tituloProva: widget.prova.titulo,
          acertos: respostasCorretas,
          totalQuestoes: questoes.length,
          dataHora: DateTime.now(),
        );

        // Executa a função do provider para persistir o dado
        await ref.read(salvarHistoricoProvider)(novoHistorico);
      }
    } catch (e) {
      // Se houver erro de conexão, avisa o desenvolvedor no terminal sem travar a experiência do usuário
      debugPrint('Erro ao salvar histórico: $e');
    }

    // 3. Abre o modal de feedback na tela do aluno após o salvamento seguro
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(tempoEsgotado ? 'Tempo Esgotado!' : 'Quiz Concluído!'),
        content: Text(
          'Você acertou $respostasCorretas de ${questoes.length} questões.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o modal
              Navigator.of(context).pop(); // Volta para a lista de provas
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
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatarTempo(_tempoRestanteSegundos),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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

          final questaoAtual = questoes[_perguntaAtualIndex];
          // Verifica qual opção está gravada no gabarito para a página atual (pode ser nulo se não clicou)
          final opcaoSelecionadaIndex = _gabaritoAluno[_perguntaAtualIndex];
          final ehUltimaQuestao = _perguntaAtualIndex == questoes.length - 1;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Questão ${_perguntaAtualIndex + 1} de ${questoes.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
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

                // Lista de Opções
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

                // Botão Avançar / Finalizar Prova
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  // Bloqueia avanço se o aluno não escolheu nada na tela atual
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
