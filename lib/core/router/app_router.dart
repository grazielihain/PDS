import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rumo_quiz/features/simulados/data/datasources/simulado_remote_data_source.dart';
import 'package:rumo_quiz/features/simulados/data/models/questao_model.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/resultado_simulado_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/simulados/presentation/pages/quiz_selection_page.dart';
import '../../features/simulados/presentation/pages/fazer_quiz_page.dart';
import '../../features/simulados/presentation/pages/meus_resultados_page.dart';
import '../../features/auth/presentation/pages/meu_perfil_page.dart';
import '../../features/simulados/presentation/pages/historico_simulado_page.dart';
import '../presentation/pages/main_layout_shell.dart';
import '../../features/simulados/presentation/pages/simulado_page.dart';
import 'package:rumo_quiz/features/admin/presentation/pages/painel_admin_page.dart';
import 'package:rumo_quiz/features/admin/presentation/pages/painel_master_page.dart';

/// Cache de role para redirect síncrono do GoRouter.
/// Atualizado pelo MainLayoutShell assim que o documento do usuário carrega.
class UserRoleCache extends ChangeNotifier {
  static final UserRoleCache _instance = UserRoleCache._();
  factory UserRoleCache() => _instance;
  UserRoleCache._();

  String? _role;
  String? get role => _role;

  void update(String role) {
    if (_role != role) {
      _role = role;
      notifyListeners();
    }
  }

  void clear() {
    _role = null;
    notifyListeners();
  }
}

class AppRouter {
  static final _publicRoutes = {'/login'};
  static final _adminRoutes = {'/admin-painel', '/admin'};
  static final _masterRoutes = {'/master-painel'};

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: UserRoleCache(),
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isPublic = _publicRoutes.contains(state.matchedLocation);
      if (user == null && !isPublic) return '/login';

