import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/master_providers.dart';
import '../atoms/master_metric_card.dart';

/// Organismo que encapsula toda a interface e comportamento da Aba Home Master.
class MasterHomeTab extends ConsumerWidget {
  final MasterDashboardState state;

  const MasterHomeTab({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricas = state.metricasGlobais;
    int countInstituicoes = metricas['totalInstituicoes'] ?? 0;
    int countAdmin = metricas['admin'] ?? 0;
    int countAcess2 = metricas['acess2'] ?? 0;
    int countAcess3 = metricas['acess3'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 600;
        return RefreshIndicator(
          onRefresh: () => ref.read(masterProvider.notifier).carregarHome(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visão Geral do Ecossistema',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWeb ? 4 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWeb ? 1.5 : 1.2,
                  children: [
                    MasterMetricCard(
                      titulo: 'Instituições',
                      valor: countInstituicoes.toString(),
                      cor: Colors.blue,
                      icone: Icons.business,
                    ),
                    MasterMetricCard(
                      titulo: 'Admins (Acess1)',
                      valor: countAdmin.toString(),
                      cor: Colors.amber.shade800,
                      icone: Icons.gavel,
                    ),
                    MasterMetricCard(
                      titulo: 'Gestores (Acess2)',
                      valor: countAcess2.toString(),
                      cor: Colors.green,
                      icone: Icons.assignment_ind,
                    ),
                    MasterMetricCard(
                      titulo: 'Alunos (Acess3)',
                      valor: countAcess3.toString(),
                      cor: Colors.purple,
                      icone: Icons.school,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
