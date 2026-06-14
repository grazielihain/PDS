import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/questao_model.dart';
import '../../data/models/revisao_questao_model.dart';
import '../controllers/simulado_controller.dart';
import '../providers/quiz_session_provider.dart';

class SimuladoPage extends ConsumerWidget {
  const SimuladoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧠 1. Escuta o estado da Sessão Ativa (Nomes idênticos ao seu QuizSessionState)
    final sessionState = ref.watch(quizSessionProvider);
    final sessionNotifier = ref.read(quizSessionProvider.notifier);

    // 🔄 2. Escuta o Controller de Gravação do Firebase
    final controllerState = ref.watch(simuladoControllerProvider);
    final controllerNotifier = ref.read(simuladoControllerProvider.notifier);

    // ⏳ Tela de Carregamento Assíncrono do Controller (Gravando no Firestore)
    if (controllerState is AsyncLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Gravando seu histórico de simulados...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    // ❌ Tela de Erro de Conexão ou Gravação
    if (controllerState is AsyncError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Erro ao processar simulado: ${controllerState.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/quiz-selection'),
                  child: const Text('Voltar para Início'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 🛑 Tratamento caso a lista de questões esteja vazia
    if (sessionState.questoes.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Nenhuma questão carregada para este simulado.'),
        ),
      );
    }

    // ✅ Cast seguro de dynamic para QuestaoModel usando os nomes reais do seu estado
    final questaoAtual =
        sessionState.questoes[sessionState.indiceQuestaoAtual] as QuestaoModel;
    final respostaSelecionadaTexto =
        sessionState.respostasSelecionadas[questaoAtual.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Questão ${sessionState.indiceQuestaoAtual + 1} de ${sessionState.questoes.length}',
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enunciado da Pergunta
            Text(
              questaoAtual.pergunta,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // Lista de Alternativas (A, B, C, D...)
            Expanded(
              child: ListView.builder(
                itemCount: questaoAtual.opcoes.length,
                itemBuilder: (context, index) {
                  final opcaoTexto = questaoAtual.opcoes[index];
                  final estaSelecionado =
                      respostaSelecionadaTexto == opcaoTexto;

                  return Card(
                    color: estaSelecionado ? Colors.blue.shade100 : null,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(String.fromCharCode(65 + index)),
                      ),
                      title: Text(opcaoTexto),
                      trailing: estaSelecionado
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                      onTap: () {
                        // ✅ Chamando a função exata do seu Notifier
                        sessionNotifier.selecionarAlternativa(
                          questaoAtual.id,
                          opcaoTexto,
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Botões de Navegação (Voltar, Avançar, Finalizar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  // ✅ Usando 'indiceQuestaoAtual' e 'questaoAnterior' do seu provider
                  onPressed: sessionState.indiceQuestaoAtual > 0
                      ? sessionNotifier.questaoAnterior
                      : null,
                  child: const Text('Anterior'),
                ),
                if (sessionState.indiceQuestaoAtual ==
                    sessionState.questoes.length - 1)
                  ElevatedButton(
                    onPressed: () async {
                      // 1. Mostra um feedback visual imediato no console para sabermos que o clique funcionou
                      debugPrint('======= BOTÃO FINALIZAR CLICADO =======');

                      int totalAcertos = 0;
                      List<Map<String, dynamic>> listaRevisaoJson = [];

                      try {
                        for (var item in sessionState.questoes) {
                          // Tratamento dinâmico para evitar qualquer quebra de classe
                          final dynamic q = item;
                          final String questaoId = q.id ?? '';
                          final List<String> opcoes = List<String>.from(
                            q.opcoes ?? [],
                          );
                          final int respostaCerta = q.respostaCorretaIndex ?? 0;

                          final respAluno =
                              sessionState.respostasSelecionadas[questaoId];
                          final int indexAluno = respAluno != null
                              ? opcoes.indexOf(respAluno)
                              : -1;

                          if (indexAluno != -1 && indexAluno == respostaCerta) {
                            totalAcertos++;
                          }

                          listaRevisaoJson.add({
                            'opcaoEscolhidaIndex': indexAluno == -1
                                ? null
                                : indexAluno,
                            'questao': {
                              'id': questaoId,
                              'pergunta': q.pergunta ?? '',
                              'opcoes': opcoes,
                              'respostaCorretaIndex': respostaCerta,
                              'nota': q.nota ?? 1.0,
                            },
                          });
                        }
                      } catch (e) {
                        debugPrint('Erro no mapeamento local das questões: $e');
                      }

                      double notaCalculada = sessionState.questoes.isNotEmpty
                          ? (totalAcertos / sessionState.questoes.length) * 10.0
                          : 0.0;

                      debugPrint(
                        'Acertos calculados: $totalAcertos | Nota: $notaCalculada',
                      );

                      // 2. Envio para gravação envelopado em try/catch para não travar a navegação da tela
                      try {
                        await controllerNotifier.finalizarEGravarSimulado(
                          // Converte a lista genérica de volta para a lista estrita de QuestaoModel
                          questoesDaProva: sessionState.questoes
                              .map((item) => item as QuestaoModel)
                              .toList(),
                          respostasAluno: sessionState.respostasSelecionadas,
                          notaCalculada: notaCalculada,
                          totalAcertos: totalAcertos,
                          // Reconstrói o modelo de revisão esperado pelo controller/Firestore usando o histórico que você mandou
                          listaRevisao: sessionState.questoes.map((item) {
                            final q = item as QuestaoModel;
                            final respAluno =
                                sessionState.respostasSelecionadas[q.id];
                            final int indexAluno = respAluno != null
                                ? q.opcoes.indexOf(respAluno)
                                : -1;

                            return RevisaoQuestaoModel(
                              questao: q,
                              opcaoEscolhidaIndex: indexAluno == -1
                                  ? null
                                  : indexAluno,
                            );
                          }).toList(),
                        );
                        debugPrint(
                          'Gravação no Firebase concluída com sucesso!',
                        );
                      } catch (erroFirebase) {
                        debugPrint(
                          'Aviso: Erro ao persistir no banco (mas avançando): $erroFirebase',
                        );
                      }

                      // 3. Força a navegação para a tela de resultados de forma garantida
                      if (context.mounted) {
                        debugPrint('Redirecionando para /resultado...');
                        context.go(
                          '/resultado',
                          extra: {
                            'questoes': sessionState.questoes,
                            'acertos': totalAcertos,
                            'totalQuestoes': sessionState.questoes.length,
                            'NotaObtida': notaCalculada,
                            'categoria': sessionState.categoriaId,
                            'revisaoQuestoes': listaRevisaoJson,
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Finalizar Simulado',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  ElevatedButton(
                    // ✅ Usando 'proximaQuestao' do seu provider
                    onPressed: sessionNotifier.proximaQuestao,
                    child: const Text('Próxima'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
