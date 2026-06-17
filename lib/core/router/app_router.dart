import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Imports blindados apontando para a pasta unificada de simulados
import 'package:rumo_quiz/features/simulados/data/models/questao_model.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/resultado_simulado_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/simulados/presentation/pages/quiz_selection_page.dart';
import '../../features/auth/presentation/pages/meu_perfil_page.dart';
import '../../features/simulados/presentation/pages/historico_simulado_page.dart';
import '../presentation/pages/main_layout_shell.dart';
import '../../features/simulados/presentation/pages/simulado_page.dart';
import 'package:rumo_quiz/features/admin/presentation/pages/painel_admin_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final loggedIn = user != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn && !loggingIn) return '/login';

      if (loggedIn && loggingIn) {
        // 💰 ZERO LEITURAS NO FIRESTORE: O login_page.dart se encarrega de empurrar o usuário
        // para a rota correspondente logo após o sucesso da autenticação.
        return '/quiz-selection';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      GoRoute(
        path: '/admin-painel',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>? ?? {};
          final idDaInstituicao =
              params['instituicaoId']?.toString() ?? 'ulbra-01';
          return PainelAdminPage(substituicaoInstituicaoId: idDaInstituicao);
        },
      ),

      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            const PainelAdminPage(substituicaoInstituicaoId: 'ulbra-01'),
      ),

      // Rota Master segura integrada
      GoRoute(
        path: '/master-home',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Painel Master 🚀',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),

      ShellRoute(
        builder: (context, state, child) => MainLayoutShell(child: child),
        routes: [
          GoRoute(
            path: '/quiz-selection',
            builder: (context, state) => const QuizSelectionPage(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const MeuPerfilPage(),
          ),
          GoRoute(
            path: '/historico',
            builder: (context, state) => const HistoricoSimuladoPage(),
          ),

          GoRoute(
            path: '/resultado',
            builder: (context, state) {
              final dados = state.extra as Map<String, dynamic>? ?? {};
              return ResultadoSimuladoPage(
                tituloSimulado: dados['categoria'] ?? 'Simulado Realizado',
                acertos: dados['acertos'] ?? 0,
                totalQuestoes: dados['totalQuestoes'] ?? 0,
                erros: (dados['totalQuestoes'] ?? 0) - (dados['acertos'] ?? 0),
                notaObtida: (dados['notaObtida'] as num?)?.toDouble() ?? 0.0,
                notaMaxima: (dados['notaMaxima'] as num?)?.toDouble() ?? 10.0,
                tempoUtilizadoSegundos: dados['tempoUtilizadoSegundos'] ?? 0,
                revisaoQuestoes: const [],
                mensagemFinalizacaoAdmin:
                    dados['mensagemFinalizacaoAdmin'] ?? 'Parabéns!',
                pontosGamificacao: dados['pontosGamificacao'] ?? 0,
                nomeDoAluno: dados['nomeDoAluno'] ?? 'Estudante',
                instituicaoDoAluno:
                    dados['instituicaoDoAluno'] ?? 'Minha Instituição',
                logoUrl: dados['logoUrl'],
                taxaAcerto: 0.0,
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: '/executar-simulado',
        builder: (context, state) => const SimuladoPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página não encontrada!'))),
  );
}
