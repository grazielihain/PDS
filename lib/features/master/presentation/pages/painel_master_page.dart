import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _PainelMasterPageState extends ConsumerState<PainelMasterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nomeInstituicaoController = TextEditingController();

  // Controladores para edição/criação de usuários internos da instituição
  final _nomeUsuarioController = TextEditingController();
  final _emailUsuarioController = TextEditingController();
  String _selectedRole = 'Acess3';

  @override
  void initState() {
    super.initState();
    // 📊 EXPANSÃO CORE: Elevado de 3 para 5 abas operacionais independentes
    _tabController = TabController(length: 5, vsync: this);
    
    // Dispara a carga de dados inicial da primeira aba assim que a tela monta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(masterProvider.notifier).carregarHome();
    });

    // Escuta a mudança de abas para carregar os dados sob demanda, poupando requisições
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 0:
            ref.read(masterProvider.notifier).carregarHome();
            break;
          case 1:
            // Controladoria possui sua carga interna atrelada ao filtro por post-frame
            break;
          case 2:
            ref.read(masterProvider.notifier).carregarInstituicoes();
            break;
          case 3:
            ref.read(masterProvider.notifier).carregarLogsAuditoria('Todas');
            break;
          case 4:
            // Perfil gerencia seu estado interno autonomamente
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeInstituicaoController.dispose();
    _nomeUsuarioController.dispose();
    _emailUsuarioController.dispose();
    super.dispose();
  }

  /// Exclui a instituição e gerencia o estado através da Clean Architecture
  Future<void> _processarExclusaoEmCascata(
    String id,
    bool deletarUsuarios,
  ) async {
    try {
      final notifier = ref.read(masterProvider.notifier);
      
      if (deletarUsuarios) {
        // Remove os usuários vinculados antes de deletar a IE
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
            content: Text('🏛️ Instituição e dependências atualizadas com sucesso.'),
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

  /// Abre diálogo inteligente perguntando sobre exclusão em lote
  Future<void> _tentarExcluirInstituicao(String id, String nome) async {
    try {
      await ref.read(masterProvider.notifier).carregarUsuariosDaInstituicao(id, 'Todos');
      
      if (!mounted) return;
      
      final estadoAtual = ref.read(masterProvider);
      final totalUsuarios = estadoAtual.usuariosDaInstituicao.length;

      if (totalUsuarios > 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text('Excluir Instituição?', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'A instituição "$nome" possui $totalUsuarios usuários vinculados.\n\n'
              'Deseja excluir a instituição juntamente com todos os cadastros de usuários vinculados?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => _processarExclusaoEmCascata(id, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sim, Excluir Tudo', style: TextStyle(fontWeight: FontWeight.bold)),
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
          SnackBar(
            content: Text('Erro ao checar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuta passivamente as mudanças de erro globais para emitir avisos na UI
    ref.listen<MasterDashboardState>(masterProvider, (previous, next) {
      if (next.erro != null && next.erro != previous?.erro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.erro!), backgroundColor: Colors.red),
        );
      }
    });

    final state = ref.watch(masterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rumo Quiz — Painel Master'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true, // Garante boa renderização de 5 abas em telas mobile
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Home Master'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Controladoria'),
            Tab(icon: Icon(Icons.account_balance_outlined), text: 'Instituições'),
            Tab(icon: Icon(Icons.security_outlined), text: 'Auditoria'),
            Tab(icon: Icon(Icons.person_pin_outlined), text: 'Meu Perfil'),
          ],
        ),
      ),
      body: state.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                MasterHomeTab(state: state),
                MasterControladoriaTab(state: state),
                MasterInstituicoesTab(
                  state: state,
                  nomeInstituicaoController: _nomeInstituicaoController,
                  onAbrirEdicao: _abrirModalEdicaoInstituicao,
                  onTentarexcluir: _tentarExcluirInstituicao,
                  onAbrirAdicionarUsuario: _abrirModalAdicionarUsuario,
                ),
                MasterAuditoriaTab(state: state),
                const MeuPerfilPage(), // Acoplamento direto e limpo do módulo auth preservando recursos
              ],
            ),
    );
  }

  void _abrirModalEdicaoInstituicao(String id, String nomeAtual, String corHex, String? logoUrl) {
    _nomeInstituicaoController.text = nomeAtual;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar Nome da Instituição'),
        content: TextField(
          controller: _nomeInstituicaoController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Nome',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_nomeInstituicaoController.text.trim().isEmpty) return;
              
              await ref.read(masterProvider.notifier).atualizarInstituicao(
                    id,
                    _nomeInstituicaoController.text.trim(),
                    corHex,
                    logoUrl,
                  );
              _nomeInstituicaoController.clear();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _abrirModalAdicionarUsuario(String instituicaoId) {
    _nomeUsuarioController.clear();
    _emailUsuarioController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          title: const Text('Adicionar Novo Usuário'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nomeUsuarioController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailUsuarioController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail de Acesso',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Nível de Acesso',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin (Acess1)')),
                    DropdownMenuItem(value: 'Acess2', child: Text('Gestor (Acess2)')),
                    DropdownMenuItem(value: 'Acess3', child: Text('Aluno (Acess3)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setStateModal(() => _selectedRole = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (_nomeUsuarioController.text.trim().isEmpty ||
                    _emailUsuarioController.text.trim().isEmpty) {
                  return;
                }

                final novosDados = {
                  'nome': _nomeUsuarioController.text.trim(),
                  'email': _emailUsuarioController.text.trim(),
                  'role': _selectedRole,
                  'instituicaoId': instituicaoId,
                };

                await ref.read(masterProvider.notifier).adicionarUsuarioNaInstituicao(
                      novosDados,
                      'SenhaPadrao123@',
                    );

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
