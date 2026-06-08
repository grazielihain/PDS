import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/prova_model.dart';
import '../../data/providers/prova_provider.dart';

class QuizRunPage extends ConsumerStatefulWidget {
  final ProvaModel prova;

  const QuizRunPage({super.key, required this.prova});

  @override
  ConsumerState<QuizRunPage> createState() => _QuizRunPageState();
}

class _QuizRunPageState extends ConsumerState<QuizRunPage> {
  int _perguntaAtualIndex = 0;
  int _respostasCorretas = 0;
  int? _opcaoSelecionadaIndex;

  // Variáveis do Cronômetro
  late int _tempoRestanteSegundos;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Pega o tempo em minutos. Se por acaso for 0 ou nulo, garante pelo menos 20 minutos por segurança
    final minutos = widget.prova.tempoEmMinutos > 0
        ? widget.prova.tempoEmMinutos
        : 20;

    // Converte para segundos
    _tempoRestanteSegundos = minutos * 60;

    // Só inicia o cronômetro se tivermos tempo configurado
    if (_tempoRestanteSegundos > 0) {
      _iniciarCronometro();
    }
  }

  void _iniciarCronometro() {
    _timer?.cancel(); // Cancela qualquer timer antigo antes de começar um novo

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted)
        return; // Garante que a tela ainda está aberta antes de atualizar o estado

      if (_tempoRestanteSegundos > 0) {
        setState(() {
          _tempoRestanteSegundos--;
        });
      } else {
        _timer?.cancel();
        _finalizarQuiz(tempoEsgotado: true);
      }
    });
  }

  String _formatarTempo(int segundosTotais) {
    final minutos = segundosTotais ~/ 60;
    final segundos = segundosTotais % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  void _responder(int indexSelecionado, int indexCorreto) {
    if (_opcaoSelecionadaIndex != null)
      return; // Impede responder duas vezes a mesma pergunta

    setState(() {
      _opcaoSelecionadaIndex = indexSelecionado;
      if (indexSelecionado == indexCorreto) {
        _respostasCorretas++;
      }
    });
  }

  void _proximaPergunta(int totalQuestoes) {
    if (_perguntaAtualIndex < totalQuestoes - 1) {
      setState(() {
        _perguntaAtualIndex++;
        _opcaoSelecionadaIndex = null; // Reseta a seleção para a próxima tela
      });
    } else {
      _finalizarQuiz(tempoEsgotado: false);
    }
  }

  void _finalizarQuiz({required bool tempoEsgotado}) {
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(tempoEsgotado ? 'Tempo Esgotado!' : 'Quiz Concluído!'),
        content: Text('Você acertou $_respostasCorretas questões.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o modal
              Navigator.of(context).pop(); // Volta para a tela de listagem
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
    // Busca as questões da subcoleção usando o provider que criamos no Passo 3
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indicador de progresso (Ex: Pergunta 1 de 5)
                Text(
                  'Questão ${_perguntaAtualIndex + 1} de ${questoes.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Enunciado da Questão
                Text(
                  questaoAtual.pergunta,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                // Lista de Opções (Alternativas)
                Expanded(
                  child: ListView.builder(
                    itemCount: questaoAtual.opcoes.length,
                    itemBuilder: (context, index) {
                      final opcao = questaoAtual.opcoes[index];
                      final foiRespondido = _opcaoSelecionadaIndex != null;
                      final ehEstaOpcao = _opcaoSelecionadaIndex == index;
                      final ehCorreta =
                          questaoAtual.respostaCorretaIndex == index;

                      // Lógica de cores após o clique
                      Color corBotao = Colors.white;
                      if (foiRespondido) {
                        if (ehCorreta) {
                          corBotao =
                              Colors.green.shade100; // Mostra a certa em verde
                        } else if (ehEstaOpcao) {
                          corBotao = Colors
                              .red
                              .shade100; // Se errou, mostra em vermelho
                        }
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
                                color: foiRespondido && ehCorreta
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                          onPressed: () => _responder(
                            index,
                            questaoAtual.respostaCorretaIndex,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              opcao,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Botão Avançar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _opcaoSelecionadaIndex == null
                      ? null // Fica desabilitado até o aluno escolher uma opção
                      : () => _proximaPergunta(questoes.length),
                  child: Text(
                    _perguntaAtualIndex == questoes.length - 1
                        ? 'Finalizar'
                        : 'Próxima Questão',
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
