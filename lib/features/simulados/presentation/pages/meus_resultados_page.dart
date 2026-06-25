import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeusResultadosPage extends StatefulWidget {
  const MeusResultadosPage({super.key});

  @override
  State<MeusResultadosPage> createState() => _MeusResultadosPageState();
}

class _MeusResultadosPageState extends State<MeusResultadosPage> {
  bool _carregando = true;

  // Métricas gerais
  int _totalProvas = 0;
  double _taxaAcertoGeral = 0;
  double _tempoMedioMin = 0;

  // Por categoria: {categoria: count}
  Map<String, int> _provasPorCategoria = {};

  // Por assunto: {assunto: {acertos, erros}}
  Map<String, Map<String, int>> _acertosPorAssunto = {};

  // Média de pontos por categoria: {categoria: media}
  Map<String, double> _mediaPontosPorCategoria = {};

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
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('historico_simulados')
          .get();

      final docs = snap.docs;

      int totalAcertos = 0;
      int totalQuestoes = 0;
      double somaTempos = 0;
      int countTempos = 0;

      final Map<String, int> porCategoria = {};
      final Map<String, Map<String, int>> porAssunto = {};
      final Map<String, List<double>> pontosPorCategoria = {};

      for (final doc in docs) {
        final d = doc.data();
        final categoria = (d['categoria'] as String? ?? 'Geral').trim();
        final assunto = (d['assunto'] as String? ?? '').trim();
        final acertos = (d['acertos'] as num? ?? 0).toInt();
        final total = (d['totalQuestoes'] as num? ?? 0).toInt();
        final nota = (d['notaObtida'] as num? ?? 0).toDouble();
        final tempo = (d['tempoUtilizadoSegundos'] as num? ?? 0).toDouble();

        totalAcertos += acertos;
        totalQuestoes += total;

        if (tempo > 0) {
          somaTempos += tempo;
          countTempos++;
        }

        // Provas por categoria
        porCategoria[categoria] = (porCategoria[categoria] ?? 0) + 1;

        // Acertos e erros por assunto
        if (assunto.isNotEmpty) {
          porAssunto[assunto] ??= {'acertos': 0, 'erros': 0};
          porAssunto[assunto]!['acertos'] =
              (porAssunto[assunto]!['acertos'] ?? 0) + acertos;
          porAssunto[assunto]!['erros'] =
              (porAssunto[assunto]!['erros'] ?? 0) + (total - acertos);
        }

        // Pontos por categoria
        pontosPorCategoria[categoria] ??= [];
        pontosPorCategoria[categoria]!.add(nota);
      }

      // Calcula médias de pontos
      final Map<String, double> mediaPontos = {};
      for (final entry in pontosPorCategoria.entries) {
        final lista = entry.value;
        mediaPontos[entry.key] =
            lista.isEmpty ? 0 : lista.reduce((a, b) => a + b) / lista.length;
      }

