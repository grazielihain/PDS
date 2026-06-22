import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/master_providers.dart';

class MasterInstituicoesTab extends ConsumerStatefulWidget {
  final MasterDashboardState state;
  final TextEditingController nomeInstituicaoController;
  final Function(String id, String nome, String corHex, String? logoUrl) onAbrirEdicao;
  final Function(String id, String nome) onTentarexcluir;
  final Function(String instituicaold) onAbrirAdicionarUsuario;

  const MasterInstituicoesTab({
    super.key,
    required this.state,
    required this.nomeInstituicaoController,
    required this.onAbrirEdicao,
    required this.onTentarexcluir,
    required this.onAbrirAdicionarUsuario,
  });

  @override
  ConsumerState<MasterInstituicoesTab> createState() => _MasterInstituicoesTabState();
}

class _MasterInstituicoesTabState extends ConsumerState<MasterInstituicoesTab> {
  static const Color corPadraoMaster = Colors.purple;
  final TextEditingController _idBancoController = TextEditingController();
  String _corSelecionadaHex = '#9C27B0';
  String? _logoSimuladaPath;
  bool _exibirFormulario = false;

  final List<Map<String, dynamic>> _paletaCores = [
    {'nome': 'Roxo', 'hex': '#9C27B0', 'color': Colors.purple},
    {'nome': 'Azul', 'hex': '#1976D2', 'color': Colors.blue},
    {'nome': 'Verde', 'hex': '#388E3C', 'color': Colors.green},
    {'nome': 'Laranja', 'hex': '#F57C00', 'color': Colors.orange},
    {'nome': 'Vermelho', 'hex': '#D32F2F', 'color': Colors.red},
    {'nome': 'Ciano', 'hex': '#0097A7', 'color': Colors.cyan},
  ];

