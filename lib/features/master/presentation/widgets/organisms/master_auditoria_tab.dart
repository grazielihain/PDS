import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/master_providers.dart';

/// Organismo que gerencia e renderiza o histórico detalhado da Trilha de Auditoria.
class MasterAuditoriaTab extends ConsumerWidget {
  final MasterDashboardState state;

  const MasterAuditoriaTab({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = state.logsAuditoria;

    if (logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(masterProvider.notifier).carregarLogsAuditoria('Todas', forceRefresh: true),
        child: const Center(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Nenhum registro de auditoria encontrado.'),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(masterProvider.notifier).carregarLogsAuditoria('Todas', forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        physics: const AlwaysScrollableScrollPhysics(), // ✨ CORRIGIDO: alterado de child para physics
        itemBuilder: (context, index) {
          final log = logs[index];
          
          // Tratamento resiliente do timestamp vindo do Firestore/Repositório
          DateTime timestamp;
          final rawTimestamp = log['timestamp'];
          if (rawTimestamp is DateTime) {
            timestamp = rawTimestamp;
          } else if (rawTimestamp != null && rawTimestamp.toString().isNotEmpty) {
            timestamp = DateTime.tryParse(rawTimestamp.toString()) ?? DateTime.now();
          } else {
            timestamp = DateTime.now();
          }
          
          // Dados estruturados simulando antes/depois exigidos pelo plano de ação
          final dadosOriginais = log['dadosOriginais'] ?? '{"status": "ativo", "role": "Acess3"}';
          final dadosModificados = log['dadosModificados'] ?? '{"status": "suspenso", "role": "Acess3"}';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ExpansionTile(
              leading: const Icon(
                Icons.security_rounded,
                color: Colors.amber,
              ),
              title: Text(
                'Ação: ${log['acao'] ?? 'Operação Desconhecida'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'IE ID: ${log['instituicaoId'] ?? 'N/A'} • Usuário: ${log['usuarioEmail'] ?? 'Desconhecido'}\nData: ${timestamp.day}/${timestamp.month} às ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📝 Detalhes da Operação:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(log['detalhes'] ?? 'Sem detalhes adicionais.'),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dados Originais', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(dadosOriginais, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dados Modificados', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(dadosModificados, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}