      setState(() {
        _totalProvas = docs.length;
        _taxaAcertoGeral =
            totalQuestoes > 0 ? (totalAcertos / totalQuestoes) * 100 : 0;
        _tempoMedioMin = countTempos > 0 ? (somaTempos / countTempos) / 60 : 0;
        _provasPorCategoria = porCategoria;
        _acertosPorAssunto = porAssunto;
        _mediaPontosPorCategoria = mediaPontos;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar resultados: $e');
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
                    const Text(
                      'Meus Resultados',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Análise detalhada do seu desempenho acadêmico.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),

                    // CARDS DE MÉTRICAS
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  icon: Icons.check_circle_outline,
                                  label: 'Total de Provas',
                                  value: '$_totalProvas',
                                  color: const Color(0xFF1E3A8A),
                                  bg: const Color(0xFFEFF6FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  icon: Icons.timer_outlined,
                                  label: 'Tempo Médio',
                                  value: _tempoMedioMin > 0
                                      ? '${_tempoMedioMin.toStringAsFixed(1)} min'
                                      : 'N/D',
                                  color: Colors.teal.shade700,
                                  bg: Colors.teal.shade50,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  icon: Icons.bar_chart_rounded,
                                  label: 'Taxa de Acerto',
                                  value: '${_taxaAcertoGeral.toStringAsFixed(1)}%',
                                  color: const Color(0xFF10B981),
                                  bg: const Color(0xFFECFDF5),
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _buildMetricCard(
                              icon: Icons.check_circle_outline,
                              label: 'Total de Provas',
                              value: '$_totalProvas',
                              color: const Color(0xFF1E3A8A),
                              bg: const Color(0xFFEFF6FF),
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              icon: Icons.timer_outlined,
                              label: 'Tempo Médio',
                              value: _tempoMedioMin > 0
                                  ? '${_tempoMedioMin.toStringAsFixed(1)} min'
                                  : 'N/D',
                              color: Colors.teal.shade700,
                              bg: Colors.teal.shade50,
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              icon: Icons.bar_chart_rounded,
                              label: 'Taxa de Acerto',
                              value: '${_taxaAcertoGeral.toStringAsFixed(1)}%',
                              color: const Color(0xFF10B981),
                              bg: const Color(0xFFECFDF5),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // GRÁFICO 1: Provas por Categoria
                    _buildChartCard(
                      title: 'Provas Concluídas por Categoria',
                      icon: Icons.category_outlined,
                      child: _provasPorCategoria.isEmpty
                          ? _buildEmptyState()
                          : _buildBarChart(
                              _provasPorCategoria.entries
                                  .map((e) => _BarData(
                                        label: e.key,
                                        value: e.value.toDouble(),
                                        maxValue: _provasPorCategoria.values
                                            .reduce((a, b) => a > b ? a : b)
                                            .toDouble(),
                                        displayText: '${e.value} prova${e.value != 1 ? 's' : ''}',
                                        color: const Color(0xFF1E3A8A),
                                      ))
                                  .toList(),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // GRÁFICO 2: Acertos e Erros por Assunto
                    _buildChartCard(
                      title: 'Acertos e Erros por Assunto',
                      icon: Icons.quiz_outlined,
                      child: _acertosPorAssunto.isEmpty
                          ? _buildEmptyState()
                          : Column(
                              children: _acertosPorAssunto.entries.map((entry) {
                                final acertos = entry.value['acertos'] ?? 0;
                                final erros = entry.value['erros'] ?? 0;
                                final total = acertos + erros;
                                return _buildAcertosErrosRow(
                                  assunto: entry.key,
                                  acertos: acertos,
                                  erros: erros,
                                  total: total,
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // GRÁFICO 3: Média de Pontos por Categoria
                    _buildChartCard(
                      title: 'Média de Pontos por Categoria',
                      icon: Icons.stars_outlined,
                      child: _mediaPontosPorCategoria.isEmpty
                          ? _buildEmptyState()
                          : _buildBarChart(
                              _mediaPontosPorCategoria.entries
                                  .map((e) {
                                    final maxVal = _mediaPontosPorCategoria.values
                                        .reduce((a, b) => a > b ? a : b);
                                    return _BarData(
                                      label: e.key,
                                      value: e.value,
                                      maxValue: maxVal > 0 ? maxVal : 1,
                                      displayText: e.value.toStringAsFixed(1),
                                      color: Colors.amber.shade700,
                                    );
                                  })
                                  .toList(),
                            ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
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
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBarChart(List<_BarData> data) {
    return Column(
      children: data.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.displayText,
                    style: TextStyle(
                      fontSize: 13,
                      color: item.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.maxValue > 0 ? item.value / item.maxValue : 0,
                  backgroundColor: Colors.grey.shade100,
                  color: item.color,
                  minHeight: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAcertosErrosRow({
    required String assunto,
    required int acertos,
    required int erros,
    required int total,
  }) {
    final acertosFrac = total > 0 ? acertos / total : 0.0;
    final errosFrac = total > 0 ? erros / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  assunto,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$acertos',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$erros',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (acertosFrac * 100).round().clamp(0, 100),
                  child: Container(
                    height: 10,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Expanded(
                  flex: (errosFrac * 100).round().clamp(0, 100),
                  child: Container(
                    height: 10,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Nenhuma prova registrada ainda.',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      ),
    );
  }
}

class _BarData {
  final String label;
  final double value;
  final double maxValue;
  final String displayText;
  final Color color;

  const _BarData({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.displayText,
    required this.color,
  });
}
