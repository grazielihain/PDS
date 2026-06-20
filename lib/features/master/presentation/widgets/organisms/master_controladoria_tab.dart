import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/master_providers.dart';
import '../atoms/master_metric_card.dart';

class MasterControladoriaTab extends ConsumerStatefulWidget {
  final MasterDashboardState state;

  const MasterControladoriaTab({
    super.key,
    required this.state,
  });

  @override
  ConsumerState<MasterControladoriaTab> createState() => _MasterControladoriaTabState();
}

class _MasterControladoriaTabState extends ConsumerState<MasterControladoriaTab> {
  String _instituicaoSelecionada = 'Todas';

  @override
  void initState() {
    super.initState();
    // Garante a carga inicial de dados da controladoria respeitando o filtro ativo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(masterProvider.notifier).carregarControladoria(_instituicaoSelecionada);
    });
  }

  @override
  Widget build(BuildContext context) {
    final metricas = widget.state.metricasControladoria;
    final listaIes = widget.state.instituicoes;

    // Extração segura dos contadores do estado ou fallback zero
    final totalUsuarios = metricas['totalUsuarios'] ?? 0;
    final provasRealizadas = metricas['provasRealizadas'] ?? 0;
    final queriesCadastradas = metricas['questoesCadastradas'] ?? 0;
    final categoriasCadastradas = metricas['categoriasCadastradas'] ?? 0;
    final acessosRealizados = metricas['acessosRealizados'] ?? 0;
    final dadosGrafico = (metricas['graficoAtividades'] as Map<String, int>?) ?? {};

    return RefreshIndicator(
      onRefresh: () => ref
          .read(masterProvider.notifier)
          .carregarControladoria(_instituicaoSelecionada, forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Seletor de Filtros Inteligente por Instituição ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _instituicaoSelecionada,
                    isExpanded: true,
                    icon: const Icon(Icons.filter_alt_outlined, color: Colors.blue),
                    items: [
                      const DropdownMenuItem(value: 'Todas', child: Text('Filtrar por: Todo o Ecossistema (Geral)')),
                      ...listaIes.map((ie) => DropdownMenuItem(value: ie.id, child: Text('Filtrar por: ${ie.nome}'))),
                    ],
                    onChanged: (novoValor) {
                      if (novoValor != null) {
                        setState(() => _instituicaoSelecionada = novoValor);
                        ref.read(masterProvider.notifier).carregarControladoria(novoValor, forceRefresh: true);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Grid de Cartões Operacionais da Controladoria ---
            LayoutBuilder(
              builder: (context, constraints) {
                final isWeb = constraints.maxWidth > 600;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWeb ? 5 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWeb ? 1.4 : 1.3,
                  children: [
                    MasterMetricCard(titulo: 'Total Usuários', valor: totalUsuarios.toString(), cor: Colors.blueGrey, icone: Icons.people),
                    MasterMetricCard(titulo: 'Provas Feitas', valor: provasRealizadas.toString(), cor: Colors.green.shade700, icone: Icons.assignment_turned_in),
                    MasterMetricCard(titulo: 'Questões Criadas', valor: queriesCadastradas.toString(), cor: Colors.purple, icone: Icons.quiz),
                    MasterMetricCard(titulo: 'Categorias', valor: categoriasCadastradas.toString(), cor: Colors.teal, icone: Icons.category),
                    MasterMetricCard(titulo: 'Acessos na App', valor: acessosRealizados.toString(), cor: Colors.orange.shade800, icone: Icons.bolt),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // --- Componente de Gráfico Customizado (Atividades Recentes) ---
            Text(
              '📈 Atividades Recentes na Semana',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (dadosGrafico.isNotEmpty)
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: dadosGrafico.entries.map((barra) {
                    // Encontra o valor máximo para normalizar a altura das barras proporcionalmente
                    final maxValor = dadosGrafico.values.isNotEmpty 
                        ? dadosGrafico.values.reduce((a, b) => a > b ? a : b) 
                        : 0;
                    final alturaPercentual = maxValor > 0 ? (barra.value / maxValor) : 0.0;

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(barra.value.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: alturaPercentual * 120, // Altura máxima estipulada em pixels
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(barra.key, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}