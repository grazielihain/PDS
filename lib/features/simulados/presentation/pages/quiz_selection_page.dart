import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/simulado_remote_data_source.dart';
import 'package:rumo_quiz/shared/widgets/molecules/metric_card_molecule.dart';
import 'package:rumo_quiz/shared/widgets/templates/scrollable_page_template.dart';

class QuizSelectionPage extends ConsumerStatefulWidget {
  const QuizSelectionPage({super.key});

  @override
  ConsumerState<QuizSelectionPage> createState() => _QuizSelectionPageState();
}

class _QuizSelectionPageState extends ConsumerState<QuizSelectionPage> {
  bool _carregando = true;
  DashboardAlunoModel _dashboard = DashboardAlunoModel.empty;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _carregando = false);
      return;
    }

    final dashboard = await ref
        .read(simuladoDataSourceProvider)
        .buscarDashboardAluno(user.uid);

    if (mounted) {
      setState(() {
        _dashboard = dashboard;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ScrollablePageTemplate(
      maxWidth: 900,
      allowRefresh: true,
      onRefresh: _carregarDados,
      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${_dashboard.nome}!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acompanhe seu desempenho e progresso acadêmico.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 28),

                    _buildSectionTitle('Desempenho e Progresso'),
                    const SizedBox(height: 16),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            children: [
                              Expanded(
                                child: MetricCardMolecule(
                                  icon: Icons.star_rounded,
                                  title: 'Pontuação Acumulada',
                                  value: '${_dashboard.pontosAcumulados.toInt()} XP',
                                  color: Colors.amber.shade700,
                                  bgColor: Colors.amber.shade50,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCardMolecule(
                                  icon: Icons.check_circle_outline,
                                  title: 'Provas Concluídas',
                                  value: '${_dashboard.provasConcluidas}',
                                  color: const Color(0xFF1E3A8A),
                                  bgColor: const Color(0xFFEFF6FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCardMolecule(
                                  icon: Icons.bar_chart_rounded,
                                  title: 'Taxa de Acerto',
                                  value: '${_dashboard.taxaAcerto.toStringAsFixed(1)}%',
                                  color: const Color(0xFF10B981),
                                  bgColor: const Color(0xFFECFDF5),
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            MetricCardMolecule(
                              icon: Icons.star_rounded,
                              title: 'Pontuação Acumulada',
                              value: '${_dashboard.pontosAcumulados.toInt()} XP',
                              color: Colors.amber.shade700,
                              bgColor: Colors.amber.shade50,
                            ),
                            const SizedBox(height: 12),
                            MetricCardMolecule(
                              icon: Icons.check_circle_outline,
                              title: 'Provas Concluídas',
                              value: '${_dashboard.provasConcluidas}',
                              color: const Color(0xFF1E3A8A),
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                            const SizedBox(height: 12),
                            MetricCardMolecule(
                              icon: Icons.bar_chart_rounded,
                              title: 'Taxa de Acerto',
                              value: '${_dashboard.taxaAcerto.toStringAsFixed(1)}%',
                              color: const Color(0xFF10B981),
                              bgColor: const Color(0xFFECFDF5),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    _buildSectionTitle('Tempo Médio por Tipo de Prova'),
                    const SizedBox(height: 16),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 500) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTempoCard(
                                  title: 'Por Assunto',
                                  minutos: _dashboard.tempoMedioAssuntoMin,
                                  icon: Icons.subject_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTempoCard(
                                  title: 'Prova Completa',
                                  minutos: _dashboard.tempoMedioCompletaMin,
                                  icon: Icons.assignment_outlined,
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _buildTempoCard(
                              title: 'Por Assunto',
                              minutos: _dashboard.tempoMedioAssuntoMin,
                              icon: Icons.subject_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildTempoCard(
                              title: 'Prova Completa',
                              minutos: _dashboard.tempoMedioCompletaMin,
                              icon: Icons.assignment_outlined,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pronto para estudar?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Acesse "Fazer Quiz" no menu lateral para iniciar uma nova prova.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  String _formatarTempo(int segundosTotais) {
    if (segundosTotais <= 0) return '00:00:00';
    final int horas = segundosTotais ~/ 3600;
    final int minutos = (segundosTotais % 3600) ~/ 60;
    final int segundos = segundosTotais % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  Widget _buildTempoCard({
    required String title,
    required double minutos,
    required IconData icon,
  }) {
    final int totalSegundos = (minutos * 60).round();
    final String display = totalSegundos > 0
        ? _formatarTempo(totalSegundos)
        : 'Sem dados';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  display,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: minutos > 0
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
