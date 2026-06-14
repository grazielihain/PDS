import 'package:flutter/material.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';

class InspecionarSimuladoPage extends StatelessWidget {
  final String tituloSimulado;
  final List<RevisaoQuestaoModel> revisaoQuestoes;

  const InspecionarSimuladoPage({
    Key? key,
    required this.tituloSimulado,
    required this.revisaoQuestoes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color corPrimaria = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Área de Conteúdo com Rolagem
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: revisaoQuestoes.length,
                itemBuilder: (context, index) {
                  final revisao = revisaoQuestoes[index];
                  final questao = revisao.questao;

                  // Identificando as respostas
                  final int corretaIndex = questao.respostaCorretaIndex;
                  final int? escolhidaIndex = revisao.opcaoEscolhidaIndex;
                  final bool acertou = escolhidaIndex == corretaIndex;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      // ✅ CORRIGIDO: Trocado 'customProperties' pela estrutura nativa 'child: Column'
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. CABEÇALHO: Detalhes da Questão (Tipo de Prova, Assunto, Referência)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: corPrimaria.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Questão ${index + 1}',
                                  style: TextStyle(
                                    color: corPrimaria,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  // Exibe o assunto/categoria se mapeados, senão usa o título geral
                                  'Assunto: ${questao.assuntoId != 'Geral' ? questao.assuntoId : tituloSimulado}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Referência da Questão
                          Text(
                            'Referência: Banco de Questões Interno Rumo Quiz (${questao.instituicaoId})',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Divider(height: 24),

                          // 2. DESCRIÇÃO DA QUESTÃO (Enunciado)
                          Text(
                            questao.pergunta,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. ALTERNATIVAS DA QUESTÃO (Com validação de cores)
                          ...List.generate(questao.opcoes.length, (optIndex) {
                            final String textoAlternativa =
                                questao.opcoes[optIndex];

                            // Regras de colorização cirúrgica:
                            Color corBorda = Colors.grey.shade300;
                            Color corFundo = Colors.white;
                            Widget? iconeResultado;

                            if (optIndex == corretaIndex) {
                              // A correta SEMPRE fica verde
                              corBorda = Colors.green.shade600;
                              corFundo = Colors.green.shade50;
                              iconeResultado = const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              );
                            } else if (optIndex == escolhidaIndex && !acertou) {
                              // Se o aluno escolheu esta e estava errada, fica vermelha
                              corBorda = Colors.red.shade600;
                              corFundo = Colors.red.shade50;
                              iconeResultado = const Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 20,
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: corFundo,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: corBorda, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      textoAlternativa,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            (optIndex == corretaIndex ||
                                                optIndex == escolhidaIndex)
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (iconeResultado != null) iconeResultado,
                                ],
                              ),
                            );
                          }),

                          // 4. JUSTIFICATIVA DA QUESTÃO
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 18,
                                      color: Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Justificativa Comentada:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Análise Pedagógica: A alternativa correta resolve a problemática do enunciado de acordo com as diretrizes do edital. As demais opções contêm generalizações ou distorções conceituais que as eliminam.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4,
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
            ),

            // Botão Inferior para fechar a inspeção e voltar ao resultado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrimaria,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Voltar ao Resumo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
