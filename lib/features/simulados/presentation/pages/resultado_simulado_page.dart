import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/inspecionar_simulado_page.dart';
import 'package:rumo_quiz/features/simulados/services/certificado_service.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';

class ResultadoSimuladoPage extends ConsumerWidget {
  final String nomeDoAluno;
  final String instituicaoDoAluno;
  final String? logoUrl;
  final String tituloSimulado;
  final int totalQuestoes;
  final int acertos;
  final int erros;
  final double notaObtida;
  final double notaMaxima;
  final int pontosGamificacao;
  final double taxaAcerto;
  final String mensagemFinalizacaoAdmin;
  final List<RevisaoQuestaoModel> revisaoQuestoes;
  final int tempoUtilizadoSegundos;

  const ResultadoSimuladoPage({
    Key? key,
    required this.nomeDoAluno,
    required this.instituicaoDoAluno,
    this.logoUrl,
    required this.tituloSimulado,
    required this.totalQuestoes,
    required this.acertos,
    required this.erros,
    required this.notaObtida,
    required this.notaMaxima,
    required this.pontosGamificacao,
    required this.taxaAcerto,
    required this.mensagemFinalizacaoAdmin,
    required this.revisaoQuestoes,
    required this.tempoUtilizadoSegundos,
  }) : super(key: key);

  String _formatarTempo(int segundosTotais) {
    if (segundosTotais <= 0) return '00:00';
    final int horas = segundosTotais ~/ 3600;
    final int minutos = (segundosTotais % 3600) ~/ 60;
    final int segundos = segundosTotais % 60;

    final String minutosStr = minutos.toString().padLeft(2, '0');
    final String segundosStr = segundos.toString().padLeft(2, '0');

    if (horas > 0) {
      return '$horas:$minutosStr:$segundosStr';
    }
    return '$minutosStr:$segundosStr min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎨 CAPTURA DINÂMICA: Pega a cor que a instituição definiu no tema global do app
    final Color corInstitucional = Theme.of(context).colorScheme.primary;
    final Color corSecundariaInstitucional = Theme.of(
      context,
    ).colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors
          .transparent, // Permite que o fundo do MainLayoutShell prevaleça

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SEÇÃO 1: CABEÇALHO DE SUCESSO DO SIMULADO
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 80,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Simulado Concluído!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: corInstitucional, // Aplicado dinamicamente
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Parabéns por finalizar a avaliação, $nomeDoAluno!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // SEÇÃO 2: BOTÕES DE AÇÃO RÁPIDA (Agora 100% baseados na cor da instituição)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildBotaoAcao(
                                context,
                                Icons.find_in_page_outlined,
                                'Inspecionar Prova',
                                corInstitucional,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBotaoAcao(
                                context,
                                Icons.picture_as_pdf_outlined,
                                'Imprimir Certificado',
                                corSecundariaInstitucional, // Variação secundária da instituição
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBotaoVoltar(
                                context,
                                corInstitucional,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildBotaoAcao(
                              context,
                              Icons.find_in_page_outlined,
                              'Inspecionar Prova',
                              corInstitucional,
                            ),
                            const SizedBox(height: 8),
                            _buildBotaoAcao(
                              context,
                              Icons.picture_as_pdf_outlined,
                              'Imprimir Certificado',
                              corSecundariaInstitucional,
                            ),
                            const SizedBox(height: 8),
                            _buildBotaoVoltar(context, corInstitucional),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 36),

                  // SEÇÃO 3: RESUMO METRIFICADO
                  const Text(
                    'Resumo da Prova',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 2.5,
                    children: [
                      _buildCardResumo(
                        'Total Questões',
                        '$totalQuestoes',
                        Colors.grey.shade700,
                      ),
                      _buildCardResumo(
                        'Total Acertos',
                        '$acertos',
                        Colors.green.shade700,
                      ),
                      _buildCardResumo(
                        'Total Erros',
                        '$erros',
                        Colors.red.shade700,
                      ),
                      _buildCardResumo(
                        'Nota Obtida',
                        '${notaObtida.toStringAsFixed(1)} / $notaMaxima pts',
                        corInstitucional, // Aplicado dinamicamente
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildCardResumo(
                          'Gamificação',
                          '+$pontosGamificacao XP',
                          Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildCardResumo(
                          'Tempo Decorrido',
                          _formatarTempo(tempoUtilizadoSegundos),
                          Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // SEÇÃO 4: BARRAS DE TAXA DE ACERTO
                  const Text(
                    'Métricas de Aproveitamento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Taxa de Acerto: ${taxaAcerto.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$acertos / $totalQuestoes Questões',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: taxaAcerto / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: taxaAcerto >= 70 ? Colors.green : Colors.orange,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 32),

                  // SEÇÃO 5: MENSAGEM DO ADMINISTRADOR
                  if (mensagemFinalizacaoAdmin.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: corInstitucional.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: corInstitucional.withValues(alpha: 0.2),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.gavel,
                                color: corInstitucional,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mensagem da Coordenação / Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: corInstitucional,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            mensagemFinalizacaoAdmin,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoAcao(
    BuildContext context,
    IconData icon,
    String label,
    Color cor,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          if (label.contains('Certificado')) {
            await CertificadoService.gerarEImprimirCertificado(
              tituloProva: tituloSimulado,
              acertos: acertos,
              totalQuestoes: totalQuestoes,
              notaObtida: notaObtida,
              notaMaxima: notaMaxima,
              nomeAluno: nomeDoAluno,
              nomeInstiticao: instituicaoDoAluno,
              logoUrl: logoUrl,
            );
          } else if (label.contains('Inspecionar') || label.contains('Prova')) {
            for (var rev in revisaoQuestoes) {
              print(
                'Questão ID: ${rev.questao.id} | Escolhida: ${rev.opcaoEscolhidaIndex} | Correta: ${rev.questao.respostaCorretaIndex}',
              );
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspecionarSimuladoPage(
                  tituloSimulado: tituloSimulado,
                  revisaoQuestoes: revisaoQuestoes,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBotaoVoltar(BuildContext context, Color corInstitucional) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.history),
        label: const Text(
          'Voltar ao Histórico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: corInstitucional),
          foregroundColor: corInstitucional,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => context.go('/historico'),
      ),
    );
  }

  Widget _buildCardResumo(String titulo, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
