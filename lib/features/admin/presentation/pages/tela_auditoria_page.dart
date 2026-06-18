import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaAuditoriaPage extends StatefulWidget {
  final bool visaoMaster; // Define se exibe visualização bruta comparativa ou textual limpa
  const TelaAuditoriaPage({super.key, this.visaoMaster = false});

  @override
  State<TelaAuditoriaPage> createState() => _TelaAuditoriaPageState();
}

class _TelaAuditoriaPageState extends State<TelaAuditoriaPage> {
  String _filtroInstituicao = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visaoMaster ? '🔒 Auditoria Avançada (Master)' : '🛡️ Histórico de Atividades (Admin)'),
        backgroundColor: widget.visaoMaster ? Colors.red.shade900 : Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Subtarefa 2.3: Filtro Dropdown para o Master
          if (widget.visaoMaster) _buildFiltroMaster(),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _obterStreamLogs(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final logs = snapshot.data!.docs;

                if (logs.isEmpty) {
                  return const Center(child: Text('Nenhum log de auditoria encontrado.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    
                    // Subtarefa 2.2: Renderização textual amigável sem JSON bruto exposto por padrão
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: Icon(
                          log['acao'] == 'EXCLUIR' ? Icons.delete_forever : (log['acao'] == 'EDITAR' ? Icons.edit : Icons.add_box),
                          color: log['acao'] == 'EXCLUIR' ? Colors.red : Colors.orange,
                        ),
                        title: Text(log['descricaoAmigavel'] ?? 'Ação realizada no sistema.'),
                        subtitle: Text('Tabela: ${log['tabela']} | Executor: ${log['usuarioNome']}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID do Usuário: ${log['usuarioId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  if (widget.visaoMaster) ...[
                                    const Text('🔎 Comparativo de Campos (Valor Antigo vs Novo):', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Antes: ${log['dadosAntigos'] ?? "{}"}', style: TextStyle(color: Colors.red.shade700, fontFamily: 'monospace')),
                                    Text('Depois: ${log['dadosNovos'] ?? "{}"}', style: TextStyle(color: Colors.green.shade700, fontFamily: 'monospace')),
                                  ] else ...[
                                    Text('Ação executada estruturalmente na tabela institucional [${log['tabela']}].'),
                                  ]
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroMaster() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: DropdownButtonFormField<String>(
        value: _filtroInstituicao,
        decoration: const InputDecoration(labelText: 'Filtrar por Instituição Alvo', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'Todos', child: Text('Todas as Instituições')),
          DropdownMenuItem(value: 'inst_01', child: Text('Instituição Alfa')),
          DropdownMenuItem(value: 'inst_02', child: Text('Instituição Beta')),
        ],
        onChanged: (val) => setState(() => _filtroInstituicao = val ?? 'Todos'),
      ),
    );
  }

  Stream<QuerySnapshot> _obterStreamLogs() {
    var query = FirebaseFirestore.instance.collection('auditoria_logs').orderBy('timestamp', descending: true);
    if (widget.visaoMaster && _filtroInstituicao != 'Todos') {
      return query.where('instituicaoId', isEqualTo: _filtroInstituicao).snapshots();
    }
    return query.snapshots();
  }
}