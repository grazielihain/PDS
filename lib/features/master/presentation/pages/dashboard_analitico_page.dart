import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/pages/meu_perfil_page.dart';
import '../providers/master_providers.dart';
import '../widgets/organisms/master_home_tab.dart';
import '../widgets/organisms/master_instituicoes_tab.dart';
import '../widgets/organisms/master_auditoria_tab.dart';
import '../widgets/organisms/master_controladoria_tab.dart';

class DashboardAnaliticoPage extends ConsumerStatefulWidget {
  final String subTela;
  const DashboardAnaliticoPage({super.key, this.subTela = 'home'});

  @override
  ConsumerState<DashboardAnaliticoPage> createState() => _DashboardAnaliticoPageState();
}

class _DashboardAnaliticoPageState extends ConsumerState<DashboardAnaliticoPage> {
  late final TextEditingController _nomeInstituicaoController;

  @override
  void initState() {
    super.initState();
    _nomeInstituicaoController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosDaSubTela(widget.subTela);
    });
  }

  @override
  void dispose() {
    _nomeInstituicaoController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardAnaliticoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subTela != widget.subTela) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carregarDadosDaSubTela(widget.subTela);
      });
    }
  }

  void _carregarDadosDaSubTela(String tela) {
    switch (tela) {
      case 'home':
        ref.read(masterProvider.notifier).carregarHome();
        break;
      case 'controladoria':
        ref.read(masterProvider.notifier).carregarControladoria('Todas');
        break;
      case 'instituicoes':
        ref.read(masterProvider.notifier).carregarInstituicoes();
        break;
      case 'auditoria':
        ref.read(masterProvider.notifier).carregarLogsAuditoria('Todas');
        break;
    }
  }

  // --- LÓGICA DE EDIÇÃO COMPATÍVEL ---
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
              // Certifique-se de que o seu notifier tenha essa função ou adapte para a sua função de update
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

  // --- LÓGICA DE EXCLUSÃO COMPATÍVEL ---
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
              // Caso seu notifier use outro nome como 'removerInstituicao', mude aqui:
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
    if (widget.subTela == 'perfil') {
      return const MeuPerfilPage();
    }

    final state = ref.watch(masterProvider);
    Widget conteudoInterno;

    if (state.isLoading) {
      conteudoInterno = const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)));
    } else if (state.erro != null) {
      conteudoInterno = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.erro!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _carregarDadosDaSubTela(widget.subTela),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    } else {
      switch (widget.subTela) {
        case 'controladoria':
          conteudoInterno = MasterControladoriaTab(state: state);
          break;
        case 'instituicoes':
          conteudoInterno = MasterInstituicoesTab(
            state: state,
            nomeInstituicaoController: _nomeInstituicaoController,
            onAbrirEdicao: _gerenciarEdicao,
            onTentarexcluir: _gerenciarExclusao,
            onAbrirAdicionarUsuario: (instituicaoId) {
              ref.read(masterProvider.notifier).carregarUsuariosDaInstituicao(instituicaoId, 'Todos');
            },
          );
          break;
        case 'auditoria':
          conteudoInterno = MasterAuditoriaTab(state: state);
          break;
        case 'home':
        default:
          conteudoInterno = MasterHomeTab(state: state);
          break;
      }
    }

    return Scaffold(
      body: Row(
        children: [
          Expanded(child: conteudoInterno),
        ],
      ),
    );
  }
}