      if (user != null) {
        final role = UserRoleCache().role;
        // Só aplica restrição quando o role já foi carregado
        if (role != null) {
          final path = state.matchedLocation;
          if (_masterRoutes.contains(path) && role != 'Master') {
            return role == 'Admin' || role == 'Acess2'
                ? '/admin-painel'
                : '/quiz-selection';
          }
          if (_adminRoutes.contains(path) && role == 'Acess3') {
            return '/quiz-selection';
          }
        }
      }
      return null;
    },
    routes: [
      // Rota de login (fora do shell — sem cabeçalho/rodapé)
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // Execução do simulado (fullscreen — fora do shell por design)
      GoRoute(
        path: '/executar-simulado',
        builder: (context, state) => const SimuladoPage(),
      ),

      // Shell global — envolve todas as páginas autenticadas
      ShellRoute(
        builder: (context, state, child) => MainLayoutShell(child: child),
        routes: [
          GoRoute(
            path: '/master-painel',
            pageBuilder: (context, state) {
              final tabIndex =
                  int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
              return MaterialPage(
                key: const ValueKey('master-painel'),
                child: PainelMasterPage(initialTab: tabIndex),
              );
            },
          ),
          GoRoute(
            path: '/admin-painel',
            pageBuilder: (context, state) {
              final tabIndex =
                  int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
              final params = state.extra as Map<String, dynamic>? ?? {};
              final instId =
                  params['instituicaoId']?.toString() ?? 'ulbra-01';
              return MaterialPage(
                key: const ValueKey('admin-painel'),
                child: PainelAdminPage(
                  substituicaoInstituicaoId: instId,
                  initialTab: tabIndex,
                ),
              );
            },
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) {
              final tabIndex =
                  int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
              final params = state.extra as Map<String, dynamic>? ?? {};
              final instId =
                  params['instituicaoId']?.toString() ?? 'ulbra-01';
              return MaterialPage(
                key: ValueKey('admin-$instId'),
                child: PainelAdminPage(
                  substituicaoInstituicaoId: instId,
                  initialTab: tabIndex,
                ),
              );
            },
          ),
          GoRoute(
            path: '/quiz-selection',
            builder: (context, state) => const QuizSelectionPage(),
          ),
          GoRoute(
            path: '/fazer-quiz',
            builder: (context, state) => const FazerQuizPage(),
          ),
          GoRoute(
            path: '/meus-resultados',
            builder: (context, state) => const MeusResultadosPage(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const MeuPerfilPage(),
          ),
          GoRoute(
            path: '/historico',
            builder: (context, state) => const HistoricoSimuladoPage(),
          ),

          // Resultado do simulado — dados buscados via datasource (não mais no router)
          GoRoute(
            path: '/resultado',
            builder: (context, state) {
              final dados = state.extra as Map<String, dynamic>? ?? {};

              final listaCrua =
                  dados['listaRevisaoJson'] ??
                  dados['revisaoQuestoes'] ??
                  dados['questoes'] ??
                  dados['listaQuestoes'] ??
                  [];

              final listaModelos =
                  (listaCrua as List<dynamic>).map((item) {
                    final mapaItem = item as Map<String, dynamic>? ?? {};
                    final mapaQuestao =
                        mapaItem['questao'] as Map<String, dynamic>? ?? {};
                    final opcoesCruas =
                        mapaQuestao['opcoes'] ??
                        mapaQuestao['alternativas'] ??
                        [];
                    final listaOpcoes =
                        (opcoesCruas as List<dynamic>)
                            .map((o) => o.toString())
                            .toList();

                    return RevisaoQuestaoModel(
                      questao: QuestaoModel(
                        id: mapaQuestao['id']?.toString() ?? '',
                        pergunta:
                            mapaQuestao['pergunta'] ??
                            mapaQuestao['enunciado'] ??
                            mapaQuestao['texto'] ??
                            'Questão sem enunciado',
                        opcoes: listaOpcoes,
                        respostaCorretaIndex:
                            mapaQuestao['respostaCorretaIndex'] ??
                            mapaQuestao['opcaoCorretaIndex'] ??
                            mapaQuestao['alternativaCorretaIndex'] ??
                            0,
                        instituicaoId:
                            mapaQuestao['instituicaoId']?.toString() ??
                            dados['instituicaoId']?.toString() ??
                            'Geral',
                        categoriaId:
                            mapaQuestao['categoriaId']?.toString() ??
                            dados['categoria']?.toString() ??
                            'Geral',
                        assuntoId:
                            mapaQuestao['assuntoId']?.toString() ??
                            dados['assuntoId']?.toString() ??
                            'Geral',
                        justificativa:
                            mapaQuestao['justificativa'] as String? ?? '',
                      ),
                      opcaoEscolhidaIndex:
                          mapaItem['opcaoEscolhidaIndex'] ??
                          mapaQuestao['opcaoEscolhidaIndex'] ??
                          mapaQuestao['alternativaRespondidaIndex'] ??
                          mapaQuestao['opcaoSelecionadaIndex'] ??
                          mapaQuestao['respostaAlunoIndex'] ??
                          0,
                    );
                  }).toList();

              final int acertos = dados['acertos'] ?? 0;
              final int total = dados['totalQuestoes'] ?? 0;
              final double taxaAcerto = dados['taxaAcerto'] != null
                  ? (dados['taxaAcerto'] as num).toDouble()
                  : (total > 0 ? (acertos / total * 100).toDouble() : 0.0);

              final uid = FirebaseAuth.instance.currentUser?.uid;
              final nomeFallback =
                  dados['nomeDoAluno'] as String? ??
                  dados['nomeAluno'] as String? ??
                  'Estudante';
              final instFallback =
                  dados['instituicaoDoAluno'] as String? ??
                  dados['instituicao'] as String? ??
                  'Minha Instituição';
              final logoFallback = dados['logoUrl'] as String?;
              final instId = dados['instituicaoId'] as String?;

              return Consumer(
                builder: (ctx, ref, _) {
                  return FutureBuilder<ResultadoMetaModel>(
                    future: ref.read(simuladoDataSourceProvider).buscarMetaResultado(
                      uid: uid,
                      instituicaoId: instId,
                      taxaAcerto: taxaAcerto,
                      nomeFallback: nomeFallback,
                      instituicaoFallback: instFallback,
                      logoFallback: logoFallback,
                    ),
                    builder: (context, snapshot) {
                      final meta = snapshot.data;
                      return ResultadoSimuladoPage(
                        tituloSimulado:
                            dados['categoria'] ??
                            dados['tipoProva'] ??
                            'Simulado Realizado',
                        acertos: acertos,
                        totalQuestoes: total,
                        erros: total - acertos,
                        notaObtida:
                            (dados['notaObtida'] as num?)?.toDouble() ?? 0.0,
                        notaMaxima:
                            (dados['notaMaxima'] as num?)?.toDouble() ?? 10.0,
                        tempoUtilizadoSegundos:
                            (dados['tempoUtilizadoSegundos'] as num?)?.toInt() ??
                            0,
                        revisaoQuestoes: listaModelos,
                        mensagemFinalizacaoAdmin: meta?.mensagem ?? '',
                        imagemUrlMensagem: meta?.imagemUrlMensagem,
                        pontosGamificacao:
                            (dados['pontosGamificacao'] as num?)?.toInt() ?? 0,
                        nomeDoAluno: meta?.nome ?? nomeFallback,
                        instituicaoDoAluno: meta?.instituicao ?? instFallback,
                        logoUrl: meta?.logoUrl ?? logoFallback,
                        taxaAcerto: taxaAcerto,
                        isPorAssunto: dados['isPorAssunto'] as bool? ?? false,
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página não encontrada!'))),
  );
}
