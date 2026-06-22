import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/inspecionar_simulado_page.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/resultado_simulado_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/simulados/presentation/pages/quiz_selection_page.dart';
import '../../features/auth/presentation/pages/meu_perfil_page.dart';
import '../../features/simulados/presentation/pages/historico_simulado_page.dart';
import '../presentation/pages/main_layout_shell.dart';
import '../../features/simulados/presentation/pages/simulado_page.dart';
import 'package:rumo_quiz/features/auth/presentation/pages/cadastro_usuario_page.dart';
import 'package:rumo_quiz/features/master/presentation/pages/tela_auditoria_page.dart';
import 'package:rumo_quiz/features/master/presentation/pages/dashboard_analitico_page.dart';

// 🟢 UNIFICADO: Importamos o DataSource oficial da aplicação para ler as Streams direto da fonte real
import '../../features/auth/presentation/providers/auth_notifier.dart';

// Provedor do Estado de Autenticação (Se está logado ou não no Firebase Auth)
final authStateProvider = StreamProvider<bool>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return dataSource.watchAuthState();
});

// Provedor do Perfil do Usuário (Lê os dados normalizados do Firestore)
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return dataSource.watchProfile();
});

final routerProvider = Provider<GoRouter>((ref) {
  // Lendo os estados assíncronos usando .valueOrNull para evitar quebras em tempo de execução
  final bool loggedIn = ref.watch(authStateProvider).valueOrNull ?? false;
  final Map<String, dynamic>? dadosUsuario = ref.watch(userProfileProvider).valueOrNull;
  
  final String role = (dadosUsuario?['role'] ?? 'acesso').toString().toLowerCase().trim();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: RouterNotifier(ref),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';

      // 1. Se não estiver logado e não estiver na tela de login, força ir para o Login
      if (!loggedIn) {
        return loggingIn ? null : '/login';
      }

      // 2. Se estiver logado e na tela de login, decide a rota de destino baseado no perfil
      if (loggingIn) {
        // Se a stream do Firestore ainda está buscando os dados, segura um instante para evitar pulo de tela nulo
        if (dadosUsuario == null) return null;

        if (role == 'master') return '/master/home';
        if (role == 'admin') return '/admin';
        return '/quiz-selection';
      }

      final location = state.matchedLocation;

      // 3. Proteção de Rotas Administrativas (Nível Master/Admin)
      if ((location.startsWith('/master/') || location == '/auditoria-master') && role != 'master') {
        return '/quiz-selection';
      }

      final adminRoutes = ['/admin', '/cadastro-usuarios', '/dashboard-analitico'];
      if (adminRoutes.contains(location) && role != 'admin' && role != 'master') {
        return '/quiz-selection';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => MainLayoutShell(child: child),
        routes: [
          GoRoute(path: '/quiz-selection', builder: (context, state) => const QuizSelectionPage()),
          GoRoute(path: '/perfil', builder: (context, state) => const MeuPerfilPage()),
          GoRoute(path: '/historico', builder: (context, state) => const HistoricoSimuladoPage()),
          GoRoute(
            path: '/master/:view',
            builder: (context, state) {
              final view = state.pathParameters['view'] ?? 'home';
              return DashboardAnaliticoPage(subTela: view);
            },
          ),
          GoRoute(path: '/cadastro-usuarios', builder: (context, state) => const CadastroUsuarioPage()),
          GoRoute(path: '/auditoria-master', builder: (context, state) => const TelaAuditoriaPage(visaoMaster: true)),
          GoRoute(
            path: '/resultado',
            builder: (context, state) {
              final dados = state.extra as Map<String, dynamic>? ?? {};
              final int total = dados['totalQuestoes'] ?? 0;
              final int acertos = dados['acertos'] ?? 0;
              final double taxa = total > 0 ? (acertos / total) * 100 : 0.0;
              
              List<RevisaoQuestaoModel> listaQuestoes = [];
              if (dados['revisaoQuestoes'] != null) {
                final listaCrua = dados['revisaoQuestoes'] as List;
                listaQuestoes = listaCrua.map((item) {
                  if (item is RevisaoQuestaoModel) return item;
                  return RevisaoQuestaoModel.fromMap(Map<String, dynamic>.from(item as Map));
                }).toList();
              }

              return ResultadoSimuladoPage(
                tituloSimulado: dados['categoria'] ?? 'Simulado Realizado',
                acertos: acertos,
                totalQuestoes: total,
                erros: total - acertos,
                notaObtida: (dados['notaObtida'] as num?)?.toDouble() ?? 0.0,
                notaMaxima: (dados['notaMaxima'] as num?)?.toDouble() ?? 10.0,
                tempoUtilizadoSegundos: dados['tempoUtilizadoSegundos'] ?? 0,
                revisaoQuestoes: listaQuestoes,
                mensagemFinalizacaoAdmin: dados['mensagemFinalizacaoAdmin'] ?? 'Parabéns!',
                pontosGamificacao: dados['pontosGamificacao'] ?? 0,
                nomeDoAluno: dados['nomeDoAluno'] ?? 'Estudante',
                instituicaoDoAluno: dados['instituicaoDoAluno'] ?? 'Minha Instituição',
                logoUrl: dados['logoUrl'],
                taxaAcerto: taxa,
              );
            },
          ),
          GoRoute(
            path: '/inspecionar',
            builder: (context, state) {
              final dados = state.extra as Map<String, dynamic>? ?? {};
              final String titulo = dados['tituloSimulado'] as String? ?? 'Simulado';
              
              List<RevisaoQuestaoModel> listaQuestoes = [];
              if (dados['revisaoQuestoes'] != null) {
                final listaCrua = dados['revisaoQuestoes'] as List;
                listaQuestoes = listaCrua.map((item) {
                  if (item is RevisaoQuestaoModel) return item;
                  return RevisaoQuestaoModel.fromMap(Map<String, dynamic>.from(item as Map));
                }).toList();
              }

              return InspecionarSimuladoPage(
                tituloSimulado: titulo,
                revisaoQuestoes: listaQuestoes,
              );
            },
          ),
        ],
      ),
      GoRoute(path: '/executar-simulado', builder: (context, state) => const SimuladoPage()),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Página não encontrada!')),
    ),
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }
}