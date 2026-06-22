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
  ConsumerState<DashboardAnaliticoPage> createState() =>
      _DashboardAnaliticoPageState();
}

class _DashboardAnaliticoPageState extends ConsumerState<DashboardAnaliticoPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosDaSubTela(widget.subTela);
    });
  }

  @override
  void didUpdateWidget(covariant DashboardAnaliticoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subTela != widget.subTela) {
      // CORREÇÃO CRÍTICA: Executa após a renderização atual para evitar o travamento da UI
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

  Widget build(BuildContext context) {
  // Se a rota ativa for o perfil do master, renderiza a tela correspondente
  if (widget.subTela == 'perfil') {
    return const MeuPerfilPage();
  }

  final state = ref.watch(masterProvider);

  // O conteúdo interno fica condicionado ao carregamento, mas NUNCA o Scaffold principal!
  Widget conteudoInterno;

  if (state.isLoading) {
    conteudoInterno = const Center(
      child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
    );
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
          nomeInstituicaoController: TextEditingController(),
          onAbrirEdicao: (id, nome, cor, logo) {},
          onTentarexcluir: (id, nome) {},
          onAbrirAdicionarUsuario: (id) {},
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

  // Mantendo o Scaffold externo sempre ativo, o Menu e o Logout NUNCA travam!
  return Scaffold(
    body: Row(
      children: [
        // Se estiver usando o menu fixo na Web, ele continua renderizando aqui normalmente
        Expanded(child: conteudoInterno),
      ],
    ),
  );
}
}