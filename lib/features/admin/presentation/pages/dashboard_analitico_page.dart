import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardAnaliticoPage extends StatefulWidget {
  const DashboardAnaliticoPage({super.key});

  @override
  State<DashboardAnaliticoPage> createState() => _DashboardAnaliticoPageState();
}

class _DashboardAnaliticoPageState extends State<DashboardAnaliticoPage> {
  // Estado para simular o clique na grade flutuante de inspeção de prova (Subtarefa 3.2)
  int? _questaoInspecionadaSelecionada;

  // Mock de dados para a Grade de Inspeção (10 Questões respondidas pelo aluno)
  final List<Map<String, dynamic>> _questoesSimulado = [
    {'numero': 1, 'acertou': true, 'justificativa': 'Alternativa A está correta porque a soma dos ângulos internos de um triângulo é 180°.'},
    {'numero': 2, 'acertou': true, 'justificativa': 'Correto. O artigo 5º da CF/88 garante a igualdade de todos perante a lei.'},
    {'numero': 3, 'acertou': false, 'justificativa': 'Você errou. A crase é proibida antes de verbos no infinitivo.'},
    {'numero': 4, 'acertou': true, 'justificativa': 'Exato! A mitocôndria é responsável pela respiração celular.'},
    {'numero': 5, 'acertou': false, 'justificativa': 'Incorreto. A primeira lei de Newton trata do princípio da Inércia, não da Ação/Reação.'},
    {'numero': 6, 'acertou': true, 'justificativa': 'Parabéns. O Brasil foi descoberto formalmente em 1500.'},
    {'numero': 7, 'acertou': true, 'justificativa': 'Correto. O valor de Pi aproximado é 3,14.'},
    {'numero': 8, 'acertou': false, 'justificativa': 'Errado. O oxigênio possui número atômico 8, não 6.'},
    {'numero': 9, 'acertou': true, 'justificativa': 'Muito bem. A capital da França é Paris.'},
    {'numero': 10, 'acertou': true, 'justificativa': 'Perfeito. Redundância de dados consome mais recursos do Firestore.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Fechamento de Prova'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool ehWeb = constraints.maxWidth > 850;

          // Montagem do layout responsivo baseado na largura da tela (Subtarefa 3.1)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 Métricas de Desempenho Global',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // RESPONSIVIDADE EM AÇÃO: Lado a Lado no Web, Coluna única no Mobile
                ehWeb
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildGraficoPizza()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildGraficoBarras()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildGraficoPizza(),
                          const SizedBox(height: 16),
                          _buildGraficoBarras(),
                        ],
                      ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // =============================================================
                // SUBTAREFA 3.2: GRADE FLUTUANTE "INSPECIONAR PROVA"
                // =============================================================
                Text(
                  '🏁 Resultados do Último Simulado Concluído',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Clique nos botões da grade flutuante abaixo para revisar o item e ler a justificativa cadastrada.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Container que simula a "Grade Flutuante" sobreposta à tela de resultados
                Card(
                  elevation: 4,
                  color: Colors.blueGrey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blueGrey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎛️ Painel de Inspeção Rápida (Grade Clicável)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        
                        // Grade de Ícones Clicáveis (Wrap garante adaptação de tamanho)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(_questoesSimulado.length, (index) {
                            final q = _questoesSimulado[index];
                            final bool acertou = q['acertou'];
                            final bool selecionada = _questaoInspecionadaSelecionada == index;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _questaoInspecionadaSelecionada = index;
                                });
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: acertou ? Colors.green.shade100 : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selecionada ? Colors.blue.shade900 : (acertou ? Colors.green : Colors.red),
                                    width: selecionada ? 3 : 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${q['numero']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      Icon(
                                        acertou ? Icons.check : Icons.close,
                                        size: 14,
                                        color: acertou ? Colors.green.shade900 : Colors.red.shade900,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        // Painel de detalhamento dinâmico exibido ao clicar na grade
                        if (_questaoInspecionadaSelecionada != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blueGrey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _questoesSimulado[_questaoInspecionadaSelecionada!]['acertou'] ? Icons.check_circle : Icons.cancel,
                                      color: _questoesSimulado[_questaoInspecionadaSelecionada!]['acertou'] ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Revisão Detalhada: Item ${_questaoInspecionadaSelecionada! + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text('💡 Justificativa do Professor:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  _questoesSimulado[_questaoInspecionadaSelecionada!]['justificativa'],
                                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SUBTAREFA 3.1: CONSTRUÇÃO DOS GRÁFICOS (fl_chart)
  // ===========================================================================
  
  /// Gráfico de Pizza - Distribuição de Acertos vs Erros por Categoria
  Widget _buildGraficoPizza() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎯 Proporção de Respostas Globais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(color: Colors.green.shade600, value: 70, title: '70% Acertos', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(color: Colors.red.shade600, value: 30, title: '30% Erros', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gráfico de Barras - Média de Pontos por Assunto/Categoria
  Widget _buildGraficoBarras() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📈 Média de Pontuação por Matéria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 85, color: Colors.teal, width: 15, borderRadius: BorderRadius.circular(4))]), // Ex: Mat
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 60, color: Colors.orange, width: 15, borderRadius: BorderRadius.circular(4))]), // Ex: Dir
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 92, color: Colors.purple, width: 15, borderRadius: BorderRadius.circular(4))]), // Ex: Port
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}