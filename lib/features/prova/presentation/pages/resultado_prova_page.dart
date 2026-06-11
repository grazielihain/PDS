import 'package:flutter/material.dart';
import 'package:rumo_quiz/features/prova/presentation/pages/inspecionar_prova_page.dart';
import 'package:rumo_quiz/features/prova/services/certificado_service.dart';
import 'package:rumo_quiz/features/prova/domain/models/revisao_questao_model.dart';

class ResultadoProvaPage extends StatelessWidget {
  final String nomeDoAluno;
  final String instituicaoDoAluno;
  final String? logoUrl;
  final String tituloProva;
  final int totalQuestoes;
  final int acertos;
  final int erros;
  final double notaObtida;
  final double notaMaxima;
  final int pontosGamificacao;
  final double taxaAcerto;
  final String mensagemFinalizacaoAdmin;
  final List<RevisaoQuestaoModel> revisaoQuestoes; 
  final int tempoUtilizadoSegundos; // 🟢 Adicionado para resolver o erro de parâmetro

  const ResultadoProvaPage({
    Key? key,
    required this.nomeDoAluno,
    required this.instituicaoDoAluno,
    this.logoUrl,
    required this.tituloProva,
    required this.totalQuestoes,
    required this.acertos,
    required this.erros,
    required this.notaObtida,
    required this.notaMaxima,
    required this.pontosGamificacao,
    required this.taxaAcerto,
    required this.mensagemFinalizacaoAdmin,
    required this.revisaoQuestoes,
    required this.tempoUtilizadoSegundos, // 🟢 Requerido no construtor
  }) : super(key: key);

  // 🕒 Função utilitária para converter segundos em MM:SS ou HH:MM:SS
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
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
                        const Text(
                          'Prova Finalizada!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Parabéns por concluir a prova, $nomeDoAluno!',
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

                  // SEÇÃO 2: OS BOTÕES DE AÇÃO RÁPIDA (Responsivo)
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
                                Colors.blue.shade600,
                                nomeDoAluno,
                                instituicaoDoAluno,
                                logoUrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBotaoAcao(
                                context,
                                Icons.picture_as_pdf_outlined,
                                'Imprimir Certificado',
                                Colors.purple.shade600,
                                nomeDoAluno,
                                instituicaoDoAluno,
                                logoUrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _buildBotaoVoltar(context)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildBotaoAcao(
                              context,
                              Icons.find_in_page_outlined,
                              'Inspecionar Prova (Revisão)',
                              Colors.blue.shade600,
                              nomeDoAluno,
                              instituicaoDoAluno,
                              logoUrl,
                            ),
                            const SizedBox(height: 8),
                            _buildBotaoAcao(
                              context,
                              Icons.picture_as_pdf_outlined,
                              'Imprimir Certificado (PDF)',
                              Colors.purple.shade600,
                              nomeDoAluno,
                              instituicaoDoAluno,
                              logoUrl,
                            ),
                            const SizedBox(height: 8),
                            _buildBotaoVoltar(context),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 36),

                  // SEÇÃO 3: RESUMO DA PROVA (Cards de Métricas)
                  const Text(
                    'Resumo da Prova',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                        Colors.blue.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  // Row Dinâmica para mostrar o XP acumulado e o Tempo gasto lado a lado
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
                          _formatarTempo(tempoUtilizadoSegundos), // ⏱️ Exibindo o tempo formatado
                          Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // SEÇÃO 4: BARRAS DE TAXA DE ACERTO
                  const Text(
                    'Métricas de Aproveitamento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.gavel, color: Colors.blue, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Mensagem da Coordenação / Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
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
    String nomeAluno,
    String nomeInstituicao,
    String? logoUrl,
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
          print('DEBUG TCC: Quantidade de questões enviadas para revisão: ${revisaoQuestoes.length}');

          if (label.contains('Imprimir Certificado')) {
            
            await CertificadoService.gerarEImprimirCertificado(
              tituloProva: tituloProva,
              acertos: acertos,
              totalQuestoes: totalQuestoes,
              notaObtida: notaObtida,
              notaMaxima: notaMaxima,
              nomeAluno: nomeAluno,
              nomeInstiticao: nomeInstituicao,
              logoUrl: logoUrl,
            );
          } else if (label.contains('Inspecionar Prova')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspecionarProvaPage(
                   tituloProva: tituloProva,
                   revisaoQuestoes: revisaoQuestoes,
                 ),
               ),
             );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ação: $label...')),
            );
          }
        },
      ),
    );
  }

  Widget _buildBotaoVoltar(BuildContext context) {
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
          side: BorderSide(color: Colors.blue.shade700),
          foregroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildCardResumo(String titulo, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withAlpha((0.3 * 255).toInt())),
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