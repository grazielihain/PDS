import 'package:flutter/material.dart';
import 'package:rumo_quiz/features/prova/domain/models/revisao_questao_model.dart';
import '../../../../shared/widgets/organisms/menu_lateral_organism.dart';
import 'inspecionar_prova_page.dart';
import '../../services/certificado_service.dart';

class ResultadoProvaPage extends StatelessWidget {
  final String tituloProva;
  final int acertos;
  final int totalQuestoes;
  final double notaObtida;
  final double notaMaxima;
  final int tempoUtilizadoSegundos;
  final List<RevisaoQuestaoModel> revisaoQuestoes;
  final String mensagemFinalizacaoAdmin;
  final int pontosGamificacao;

  const ResultadoProvaPage({
    super.key,
    required this.tituloProva,
    required this.acertos,
    required this.totalQuestoes,
    required this.notaObtida,
    required this.notaMaxima,
    required this.tempoUtilizadoSegundos,
    required this.revisaoQuestoes,
    required this.mensagemFinalizacaoAdmin,
    required this.pontosGamificacao,
  });

  String _formatarTempo(int segundosTotais) {
    final minutos = segundosTotais ~/ 60;
    final segundos = segundosTotais % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    // Calcular as métricas locais para exibição
    final erros = totalQuestoes - acertos;
    final taxaAcerto = totalQuestoes > 0
        ? (acertos / totalQuestoes) * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Resultados: $tituloProva'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        centerTitle: true, // Centraliza o título na AppDoc/Web
      ),
      // Responsividade Web: Center + ConstrainedBox
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ), // Limita a largura na Web
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              24.0,
            ), // Aumentado o padding para respiro na web
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SEÇÃO 1: AVATAR + MENSAGEM DE PARABÉNS
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50, // Ligeiramente maior na web
                        backgroundColor: Colors.blue.shade100,
                        child: const Text('🐱', style: TextStyle(fontSize: 55)),
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
                        'Parabéns por concluir a prova, Aluno!',
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

                // SEÇÃO 2: OS 3 BOTÕES DE AÇÃO RÁPIDA (Em Grid na Web, Coluna no Mobile)
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Se a tela for larga (Web), coloca os botões lado a lado. Se for celular, empilha.
                    if (constraints.maxWidth > 600) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildBotaoAcao(
                              context,
                              Icons.find_in_page_outlined,
                              'Inspecionar Prova',
                              Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBotaoAcao(
                              context,
                              Icons.picture_as_pdf_outlined,
                              'Imprimir Certificado',
                              Colors.purple.shade600,
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
                          ),
                          const SizedBox(height: 8),
                          _buildBotaoAcao(
                            context,
                            Icons.picture_as_pdf_outlined,
                            'Imprimir Certificado (PDF)',
                            Colors.purple.shade600,
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio:
                      2.5, // Ajustado para os cards ficarem mais compactos
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
                      'Points da Prova',
                      '${notaObtida.toStringAsFixed(1)} pts',
                      Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildCardResumo(
                  'Pontuação Gamificação Acumulada',
                  '+$pontosGamificacao XP',
                  Colors.amber.shade900,
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
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
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

                // SEÇÃO 6: MENSAGEM DO ADMINISTRADOR (CONGELADA / IMUTÁVEL)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
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
    );
  }

  // Lógica de clique inserida dinamicamente baseada na label do botão
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
          print(
            'DEBUG TCC: Quantidade de questões enviadas para revisão: ${revisaoQuestoes.length}',
          );

          // Verifica se o botão clicado foi o de Imprimir Certificado
          // Enviando o nome (temporariamente estático até ligar ao Meu Perfil)
          if (label.contains('Imprimir Certificado')) {
            await CertificadoService.gerarEImprimirCertificado(
              tituloProva: tituloProva,
              acertos: acertos,
              totalQuestoes: totalQuestoes,
              notaObtida: notaObtida,
              notaMaxima: notaMaxima,
              nomeAluno: 'Estudante Cadastrado',
              nomeInstiticao:
                  'Sua Instituição de Ensino', // Passando o nome correto da escola/faculdade
            );
          }
          // Verifica se o botão clicado foi o de Inspecionar Prova
          else if (label.contains('Inspecionar Prova')) {
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Ação: $label...')));
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

  Widget _buildBarraAssunto(String assunto, double porcentagem, String fracao) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                assunto,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$fracao acertos (${porcentagem.toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: porcentagem / 100,
            backgroundColor: Colors.grey.shade200,
            color: Colors.blue.shade600,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
