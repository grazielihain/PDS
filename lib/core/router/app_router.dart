import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/features/prova/domain/models/questao_model.dart';
import 'package:rumo_quiz/features/prova/domain/models/revisao_questao_model.dart';
import 'package:rumo_quiz/features/prova/presentation/pages/resultado_prova_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/prova/presentation/pages/quiz_selection_page.dart';
import '../../features/auth/presentation/pages/meu_perfil_page.dart';
import '../../features/prova/presentation/pages/historico_page.dart';
import '../presentation/pages/main_layout_shell.dart';
import '../../features/simulados/presentation/pages/simulado_page.dart';
import 'package:rumo_quiz/shared/widgets/organisms/carrossel_patrocinadores.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      GoRoute(
        path: '/admin',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Painel Administrativo (Admin)')),
        ),
      ),

      // 🗺️ AS ROTAS QUE COMPARTILHAM O CABEÇALHO FIXO E MENU LATERAL
      ShellRoute(
        builder: (context, state, child) {
          return MainLayoutShell(child: child);
        },
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
            builder: (context, state) => const HistoricoProvasPage(),
          ),
        ],
      ),

      GoRoute(
        path: '/resultado',
        builder: (context, state) {
          final dados = state.extra as Map<String, dynamic>? ?? {};

          final listaCrua =
              dados['revisaoQuestoes'] ??
              dados['questoes'] ??
              dados['listaQuestoes'] ??
              [];
          final listaModelos = (listaCrua as List<dynamic>).map((q) {
            final mapaQuestao = q as Map<String, dynamic>? ?? {};

            final opcoesCruas =
                mapaQuestao['opcoes'] ?? mapaQuestao['alternativas'] ?? [];
            final listaOpcoes = (opcoesCruas as List<dynamic>)
                .map((o) => o.toString())
                .toList();

            return RevisaoQuestaoModel(
              questao: QuestaoModel(
                id: mapaQuestao['id']?.toString() ?? '',
                pergunta:
                    mapaQuestao['enunciado'] ??
                    mapaQuestao['pergunta'] ??
                    mapaQuestao['texto'] ??
                    'Questão sem enunciado',
                opcoes: listaOpcoes,
                respostaCorretaIndex:
                    mapaQuestao['opcaoCorretaIndex'] ??
                    mapaQuestao['alternativaCorretaIndex'] ??
                    mapaQuestao['respostaCorretaIndex'] ??
                    0,
                nota: (mapaQuestao['nota'] as num?)?.toDouble() ?? 1.0,
              ),
              opcaoEscolhidaIndex:
                  mapaQuestao['opcaoEscolhidaIndex'] ??
                  mapaQuestao['alternativaRespondidaIndex'] ??
                  mapaQuestao['opcaoSelecionadaIndex'] ??
                  mapaQuestao['respostaAlunoIndex'],
            );
          }).toList();

          return ResultadoProvaPage(
            tituloProva:
                dados['categoria'] ??
                dados['tipoProva'] ??
                'Simulado Realizado',
            acertos: dados['acertos'] ?? 0,
            totalQuestoes: dados['totalQuestoes'] ?? 0,
            erros: (dados['totalQuestoes'] ?? 0) - (dados['acertos'] ?? 0),
            notaObtida: (dados['NotaObtida'] as num?)?.toDouble() ?? 0.0,
            notaMaxima: (dados['notaMaxima'] as num?)?.toDouble() ?? 10.0,
            tempoUtilizadoSegundos: dados['tempoUtilizadoSegundos'] ?? 0,
            revisaoQuestoes: listaModelos,
            mensagemFinalizacaoAdmin:
                dados['mensagemFinalizacaoAdmin'] ?? 'Parabéns pela conclusão!',
            pontosGamificacao: dados['pontosGamificacao'] ?? 0,
            nomeDoAluno:
                dados['nomeDoAluno'] ?? dados['nomeAluno'] ?? 'Estudante',
            instituicaoDoAluno:
                dados['instituicaoDoAluno'] ??
                dados['instituicao'] ??
                'Minha Instituição',
            logoUrl: dados['logoUrl'], 
            taxaAcerto: dados['taxaAcerto'] != null
                ? (dados['taxaAcerto'] as num).toDouble()
                : ((dados['totalQuestoes'] ?? 0) > 0
                    ? (((dados['acertos'] ?? 0) / dados['totalQuestoes']) *
                                100)
                            .toDouble()
                    : 0.0),
          );
        },
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
