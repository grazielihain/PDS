import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/master_providers.dart';

class MasterInstituicoesTab extends ConsumerWidget {
  final MasterDashboardState state;
  final TextEditingController nomeInstituicaoController;
  final Function(String id, String nome, String corHex, String? logoUrl) onAbrirEdicao;
  final Function(String id, String nome) onTentarexcluir;
  final Function(String instituicaoId) onAbrirAdicionarUsuario;

  const MasterInstituicoesTab({
    super.key,
    required this.state,
    required this.nomeInstituicaoController,
    required this.onAbrirEdicao,
    required this.onTentarexcluir,
    required this.onAbrirAdicionarUsuario,
  });

  // Cor padrão do escopo Master estabelecida para componentes visuais de controle
  static const Color corPadraoMaster = Colors.purple;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instDocs = state.instituicoes;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏛️ Organização e Árvore de Clientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: corPadraoMaster,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nomeInstituicaoController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Nova Instituição',
                    hintText: 'Ex: Escola Rumo Saber',
                    border: OutlineInputBorder(),
                    floatingLabelStyle: TextStyle(color: corPadraoMaster),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: corPadraoMaster, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  if (nomeInstituicaoController.text.trim().isEmpty) return;
                  
                  // Injeta por padrão uma cor cinza neutra, permitindo que a edição defina o Hexadecimal final
                  await ref.read(masterProvider.notifier).criarInstituicao(
                        nomeInstituicaoController.text.trim(),
                        '#9E9E9E',
                        null,
                      );
                  nomeInstituicaoController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: corPadraoMaster,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cadastrar'),
              ),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: RefreshIndicator(
              color: corPadraoMaster,
              onRefresh: () => ref.read(masterProvider.notifier).carregarInstituicoes(forceRefresh: true),
              child: instDocs.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('Nenhuma instituição cadastrada no ecossistema.'),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: instDocs.length,
                      itemBuilder: (context, index) {
                        final inst = instDocs[index];

                        // Converte a cor Hex da IE com fallback seguro caso o formato falhe
                        Color corInstituicao;
                        try {
                          final hex = inst.corPrimaria.replaceAll('#', '');
                          corInstituicao = Color(int.parse('FF$hex', radix: 16));
                        } catch (_) {
                          corInstituicao = corPadraoMaster;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ExpansionTile(
                            iconColor: corPadraoMaster,
                            leading: CircleAvatar(
                              backgroundColor: corInstituicao.withOpacity(0.15),
                              child: Icon(Icons.corporate_fare, color: corInstituicao),
                            ),
                            title: Text(
                              inst.nome,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('ID: ${inst.id} • Cor: ${inst.corPrimaria}'),
                            onExpansionChanged: (expanded) {
                              if (expanded) {
                                ref.read(masterProvider.notifier).carregarUsuariosDaInstituicao(inst.id, 'Todos');
                              }
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, color: Colors.orange),
                                  onPressed: () => onAbrirEdicao(
                                    inst.id,
                                    inst.nome,
                                    inst.corPrimaria,
                                    inst.logoUrl,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                                  onPressed: () => onTentarexcluir(inst.id, inst.nome),
                                ),
                              ],
                            ),
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Divider(height: 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Árvore de Usuários Vinculados:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => onAbrirAdicionarUsuario(inst.id),
                                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                      label: const Text('Vincular Usuário', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildListaUsuariosVinculados(inst.id),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaUsuariosVinculados(String instituicaoId) {
    final usuarios = state.usuariosDaInstituicao;
    final usuariosFiltrados = usuarios.where((u) => u['instituicaoId'] == instituicaoId).toList();

    if (usuariosFiltrados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'Nenhum usuário alocado nesta instituição.',
          style: TextStyle(color: Colors.black54, fontSize: 13, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: usuariosFiltrados.map((user) {
        final uNome = user['nome'] ?? 'Sem Nome';
        final uRole = user['role'] ?? 'Acess3';
        final uEmail = user['email'] ?? '';

        // Identificadores amigáveis de nível de acesso com base nas regras do negócio
        String traducaoNivel = 'Aluno (Acess3)';
        Color corNivel = Colors.grey;
        if (uRole == 'Admin' || uRole == 'Acess1') {
          traducaoNivel = 'Admin da IE (Acess1)';
          corNivel = Colors.amber.shade900;
        } else if (uRole == 'Acess2') {
          traducaoNivel = 'Gestor (Acess2)';
          corNivel = Colors.blue.shade700;
        }

        return Consumer(
          builder: (context, ref, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: ListTile(
                dense: true,
                title: Text(uNome, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('E-mail: $uEmail\nNível: $traducaoNivel'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                  tooltip: 'Desvincular Usuário',
                  onPressed: () async {
                    await ref.read(masterProvider.notifier).removerUsuario(user['id'], instituicaoId);
                  },
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}