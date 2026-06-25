import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizSelectionPage extends StatefulWidget {
  const QuizSelectionPage({super.key});

  @override
  State<QuizSelectionPage> createState() => _QuizSelectionPageState();
}

class _QuizSelectionPageState extends State<QuizSelectionPage> {
  bool _carregando = true;
  String _nomeAluno = 'Estudante';
  int _provasConcluidas = 0;
  double _pontosAcumulados = 0;
  double _taxaAcerto = 0;
  double _tempoMedioAssuntoMin = 0;
  double _tempoMedioCompletaMin = 0;

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

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get(),
        FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('historico_simulados')
            .get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final historicoSnap = results[1] as QuerySnapshot;

      if (userDoc.exists) {
        final d = userDoc.data() as Map<String, dynamic>;
        _nomeAluno = d['nome'] as String? ?? 'Estudante';
      }

      final docs = historicoSnap.docs;
      double pontos = 0;
      int totalAcertos = 0;
      int totalQuestoes = 0;
      double tempoAssunto = 0;
      int countAssunto = 0;
      double tempoCompleta = 0;
      int countCompleta = 0;

      for (final doc in docs) {
        final d = doc.data() as Map<String, dynamic>;
        pontos += (d['pontosGamificacao'] as num? ?? 0);
        totalAcertos += (d['acertos'] as num? ?? 0).toInt();
        totalQuestoes += (d['totalQuestoes'] as num? ?? 0).toInt();

        final tipo = (d['tipoProva'] as String? ?? '').toLowerCase();
        final tempo = (d['tempoUtilizadoSegundos'] as num? ?? 0).toDouble();

        if (tipo.contains('assunto')) {
          tempoAssunto += tempo;
          countAssunto++;
        } else {
          tempoCompleta += tempo;
          countCompleta++;
        }
      }

      setState(() {
        _provasConcluidas = docs.length;
        _pontosAcumulados = pontos;
        _taxaAcerto = totalQuestoes > 0
            ? (totalAcertos / totalQuestoes) * 100
            : 0;
        _tempoMedioAssuntoMin =
            countAssunto > 0 ? (tempoAssunto / countAssunto) / 60 : 0;
        _tempoMedioCompletaMin =
            countCompleta > 0 ? (tempoCompleta / countCompleta) / 60 : 0;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dashboard: $e');
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $_nomeAluno!',
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
                                child: _buildMetricCard(
                                  icon: Icons.star_rounded,
                                  title: 'Pontuação Acumulada',
                                  value: '${_pontosAcumulados.toInt()} XP',
                                  color: Colors.amber.shade700,
                                  bgColor: Colors.amber.shade50,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  icon: Icons.check_circle_outline,
                                  title: 'Provas Concluídas',
                                  value: '$_provasConcluidas',
                                  color: const Color(0xFF1E3A8A),
                                  bgColor: const Color(0xFFEFF6FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  icon: Icons.bar_chart_rounded,
                                  title: 'Taxa de Acerto',
                                  value: '${_taxaAcerto.toStringAsFixed(1)}%',
                                  color: const Color(0xFF10B981),
                                  bgColor: const Color(0xFFECFDF5),
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _buildMetricCard(
                              icon: Icons.star_rounded,
                              title: 'Pontuação Acumulada',
                              value: '${_pontosAcumulados.toInt()} XP',
                              color: Colors.amber.shade700,
                              bgColor: Colors.amber.shade50,
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              icon: Icons.check_circle_outline,
                              title: 'Provas Concluídas',
                              value: '$_provasConcluidas',
                              color: const Color(0xFF1E3A8A),
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              icon: Icons.bar_chart_rounded,
                              title: 'Taxa de Acerto',
                              value: '${_taxaAcerto.toStringAsFixed(1)}%',
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
                                  minutos: _tempoMedioAssuntoMin,
                                  icon: Icons.subject_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTempoCard(
                                  title: 'Prova Completa',
                                  minutos: _tempoMedioCompletaMin,
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
                              minutos: _tempoMedioAssuntoMin,
                              icon: Icons.subject_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildTempoCard(
                              title: 'Prova Completa',
                              minutos: _tempoMedioCompletaMin,
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
              ),
            ),
          ),
        ),
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

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
