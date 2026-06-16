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
    final double larguraTela = MediaQuery.of(context).size.width;
    final bool isMobile = larguraTela < 600;

    // 🎨 Identidade Visual Rumo Quiz (Cores do Logo)
    final Color verdeEsmeraldaBorda = const Color(0xFF10B981);
    final Color verdeEsmeraldaFundo = const Color(
      0xFFE6F4EA,
    ); // Verde suave adaptado
    final Color laranjaClaroBorda = const Color(0xFFF97316);
    final Color laranjaClaroFundo = const Color(
      0xFFFFF7ED,
    ); // Laranja suave adaptado

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Revisão: $tituloSimulado',
                    style: TextStyle(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Área de Conteúdo Centralizada e Otimizada para Web/Mobile
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: revisaoQuestoes.length,
                    itemBuilder: (context, index) {
                      final revisao = revisaoQuestoes[index];
                      final questao = revisao.questao;

                      final int corretaIndex = questao.respostaCorretaIndex;
                      final int? escolhidaIndex = revisao.opcaoEscolhidaIndex;
                      final bool acertou = escolhidaIndex == corretaIndex;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: 0.5,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. CABEÇALHO: Detalhes da Questão
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: corPrimaria.withValues(
                                        alpha: 0.08,
                                      ),
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
                                      'Assunto: ${questao.assuntoId != 'Geral' ? questao.assuntoId : tituloSimulado}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Referência da Questão
                              Text(
                                'Referência: Banco de Questões Interno Rumo Quiz (${questao.instituicaoId})',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const Divider(
                                height: 24,
                                color: Color(0xFFE5E7EB),
                              ),

                              // 2. DESCRIÇÃO DA QUESTÃO (Enunciado)
                              Text(
                                questao.pergunta,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 3. ALTERNATIVAS DA QUESTÃO (Paleta Rumo Quiz)
                              ...List.generate(questao.opcoes.length, (
                                optIndex,
                              ) {
                                final String textoAlternativa =
                                    questao.opcoes[optIndex];

                                Color corBorda = Colors.grey.shade200;
                                Color corFundo = Colors.white;
                                Widget? iconeResultado;

                                if (optIndex == corretaIndex) {
                                  // Correta: Verde Esmeralda da logo
                                  corBorda = verdeEsmeraldaBorda;
                                  corFundo = verdeEsmeraldaFundo;
                                  iconeResultado = Icon(
                                    Icons.check_circle,
                                    color: verdeEsmeraldaBorda,
                                    size: 20,
                                  );
                                } else if (optIndex == escolhidaIndex &&
                                    !acertou) {
                                  // Errada: Laranja Claro da logo
                                  corBorda = laranjaClaroBorda;
                                  corFundo = laranjaClaroFundo;
                                  iconeResultado = Icon(
                                    Icons.error_rounded,
                                    color: laranjaClaroBorda,
                                    size: 20,
                                  );
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: corFundo,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: corBorda,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Indicador de Letra (A, B, C...)
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            optIndex == corretaIndex
                                            ? verdeEsmeraldaBorda.withValues(
                                                alpha: 0.2,
                                              )
                                            : (optIndex == escolhidaIndex
                                                  ? laranjaClaroBorda
                                                        .withValues(alpha: 0.2)
                                                  : Colors.grey.shade100),
                                        child: Text(
                                          String.fromCharCode(65 + optIndex),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: optIndex == corretaIndex
                                                ? verdeEsmeraldaBorda
                                                : (optIndex == escolhidaIndex
                                                      ? laranjaClaroBorda
                                                      : Colors.grey.shade600),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          textoAlternativa,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color(0xFF374151),
                                            fontWeight:
                                                (optIndex == corretaIndex ||
                                                    optIndex == escolhidaIndex)
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (iconeResultado != null)
                                        iconeResultado,
                                    ],
                                  ),
                                );
                              }),

                              // 4. JUSTIFICATIVA DA QUESTÃO
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.shade200.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
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
                                    // Retornado ao padrão fixo seguro de acordo com o seu modelo de dados
                                    const Text(
                                      'Análise Pedagógica: A alternativa correta atende perfeitamente à problemática do enunciado. As demais opções contêm generalizações ou distorções conceituais que as invalidam.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4B5563),
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
              ),
            ),

            // Botão Inferior de Fechamento (Alinhado e Seguro)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text(
                        'Voltar ao Resumo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corPrimaria,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
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
