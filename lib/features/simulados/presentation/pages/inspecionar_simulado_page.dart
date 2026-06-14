import 'package:flutter/material.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';

class InspecionarSimuladoPage extends StatelessWidget {
  final String tituloSimulado;
  final List<RevisaoQuestaoModel> revisaoQuestoes;

  const InspecionarSimuladoPage({
    super.key,
    required this.tituloSimulado,
    required this.revisaoQuestoes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revisão: $tituloSimulado'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: revisaoQuestoes.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma questão encontrada para revisão.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: revisaoQuestoes.length,
              itemBuilder: (context, index) {
                final revisao = revisaoQuestoes[index];
                final questao = revisao.questao;

                final int respostaCorreta = questao.respostaCorretaIndex;
                final int? respostaAluno = revisao.opcaoEscolhidaIndex;

                return Card(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. CABEÇALHO DA QUESTÃO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Questão ${index + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (respostaAluno == respostaCorreta)
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (respostaAluno == respostaCorreta)
                                    ? 'Acertou'
                                    : 'Errou',
                                style: TextStyle(
                                  color: (respostaAluno == respostaCorreta)
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Assunto/Referência: $tituloSimulado',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Divider(height: 20),

                        // 2. ENUNCIADO
                        Text(
                          questao.pergunta,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. ALTERNATIVAS
                        Column(
                          children: List.generate(questao.opcoes.length, (i) {
                            final alternativaTexto = questao.opcoes[i];

                            Color boxColor = Colors.white;
                            Color borderColor = Colors.grey.shade300;
                            Color textColor = Colors.black87;
                            Widget? trailingIcon;

                            if (i == respostaCorreta) {
                              boxColor = Colors.green.shade50;
                              borderColor = Colors.green.shade400;
                              textColor = Colors.green.shade900;
                              trailingIcon = const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              );
                            } else if (i == respostaAluno &&
                                respostaAluno != respostaCorreta) {
                              boxColor = Colors.red.shade50;
                              borderColor = Colors.red.shade400;
                              textColor = Colors.red.shade900;
                              trailingIcon = const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: boxColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: borderColor,
                                    child: Text(
                                      String.fromCharCode(65 + i),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      alternativaTexto,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 15,
                                        fontWeight: (i == respostaCorreta ||
                                                i == respostaAluno)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (trailingIcon != null) trailingIcon,
                                ],
                              ),
                            );
                          }),
                        ),

                        // 4. JUSTIFICATIVA DINÂMICA
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.amber.shade900,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Explicação / Justificativa:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                // Procura a justificativa no modelo, se nula usa a mensagem padrão
                                (questao as dynamic).justificativa ?? 
                                'Analise as alternativas acima com base nos critérios de eliminação do edital. A resposta correta aborda a teoria de forma direta.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}