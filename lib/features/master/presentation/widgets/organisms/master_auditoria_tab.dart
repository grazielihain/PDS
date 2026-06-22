import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/master_providers.dart';

/// Organismo que gerencia, filtra e renderiza de forma amigável a Trilha de Auditoria.
class MasterAuditoriaTab extends ConsumerStatefulWidget {
  final MasterDashboardState state;

  const MasterAuditoriaTab({
    super.key,
    required this.state,
  });

  @override
  ConsumerState<MasterAuditoriaTab> createState() => _MasterAuditoriaTabState();
}

class _MasterAuditoriaTabState extends ConsumerState<MasterAuditoriaTab> {
  String _instituicaoSelecionada = 'Todas';

  @override
  void initState() {
    super.initState();
    // Garante que a lista de instituições para o filtro esteja populada ao abrir a aba
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(masterProvider.notifier).carregarInstituicoes();
    });
  }

  /// Converte mapas/JSON NoSQL brutos em uma visualização textual limpa e legível para o usuário
  Widget _renderizarDadosAmigaveis(dynamic dados, Color corDestaque) {
    if (dados == null) return const Text('Nenhum dado registrado.');
    
    Map<String, dynamic> mapaFormatado = {};
    try {
      if (dados is String) {
        mapaFormatado = jsonDecode(dados);
      } else if (dados is Map<String, dynamic>) {
        mapaFormatado = dados;
      }
    } catch (_) {
      return Text(dados.toString());
    }

    if (mapaFormatado.isEmpty) return const Text('Registro vazio.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mapaFormatado.entries.map((entry) {
        // Ignora campos internos de ID do Firebase para limpar a leitura do usuário
        if (entry.key == 'id' || entry.key == 'instituicaoId') return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ${entry.key}: ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Expanded(
                child: Text(
                  '${entry.value}',
                  style: TextStyle(color: corDestaque, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.state.logsAuditoria;
    final instituicoes = widget.state.instituicoes;

    return Column(
      children: [
        // --- 1. SELETOR DE FILTRAGEM MULTI-TENANT (Item 1 do Planejamento)
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.purple),
              const SizedBox(width: 12),
              const Text('Instituição:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _instituicaoSelecionada,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: 'Todas', child: Text('Todas as Instituições')),
                      ...instituicoes.map((ie) => DropdownMenuItem(value: ie.id, child: Text(ie.nome))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _instituicaoSelecionada = val);
                        ref.read(masterProvider.notifier).carregarLogsAuditoria(val, forceRefresh: true);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- LISTAGEM DE LOGS EM BARRA DE ROLAGEM RESPONSIVA
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(masterProvider.notifier)
                .carregarLogsAuditoria(_instituicaoSelecionada, forceRefresh: true),
            child: logs.isEmpty
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Nenhum registro de auditoria encontrado para este filtro.'),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final timestamp = log['timestamp'] is DateTime 
                          ? log['timestamp'] as DateTime 
                          : DateTime.now();
                      
                      final acao = log['acao'] ?? 'Ação Desconhecida';
                      
                      // Define cores baseadas no tipo de evento gerado
                      Color corAcao = Colors.blue;
                      IconData iconeAcao = Icons.info_outline;
                      if (acao.toString().toUpperCase().contains('CRIAR') || acao.toString().toUpperCase().contains('ADD')) {
                        corAcao = Colors.green;
                        iconeAcao = Icons.add_circle_outline;
                      } else if (acao.toString().toUpperCase().contains('EDITAR') || acao.toString().toUpperCase().contains('ATUALIZAR')) {
                        corAcao = Colors.amber.shade800;
                        iconeAcao = Icons.edit_note_rounded;
                      } else if (acao.toString().toUpperCase().contains('EXCLUIR') || acao.toString().toUpperCase().contains('DELETAR')) {
                        corAcao = Colors.red;
                        iconeAcao = Icons.delete_forever_outlined;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ExpansionTile(
                          iconColor: Colors.purple,
                          leading: Icon(iconeAcao, color: corAcao, size: 28),
                          title: Text(
                            'Operação: $acao',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Usuário: ${log['usuarioEmail'] ?? 'Sistema'}\nData: ${timestamp.day}/${timestamp.month} às ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12, height: 1.3, color: Colors.black54),
                          ),
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (log['detalhes'] != null) ...[
                                    Text(
                                      'Contexto: ${log['detalhes']}',
                                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  
                                  // --- 2. MAPEAMENTO HUMANO REMOVENDO JSON (Item 2 do Planejamento)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Estado Anterior',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11, letterSpacing: 0.5),
                                            ),
                                            const SizedBox(height: 6),
                                            _renderizarDadosAmigaveis(log['dadosOriginais'], Colors.red.shade900),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                        child: VerticalDivider(width: 1),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Novo Estado',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 11, letterSpacing: 0.5),
                                            ),
                                            const SizedBox(height: 6),
                                            _renderizarDadosAmigaveis(log['dadosModificados'], Colors.green.shade900),
                                          ],
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
          ),
        ),
      ],
    );
  }
}