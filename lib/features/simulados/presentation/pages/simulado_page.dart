import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/simulado_controller.dart';

class SimuladoPage extends ConsumerWidget {
  const SimuladoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🟡 Escuta o estado do simulado em tempo real
    final state = ref.watch(simuladoControllerProvider);
    final controller = ref.read(simuladoControllerProvider.notifier);

    // 1. Tela de Carregamento
    if (state.carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Tela de Erro (Se não encontrar questões ou cair a internet)
    if (state.erro != null) {
      return Scaffold(
        body: Center(
          child: Text(
            state.erro!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 3. Tela de Resultado Final (Quando o aluno clica em finalizar)
    if (state.finalizado) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado do Simulado')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🎉 Simulado Concluído!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sua Nota: ${state.notaFinal}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: state.notaFinal >= 70 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // 🟢 Manda o GoRouter levar o usuário de volta para a aba de seleção de Quizzes de forma limpa!
                    context.go('/quiz-selection');
                  },
                  child: const Text('Voltar para o Início'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 4. Tela de Execução da Prova (Se houver questões carregadas)
    if (state.questoes.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Nenhum simulado ativo.')),
      );
    }

    final questaoAtual = state.questoes[state.indiceQuestaoAtual];
    final respostaSelecionada =
        state.respostasDoAluno[state.indiceQuestaoAtual];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Questão ${state.indiceQuestaoAtual + 1} de ${state.questoes.length}',
        ),
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
                  final estaSelecionado = respostaSelecionada == index;

                  return Card(
                    color: estaSelecionado ? Colors.blue.shade100 : null,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          String.fromCharCode(65 + index),
                        ), // Transforma 0 em A, 1 em B...
                      ),
                      title: Text(questaoAtual.opcoes[index]),
                      trailing: estaSelecionado
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                      onTap: () => controller.selecionarAlternativa(index),
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
                  onPressed: state.indiceQuestaoAtual > 0
                      ? controller.questaoAnterior
                      : null,
                  child: const Text('Anterior'),
                ),
                if (state.indiceQuestaoAtual == state.questoes.length - 1)
                  ElevatedButton(
                    onPressed: respostaSelecionada != null
                        ? controller.finalizarSimulado
                        : null,
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
                    onPressed: respostaSelecionada != null
                        ? controller.proximaQuestao
                        : null,
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
