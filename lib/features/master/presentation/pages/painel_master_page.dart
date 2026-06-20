import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../auth/presentation/pages/meu_perfil_page.dart';
import '../providers/master_providers.dart';
import '../widgets/organisms/master_home_tab.dart';
import '../widgets/organisms/master_controladoria_tab.dart';
import '../widgets/organisms/master_instituicoes_tab.dart';
import '../widgets/organisms/master_auditoria_tab.dart';

class PainelMasterPage extends ConsumerStatefulWidget {
  const PainelMasterPage({super.key});

  @override
  ConsumerState<PainelMasterPage> createState() => _PainelMasterPageState();
}

class _PainelMasterPageState extends ConsumerState<PainelMasterPage> {
  final _nomeInstituicaoController = TextEditingController();
  final _idInstituicaoController = TextEditingController();
  dynamic _logoArquivoOuUrl; 

  final _nomeUsuarioController = TextEditingController();
  final _emailUsuarioController = TextEditingController();
  final _senhaUsuarioController = TextEditingController();
  String _selectedRole = 'Acess3';
  bool _senhaOculta = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(masterProvider.notifier).carregarHome();
    });
  }

  @override
  void dispose() {
    _nomeInstituicaoController.dispose();
    _idInstituicaoController.dispose();
    _nomeUsuarioController.dispose();
    _emailUsuarioController.dispose();
    _senhaUsuarioController.dispose();
    super.dispose();
  }

  // CORREÇÃO CRUCIAL AQUI: Removendo travas para forçar recarregamento ao trocar de aba
  void _verificarECarregarDados(int index) {
    switch (index) {
      case 0:
        ref.read(masterProvider.notifier).carregarHome();
        break;
      case 2:
        // Força a atualização da lista direto do Firestore ao entrar na aba
        ref.read(masterProvider.notifier).carregarInstituicoes();
        break;
      case 3:
        ref.read(masterProvider.notifier).carregarLogsAuditoria('Todas');
        break;
    }
  }

  Future<void> _selecionarLogoDoDispositivo(StateSetter setDialogState) async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, 
    );
    if (resultado != null && resultado.files.isNotEmpty) {
      setDialogState(() {
        _logoArquivoOuUrl = resultado.files.single; 
      });
    }
  }

  Future<void> _processarExclusaoEmCascata(
    String id,
    bool deletarUsuarios,
  ) async {
    try {
      final notifier = ref.read(masterProvider.notifier);
      if (deletarUsuarios) {
        final estado = ref.read(masterProvider);
        for (var user in estado.usuariosDaInstituicao) {
          await notifier.removerUsuario(user['id'], id);
        }
      }
      await notifier.deletarInstituicao(id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏛️ Instituição removida com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar exclusão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _tentarExcluirInstituicao(String id, String nome) async {
    try {
      await ref
          .read(masterProvider.notifier)
          .carregarUsuariosDaInstituicao(id, 'Todos');
      if (!mounted) return;

      final estadoAtual = ref.read(masterProvider);
      final totalUsuarios = estadoAtual.usuariosDaInstituicao.length;

      if (totalUsuarios > 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  'Excluir Instituição?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'A instituição "$nome" possui $totalUsuarios usuários vinculados.\n\nDeseja excluir tudo permanentemente?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => _processarExclusaoEmCascata(id, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text(
                  'Sim, Excluir Tudo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      } else {
        await ref.read(masterProvider.notifier).deletarInstituicao(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏛️ Instituição "$nome" removida.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MasterDashboardState>(masterProvider, (previous, next) {
      if (next.erro != null && next.erro != previous?.erro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.erro!), backgroundColor: Colors.red),
        );
      }
    });

    final abaAtiva = ref.watch(masterAbaAtivaProvider);
    final state = ref.watch(masterProvider);

    ref.listen<int>(masterAbaAtivaProvider, (_, nextIndex) {
      _verificarECarregarDados(nextIndex);
    });

    final List<String> titulos = [
      'Painel Master — Visão Geral',
      'Painel Master — Controladoria Financeira',
      'Painel Master — Gerenciar Instituições',
      'Painel Master — Auditoria de Logs',
      'Painel Master — Meu Perfil',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titulos[abaAtiva]),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: abaAtiva,
              children: [
                MasterHomeTab(state: state),
                MasterControladoriaTab(state: state),
                MasterInstituicoesTab(
                  state: state,
                  nomeInstituicaoController: _nomeInstituicaoController,
                  onAbrirEdicao: _abrirFormularioInstituicao,
                  onTentarexcluir: _tentarExcluirInstituicao,
                  onAbrirAdicionarUsuario: (instituicaoId) {
                    _abrirModalUsuarioForm(instituicaoId);
                  },
                  onEditarUsuario: (usuario, instituicaoId) {
                    _abrirModalUsuarioForm(
                      instituicaoId as String,
                      usuario as Map<String, dynamic>,
                    );
                  },
                ),
                MasterAuditoriaTab(state: state),
                const MeuPerfilPage(),
              ],
            ),
    );
  }

  void _abrirFormularioInstituicao(
    String id,
    String nomeAtual,
    String corHex,
    String? logoUrl,
  ) {
    final bool isEdicao = id.isNotEmpty;
    _nomeInstituicaoController.text = nomeAtual;
    _idInstituicaoController.text = id;
    _logoArquivoOuUrl = logoUrl; 
    String corSelecionadaHex = corHex.replaceAll('#', '');

    final List<String> paletaCores = [
      '4CAF50',
      '2196F3',
      'FF9800',
      'E91E63',
      '9C27B0',
      '3F51B5',
      '00BCD4',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEdicao ? 'Editar Instituição' : 'Cadastrar Nova Instituição',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEdicao) ...[
                  TextField(
                    controller: _idInstituicaoController,
                    decoration: const InputDecoration(
                      labelText: 'ID customizado do banco (Opcional)',
                      helperText: 'Deixe em branco para gerar automático',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _nomeInstituicaoController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Instituição*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () => _selecionarLogoDoDispositivo(setDialogState),
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Buscar Logo do Dispositivo'),
                ),
                if (_logoArquivoOuUrl != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _logoArquivoOuUrl is PlatformFile
                        ? 'Arquivo selecionado: ${(_logoArquivoOuUrl as PlatformFile).name}'
                        : 'Logo atual em nuvem existente',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                ],
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecione a Cor Primária:*',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: paletaCores.map((hex) {
                    final bool selecionada = corSelecionadaHex == hex;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => corSelecionadaHex = hex),
                      child: CircleAvatar(
                        backgroundColor: Color(int.parse('FF$hex', radix: 16)),
                        radius: 18,
                        child: selecionada
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nomeInstituicaoController.text.trim().isEmpty) return;

                try {
                  final notifier = ref.read(masterProvider.notifier);

                  if (isEdicao) {
                    await notifier.atualizarInstituicao(
                      id,
                      _nomeInstituicaoController.text.trim(),
                      corSelecionadaHex,
                      _logoArquivoOuUrl, 
                    );
                  } else {
                    await notifier.criarInstituicao(
                      _nomeInstituicaoController.text.trim(),
                      '#$corSelecionadaHex',
                      _logoArquivoOuUrl, 
                      _idInstituicaoController.text.trim(),
                    );
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Erro interno: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalUsuarioForm(
    String instituicaoId, [
    Map<String, dynamic>? usuarioExistente,
  ]) {
    final bool isEdicao = usuarioExistente != null;
    _nomeUsuarioController.text = isEdicao
        ? (usuarioExistente['nome'] ?? '')
        : '';
    _emailUsuarioController.text = isEdicao
        ? (usuarioExistente['email'] ?? '')
        : '';
    _selectedRole = isEdicao
        ? (usuarioExistente['role'] ?? 'Acess3')
        : 'Acess3';
    _senhaUsuarioController.clear();
    _senhaOculta = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          title: Text(
            isEdicao
                ? 'Editar Usuário Vinculado'
                : 'Cadastrar Usuário na Instituição',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Usuário*',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Acess2', child: Text('Acess2')),
                    DropdownMenuItem(value: 'Acess3', child: Text('Acess3')),
                  ],
                  onChanged: (val) => setStateModal(() => _selectedRole = val!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nomeUsuarioController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Usuário*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailUsuarioController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail*',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (!isEdicao) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _senhaUsuarioController,
                    obscureText: _senhaOculta,
                    decoration: InputDecoration(
                      labelText: 'Senha*',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _senhaOculta
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setStateModal(() => _senhaOculta = !_senhaOculta),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nomeUsuarioController.text.isEmpty ||
                    _emailUsuarioController.text.isEmpty)
                  return;
                if (!isEdicao && _senhaUsuarioController.text.isEmpty) return;

                final notifier = ref.read(masterProvider.notifier);

                if (isEdicao) {
                  await notifier.atualizarUsuarioNaInstituicao({
                    'id': usuarioExistente['id'],
                    'nome': _nomeUsuarioController.text.trim(),
                    'email': _emailUsuarioController.text.trim(),
                    'role': _selectedRole,
                    'instituicaoId': instituicaoId,
                  });
                } else {
                  await notifier.adicionarUsuarioNaInstituicao({
                    'nome': _nomeUsuarioController.text.trim(),
                    'email': _emailUsuarioController.text.trim(),
                    'role': _selectedRole,
                    'instituicaoId': instituicaoId,
                  }, _senhaUsuarioController.text.trim());
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdicao ? 'Atualizar' : 'Criar'),
            ),
          ],
        ),
      ),
    );
  }
}