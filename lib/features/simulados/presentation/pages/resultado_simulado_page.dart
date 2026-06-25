import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/inspecionar_simulado_page.dart';
import 'package:rumo_quiz/features/simulados/services/certificado_service.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';

class ResultadoSimuladoPage extends StatelessWidget {
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
  final bool isPorAssunto;

  const ResultadoSimuladoPage({
    super.key,
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
    this.isPorAssunto = false,
  });

  String _formatarTempo(int segundosTotais) {
    if (segundosTotais <= 0) return '00:00:00';
    final int horas = segundosTotais ~/ 3600;
    final int minutos = (segundosTotais % 3600) ~/ 60;
    final int segundos = segundosTotais % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color corInstitucional = const Color(0xFF1E3A8A);
    final Color corSecundariaInstitucional = Theme.of(context).colorScheme.secondary;

    final bool provaPorAssunto = isPorAssunto;
    final double larguraTela = MediaQuery.of(context).size.width;
    final bool isMobile = larguraTela < 600;

    // 🎨 Cores Oficiais da Identidade Rumo Quiz (Verde Esmeralda e Laranja Claro)
    final Color verdeEsmeralda = const Color(0xFF10B981);
    final Color laranjaClaro = const Color(0xFFF97316);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.school, color: Color(0xFF1E3A8A), size: 28),
            const SizedBox(width: 8),
            Text(
              'Rumo Quiz',
              style: TextStyle(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 18 : 22,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SEÇÃO 1: CABEÇALHO DE SUCESSO
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: verdeEsmeralda.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 72,
                            color: verdeEsmeralda,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Simulado Concluído!',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Parabéns por finalizar a avaliação, $nomeDoAluno!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // SEÇÃO 2: BOTÕES DE AÇÃO RÁPIDA
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
                                isPorAssunto: provaPorAssunto,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBotaoAcao(
                                context,
                                Icons.picture_as_pdf_outlined,
                                'Imprimir Certificado',
                                corSecundariaInstitucional,
                                isPorAssunto: provaPorAssunto,
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
                              isPorAssunto: provaPorAssunto,
                            ),
                            const SizedBox(height: 10),
                            _buildBotaoAcao(
                              context,
                              Icons.picture_as_pdf_outlined,
                              'Imprimir Certificado',
                              corSecundariaInstitucional,
                              isPorAssunto: provaPorAssunto,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBotaoVoltar(context, corInstitucional),
                  
                  const SizedBox(height: 36),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 28),

                  // SEÇÃO 3: RESUMO METRIFICADO (REGRAS VINCULADAS AO TIPO DE PROVA)
                  const Text(
                    'Resumo do Desempenho',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      final valorPontos = provaPorAssunto ? '★' : '${notaObtida.toStringAsFixed(1)} / $notaMaxima';

                      if (isWide) {
                        Widget buildExpandedCard(String titulo, String valor, Color corTexto, Color corFundo) {
                          return Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: corFundo,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: corTexto.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTexto)),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                buildExpandedCard('Questões', '$totalQuestoes', Colors.grey.shade700, Colors.grey.shade100),
                                const SizedBox(width: 12),
                                buildExpandedCard('Acertos', '$acertos', verdeEsmeralda, verdeEsmeralda.withValues(alpha: 0.08)),
                                const SizedBox(width: 12),
                                buildExpandedCard('Erros', '$erros', laranjaClaro, laranjaClaro.withValues(alpha: 0.08)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                buildExpandedCard('Pontos de Prova', valorPontos, corInstitucional, corInstitucional.withValues(alpha: 0.04)),
                                const SizedBox(width: 12),
                                buildExpandedCard('Pontuação Acumulada', '+$pontosGamificacao XP', Colors.amber.shade900, Colors.amber.shade50),
                                const SizedBox(width: 12),
                                buildExpandedCard('Tempo Decorrido', _formatarTempo(tempoUtilizadoSegundos), Colors.teal.shade700, Colors.teal.shade50),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildCardResumoLarguraMutavel('Questões', '$totalQuestoes', Colors.grey.shade700, Colors.grey.shade100, larguraTela),
                            _buildCardResumoLarguraMutavel('Acertos', '$acertos', verdeEsmeralda, verdeEsmeralda.withValues(alpha: 0.08), larguraTela),
                            _buildCardResumoLarguraMutavel('Erros', '$erros', laranjaClaro, laranjaClaro.withValues(alpha: 0.08), larguraTela),
                            _buildCardResumoLarguraMutavel('Pontos de Prova', valorPontos, corInstitucional, corInstitucional.withValues(alpha: 0.04), larguraTela),
                            _buildCardResumoLarguraMutavel('Pontuação Acumulada', '+$pontosGamificacao XP', Colors.amber.shade900, Colors.amber.shade50, larguraTela),
                            _buildCardResumoLarguraMutavel('Tempo Decorrido', _formatarTempo(tempoUtilizadoSegundos), Colors.teal.shade700, Colors.teal.shade50, larguraTela),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // SEÇÃO 4: BARRAS DE TAXA DE ACERTO
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Taxa de Acerto: ${taxaAcerto.toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF374151)),
                            ),
                            Text('$acertos de $totalQuestoes corretas', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: taxaAcerto / 100,
                          backgroundColor: Colors.grey.shade100,
                          color: taxaAcerto >= 70 ? verdeEsmeralda : laranjaClaro,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SEÇÃO 5: MENSAGEM DO ADMINISTRADOR
                  if (mensagemFinalizacaoAdmin.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: corInstitucional.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: corInstitucional.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.comment_bank_outlined, color: corInstitucional, size: 20),
                              const SizedBox(width: 8),
                              const Text('Mensagem da Coordenação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(mensagemFinalizacaoAdmin, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14, height: 1.4)),
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

  Widget _buildBotaoAcao(BuildContext context, IconData icon, String label, Color cor, {required bool isPorAssunto}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          if (label.contains('Certificado')) {
            final usuarioAtual = FirebaseAuth.instance.currentUser;
            final String nomeAtualizado = usuarioAtual?.displayName ?? nomeDoAluno;

            await CertificadoService.gerarEImprimirCertificado(
              tituloProva: tituloSimulado,
              acertos: acertos,
              totalQuestoes: totalQuestoes,
              notaObtida: notaObtida,
              notaMaxima: notaMaxima,
              nomeAluno: nomeAtualizado,
              nomeInstiticao: instituicaoDoAluno,
              logoUrl: logoUrl,
              isPorAssunto: isPorAssunto, // <-- Passado corretamente para omitir Ponto de Prova no PDF se for por assunto
            );
          } else if (label.contains('Inspecionar') || label.contains('Prova')) {
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
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Voltar para o Histórico de Simulados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          foregroundColor: const Color(0xFF4B5563),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => context.go('/historico'),
      ),
    );
  }

  Widget _buildCardResumoLarguraMutavel(String titulo, String valor, Color corTexto, Color corFundo, double larguraDisponivel) {
    final double larguraCard = larguraDisponivel > 600 ? (larguraDisponivel - 80) / 3 : (larguraDisponivel - 64) / 2;
    return Container(
      width: larguraCard,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: corTexto.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTexto)),
        ],
      ),
    );
  }
}