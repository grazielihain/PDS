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

class _PainelMasterPageState extends ConsumerState<PainelMasterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nomeInstituicaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(masterProvider.notifier).carregarHome();
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 0:
            ref.read(masterProvider.notifier).carregarHome();
            break;
          case 2:
            ref.read(masterProvider.notifier).carregarInstituicoes();
            break;
          case 3:
            ref.read(masterProvider.notifier).carregarLogsAuditoria('Todas');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeInstituicaoController.dispose();
    super.dispose();
  }

  void _gerenciarEdicao(String id, String nome, String corHex, String? logoUrl) {
    final editarNomeCtrl = TextEditingController(text: nome);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Instituição'),
        content: TextField(
          controller: editarNomeCtrl,
          decoration: const InputDecoration(labelText: 'Nome da Instituição', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (editarNomeCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await ref.read(masterProvider.notifier).criarInstituicao(
                    editarNomeCtrl.text.trim(),
                    corHex,
                    logoUrl,
                    customId: id,
                  );
              ref.read(masterProvider.notifier).carregarInstituicoes(forceRefresh: true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _gerenciarExclusao(String id, String nome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Instituição'),
        content: Text('Deseja realmente excluir a instituição $nome?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(masterProvider.notifier).removerUsuario(id, id); 
              ref.read(masterProvider.notifier).carregarInstituicoes(forceRefresh: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
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
          isScrollable: true,
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
                  onAbrirEdicao: _gerenciarEdicao,
                  onTentarexcluir: _gerenciarExclusao,
                  onAbrirAdicionarUsuario: (instituicaoId) {
                    ref.read(masterProvider.notifier).carregarUsuariosDaInstituicao(instituicaoId, 'Todos');
                  },
                ),
                MasterAuditoriaTab(state: state),
                const MeuPerfilPage(),
              ],
            ),
    );
  }
}