  @override
  void dispose() {
    _idBancoController.dispose();
    super.dispose();
  }

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
                'Painel de Instituições & Clientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: corPadraoMaster,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _exibirFormulario = !_exibirFormulario;
                  });
                },
                icon: Icon(_exibirFormulario ? Icons.close : Icons.add_business),
                label: Text(_exibirFormulario ? 'Fechar' : 'Nova Instituição'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _exibirFormulario ? Colors.grey : corPadraoMaster,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_exibirFormulario) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cadastrar Nova Instituição',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: widget.nomeInstituicaoController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Instituição *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _idBancoController,
                      decoration: const InputDecoration(
                        labelText: 'Identificador Único no Banco (ID) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _paletaCores.map((item) {
                        final bool isSelected = _corSelecionadaHex == item['hex'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _corSelecionadaHex = item['hex']);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item['color'],
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 2.5)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            widget.nomeInstituicaoController.clear();
                            _idBancoController.clear();
                            setState(() {
                              _exibirFormulario = false;
                            });
                          },
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final nomeInput = widget.nomeInstituicaoController.text.trim();
                            final idInput = _idBancoController.text.trim();

                            if (nomeInput.isEmpty || idInput.isEmpty) return;

                            widget.nomeInstituicaoController.clear();
                            _idBancoController.clear();
                            setState(() => _exibirFormulario = false);

                            try {
                              await ref.read(masterProvider.notifier).criarInstituicao(
                                    nomeInput,
                                    _corSelecionadaHex,
                                    _logoSimuladaPath,
                                    customId: idInput,
                                  );
                              ref.read(masterProvider.notifier).carregarInstituicoes(forceRefresh: true);
                            } catch (e) {
                              print("Erro ao criar: $e");
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: corPadraoMaster, foregroundColor: Colors.white),
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Divider(height: 32),
          Expanded(
            child: RefreshIndicator(
              color: corPadraoMaster,
              onRefresh: () => ref.read(masterProvider.notifier).carregarInstituicoes(forceRefresh: true),
              child: instDocs.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Center(child: Text('Nenhuma instituição cadastrada.')),
                    )
                  : ListView.builder(
                      itemCount: instDocs.length,
                      itemBuilder: (context, index) {
                        final inst = instDocs[index];
                        Color corInstituicao;
                        try {
                          final hex = inst.corPrimaria.replaceAll('#', '');
                          corInstituicao = Color(int.parse('FF$hex', radix: 16));
                        } catch (_) {
                          corInstituicao = corPadraoMaster;
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: corInstituicao.withOpacity(0.15),
                              child: Icon(Icons.business, color: corInstituicao),
                            ),
                            title: Text(inst.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('ID: ${inst.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(masterProvider.notifier).carregarUsuariosDaInstituicao(inst.id, 'Todos');
                                    _abrirModalGerenciarUsuarios(context, inst.id, inst.nome);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                                  child: const Text('Usuários'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => widget.onAbrirEdicao(
                                    inst.id,
                                    inst.nome,
                                    inst.corPrimaria,
                                    inst.logoUrl,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => widget.onTentarexcluir(
                                    inst.id,
                                    inst.nome,
                                  ),
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

  void _abrirModalGerenciarUsuarios(BuildContext context, String instituicaoId, String nomeInstituicao) {
    String filtroNivelLocal = 'Todos';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Consumer(
          builder: (context, modalRef, child) {
            final appState = modalRef.watch(masterProvider);
            final usuariosDaInst = appState.usuariosDaInstituicao.where((u) => u['instituicaoId'] == instituicaoId).toList();

            final int totalAdmin = usuariosDaInst.where((u) => u['role'].toString().toLowerCase() == 'admin').length;
            final int totalAcess2 = usuariosDaInst.where((u) => u['role'].toString().toLowerCase() == 'acess2').length;
            final int totalAcess3 = usuariosDaInst.where((u) => u['role'].toString().toLowerCase() == 'acess3').length;

            final listaFiltrada = usuariosDaInst.where((u) {
              if (filtroNivelLocal == 'Todos') return true;
              return u['role'].toString().toLowerCase() == filtroNivelLocal.toLowerCase();
            }).toList();

            return StatefulBuilder(
              builder: (context, changeModalState) {
                return Padding(
                  padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Usuários: $nomeInstituicao', style: const TextStyle(fontWeight: FontWeight.bold, color: corPadraoMaster))),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildCardContador('Admin', totalAdmin, Colors.amber.shade900),
                            _buildCardContador('Acess2', totalAcess2, Colors.blue.shade700),
                            _buildCardContador('Acess3', totalAcess3, Colors.grey.shade700),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownButton<String>(
                              value: filtroNivelLocal,
                              items: const [
                                DropdownMenuItem(value: 'Todos', child: Text('Todos Níveis')),
                                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                DropdownMenuItem(value: 'Acess2', child: Text('Acess2')),
                                DropdownMenuItem(value: 'Acess3', child: Text('Acess3')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  modalRef.read(masterProvider.notifier).carregarUsuariosDaInstituicao(instituicaoId, val);
                                  changeModalState(() => filtroNivelLocal = val);
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _abrirModalCriarUsuarioInterno(context, instituicaoId, modalRef),
                              icon: const Icon(Icons.person_add, size: 16),
                              label: const Text('Novo Usuário'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                        const Divider(),
                        Expanded(
                          child: listaFiltrada.isEmpty
                              ? const Center(child: Text('Nenhum usuário encontrado.'))
                              : ListView.builder(
                                  itemCount: listaFiltrada.length,
                                  itemBuilder: (context, idx) {
                                    final user = listaFiltrada[idx];
                                    return Card(
                                      child: ListTile(
                                        title: Text(user['nome'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(user['email'] ?? ''),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () async {
                                            await modalRef.read(masterProvider.notifier).removerUsuario(user['id'], instituicaoId);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCardContador(String label, int total, Color cor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Column(
          children: [
            Text('$total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cor)),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _abrirModalCriarUsuarioInterno(BuildContext context, String instituicaoId, WidgetRef modalRef) {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    String tipoSelecionado = 'Acess3';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cadastrar Usuário', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tipoSelecionado,
                    decoration: const InputDecoration(labelText: 'Tipo *', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin (Acess1)')),
                      DropdownMenuItem(value: 'Acess2', child: Text('Gestor (Acess2)')),
                      DropdownMenuItem(value: 'Acess3', child: Text('Estudante (Acess3)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tipoSelecionado = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome *', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'E-mail *', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: senhaCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Senha *', border: OutlineInputBorder())),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (nomeCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || senhaCtrl.text.trim().isEmpty) return;

                    final dados = {
                      'nome': nomeCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'role': tipoSelecionado,
                      'instituicaoId': instituicaoId,
                    };

                    await modalRef.read(masterProvider.notifier).adicionarUsuarioNaInstituicao(dados, senhaCtrl.text.trim());
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: corPadraoMaster, foregroundColor: Colors.white),
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}