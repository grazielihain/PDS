import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/master_providers.dart';

class MasterInstituicoesTab extends ConsumerStatefulWidget {
  final MasterDashboardState state;
  final TextEditingController nomeInstituicaoController;
  final Function(String id, String nome, String corHex, String? logoUrl)
  onAbrirEdicao;
  final Function(String id, String nome) onTentarexcluir;
  final Function(String instituicaoId) onAbrirAdicionarUsuario;
  // Nova callback adicionada para gerenciar a edição do usuário a partir da lista
  final Function(Map<String, dynamic> usuario, String instituicaoId)
  onEditarUsuario;

  const MasterInstituicoesTab({
    super.key,
    required this.state,
    required this.nomeInstituicaoController,
    required this.onAbrirEdicao,
    required this.onTentarexcluir,
    required this.onAbrirAdicionarUsuario,
    required this.onEditarUsuario,
  });

  @override
  ConsumerState<MasterInstituicoesTab> createState() =>
      _MasterInstituicoesTabState();
}

class _MasterInstituicoesTabState extends ConsumerState<MasterInstituicoesTab> {
  String _filtroNivelAtivo = 'Todos';

  @override
  Widget build(BuildContext context) {
    final instDocs = widget.state.instituicoes;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Instituições de Ensino',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nova Instituição'),
                onPressed: () => widget.onAbrirEdicao('', '', '4CAF50', null),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(masterProvider.notifier)
                  .carregarInstituicoes(forceRefresh: true),
              child: instDocs.isEmpty
                  ? const Center(child: Text('Nenhuma instituição cadastrada.'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent:
                            220, // Ajustado ligeiramente para caber as ações de forma limpa
                      ),
                      itemCount: instDocs.length,
                      itemBuilder: (context, index) {
                        final inst = instDocs[index];
                        Color corIE = Colors.grey;
                        try {
                          final hex = inst.corPrimaria
                              .replaceAll('#', '')
                              .trim();
                          if (hex.isNotEmpty) {
                            corIE = Color(int.parse('FF$hex', radix: 16));
                          }
                        } catch (_) {}

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: corIE.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: corIE.withOpacity(0.1),
                                      backgroundImage:
                                          (inst.logoUrl != null &&
                                              inst.logoUrl!.isNotEmpty)
                                          ? NetworkImage(inst.logoUrl!)
                                          : null,
                                      child:
                                          (inst.logoUrl == null ||
                                              inst.logoUrl!.isEmpty)
                                          ? Icon(Icons.business, color: corIE)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        inst.nome,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  'ID: ${inst.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade100,
                                    foregroundColor: Colors.purple.shade900,
                                    elevation: 0,
                                    minimumSize: const Size.fromHeight(36),
                                  ),
                                  icon: const Icon(
                                    Icons.people_alt_outlined,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Ver Usuários Vinculados',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  onPressed: () async {
                                    // Carrega os usuários no provider antes de abrir o modal
                                    await ref
                                        .read(masterProvider.notifier)
                                        .carregarUsuariosDaInstituicao(
                                          inst.id,
                                          'Todos',
                                        );
                                    if (context.mounted) {
                                      _abrirModalUsuarios(
                                        context,
                                        inst.id,
                                        inst.nome,
                                      );
                                    }
                                  },
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar Instituição',
                                      onPressed: () => widget.onAbrirEdicao(
                                        inst.id,
                                        inst.nome,
                                        inst.corPrimaria,
                                        inst.logoUrl,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Excluir Instituição',
                                      onPressed: () => widget.onTentarexcluir(
                                        inst.id,
                                        inst.nome,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  void _abrirModalUsuarios(
    BuildContext context,
    String instituicaoId,
    String instituicaoNome,
  ) {
    setState(() => _filtroNivelAtivo = 'Todos');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, refConsumer, child) {
            final masterState = refConsumer.watch(masterProvider);
            final usuarios = masterState.usuariosDaInstituicao;

            final usuariosDaInst = usuarios
                .where((u) => u['instituicaoId'] == instituicaoId)
                .toList();

            int totalAdmin = 0;
            int totalAcess2 = 0;
            int totalAcess3 = 0;

            for (var u in usuariosDaInst) {
              final role = u['role'].toString().toLowerCase();
              if (role == 'admin') totalAdmin++;
              if (role == 'acess2') totalAcess2++;
              if (role == 'acess3') totalAcess3++;
            }

            final usuariosFiltrados = usuariosDaInst.where((u) {
              if (_filtroNivelAtivo == 'Todos') return true;
              return u['role'].toString().toLowerCase() ==
                  _filtroNivelAtivo.toLowerCase();
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        tooltip: 'Sair de Usuários Vinculados',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Usuários vinculados — $instituicaoNome',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                        ),
                        icon: const Icon(
                          Icons.person_add,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Cadastrar Usuário',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onAbrirAdicionarUsuario(instituicaoId);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildChipContador('Admins', totalAdmin, Colors.red),
                      _buildChipContador('Acess2', totalAcess2, Colors.orange),
                      _buildChipContador('Acess3', totalAcess3, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Todos', 'Admin', 'Acess2', 'Acess3'].map((
                        nivel,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(nivel),
                            selected: _filtroNivelAtivo == nivel,
                            selectedColor: Colors.purple.shade100,
                            onSelected: (val) {
                              if (val) {
                                (context as Element).markNeedsBuild();
                                setState(() => _filtroNivelAtivo = nivel);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: usuariosFiltrados.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum usuário localizado neste nível.',
                            ),
                          )
                        : ListView.builder(
                            itemCount: usuariosFiltrados.length,
                            itemBuilder: (context, idx) {
                              final user = usuariosFiltrados[idx];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(user['nome'] ?? 'Sem Nome'),
                                  subtitle: Text(
                                    '${user['email']} \nNível: ${user['role']}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Editar Usuário',
                                        onPressed: () {
                                          Navigator.pop(context);
                                          widget.onEditarUsuario(
                                            user,
                                            instituicaoId,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Remover Usuário',
                                        onPressed: () async {
                                          await refConsumer
                                              .read(masterProvider.notifier)
                                              .removerUsuario(
                                                user['id'],
                                                instituicaoId,
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChipContador(String label, int total, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $total',
        style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
