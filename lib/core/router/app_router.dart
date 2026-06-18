import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rumo_quiz/features/simulados/data/models/questao_model.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/inspecionar_simulado_page.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/resultado_simulado_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/simulados/presentation/pages/quiz_selection_page.dart';
import '../../features/auth/presentation/pages/meu_perfil_page.dart';
import '../../features/simulados/presentation/pages/historico_simulado_page.dart';
import '../presentation/pages/main_layout_shell.dart';
import '../../features/simulados/presentation/pages/simulado_page.dart';
import 'package:rumo_quiz/features/admin/presentation/pages/painel_admin_page.dart';

// 📦 NOVOS IMPORTS ADICIONADOS DAS SPRINTS DIA 2 E DIA 3
import 'package:rumo_quiz/features/auth/presentation/pages/cadastro_usuario_page.dart';
import 'package:rumo_quiz/features/admin/presentation/pages/configuracao_gamificacao_page.dart';
import 'package:rumo_quiz/features/master/presentation/pages/painel_master_page.dart';
import 'package:rumo_quiz/features/admin/presentation/pages/tela_auditoria_page.dart';
import 'package:rumo_quiz/features/admin/presentation/pages/dashboard_analitico_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final loggedIn = user != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/quiz-selection';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

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

          // 🏛️ ROTAS DO DIA 2 E DIA 3 ACOPLADAS INTERNAMENTE AO SHELL COM MENU LATERAL
          GoRoute(
            path: '/admin',
            builder: (context, state) =>
                const PainelAdminPage(substituicaoInstituicaoId: 'ulbra-01'),
          ),
          GoRoute(
            path: '/master-home',
            builder: (context, state) => const PainelMasterPage(),
          ),
          GoRoute(
            path: '/cadastro-usuarios',
            builder: (context, state) => const CadastroUsuarioPage(),
          ),
          GoRoute(
            path: '/configuracao-gamificacao',
            builder: (context, state) => const ConfiguracaoGamificacaoPage(),
          ),
          GoRoute(
            path: '/auditoria-master',
            builder: (context, state) =>
                const TelaAuditoriaPage(visaoMaster: true),
          ),
          GoRoute(
            path: '/dashboard-analitico',
            builder: (context, state) => const DashboardAnaliticoPage(),
          ),

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
                  return RevisaoQuestaoModel.fromMap(
                    Map<String, dynamic>.from(item as Map),
                  );
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
                mensagemFinalizacaoAdmin:
                    dados['mensagemFinalizacaoAdmin'] ?? 'Parabéns!',
                pontosGamificacao: dados['pontosGamificacao'] ?? 0,
                nomeDoAluno: dados['nomeDoAluno'] ?? 'Estudante',
                instituicaoDoAluno:
                    dados['instituicaoDoAluno'] ?? 'Minha Instituição',
                logoUrl: dados['logoUrl'],
                taxaAcerto: taxa,
              );
            },
          ),

          GoRoute(
            path: '/inspecionar',
            builder: (context, state) {
              final dados = state.extra as Map<String, dynamic>? ?? {};
              final String titulo =
                  dados['tituloSimulado'] as String? ?? 'Simulado';

              List<RevisaoQuestaoModel> listaQuestoes = [];
              if (dados['revisaoQuestoes'] != null) {
                final listaCrua = dados['revisaoQuestoes'] as List;
                listaQuestoes = listaCrua.map((item) {
                  if (item is RevisaoQuestaoModel) return item;
                  return RevisaoQuestaoModel.fromMap(
                    Map<String, dynamic>.from(item as Map),
                  );
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

      GoRoute(
        path: '/executar-simulado',
        builder: (context, state) => const SimuladoPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página não encontrada!'))),
  );
}
