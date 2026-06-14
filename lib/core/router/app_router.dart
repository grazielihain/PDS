import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// 🔄 Imports blindados apontando para a pasta unificada de simulados
import 'package:rumo_quiz/features/simulados/data/models/questao_model.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/resultado_simulado_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/simulados/presentation/pages/quiz_selection_page.dart';
import '../../features/auth/presentation/pages/meu_perfil_page.dart';
import '../../features/simulados/presentation/pages/historico_page.dart';
import '../presentation/pages/main_layout_shell.dart';
import '../../features/simulados/presentation/pages/simulado_page.dart';

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

      // 👑 ENVELOPE GLOBAL DO SISTEMA (MainLayoutShell)
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

          // 🎯 MOVIDO PARA CÁ: Agora a página de resultados herda automaticamente
          // o cabeçalho oficial, menu sanduíche e rodapé padrão do MainLayoutShell!
          GoRoute(
            path: '/resultado',
            builder: (context, state) {
              final dados = state.extra as Map<String, dynamic>? ?? {};

              // 1. CAPTURA A LISTA CORRETA: Mapeado com o nome salvo no Firebase ('listaRevisaoJson')
              final listaCrua =
                  dados['listaRevisaoJson'] ?? // 👈 Adicionado o nome real que vem do banco
                  dados['revisaoQuestoes'] ??
                  dados['questoes'] ??
                  dados['listaQuestoes'] ??
                  [];

              final listaModelos = (listaCrua as List<dynamic>).map((item) {
                final mapaItem = item as Map<String, dynamic>? ?? {};

                // No JSON salvo, os dados do enunciado e opções ficam agrupados dentro de 'questao'
                final mapaQuestao =
                    mapaItem['questao'] as Map<String, dynamic>? ?? {};

                final opcoesCruas =
                    mapaQuestao['opcoes'] ?? mapaQuestao['alternativas'] ?? [];
                final listaOpcoes = (opcoesCruas as List<dynamic>)
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
                        mapaQuestao['respostaCorretaIndex'] ?? // 👈 Bate com a estrutura do Envio
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
                  ),
                  // 2. CAPTURA O ÍNDICE CORRETO: Fica no nó pai do item do laço
                  opcaoEscolhidaIndex:
                      mapaItem['opcaoEscolhidaIndex'] ??
                      mapaQuestao['opcaoEscolhidaIndex'] ??
                      mapaQuestao['alternativaRespondidaIndex'] ??
                      mapaQuestao['opcaoSelecionadaIndex'] ??
                      mapaQuestao['respostaAlunoIndex'],
                );
              }).toList();

              return ResultadoSimuladoPage(
                tituloSimulado:
                    dados['categoria'] ??
                    dados['tipoProva'] ??
                    'Simulado Realizado',
                acertos: dados['acertos'] ?? 0,
                totalQuestoes: dados['totalQuestoes'] ?? 0,
                erros: (dados['totalQuestoes'] ?? 0) - (dados['acertos'] ?? 0),
                notaObtida: (dados['notaObtida'] as num?)?.toDouble() ?? 0.0,
                notaMaxima: (dados['notaMaxima'] as num?)?.toDouble() ?? 10.0,
                tempoUtilizadoSegundos: dados['tempoUtilizadoSegundos'] ?? 0,
                revisaoQuestoes: listaModelos,
                mensagemFinalizacaoAdmin:
                    dados['mensagemFinalizacaoAdmin'] ??
                    'Parabéns pela conclusão!',
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
                          ? (((dados['acertos'] ?? 0) /
                                        dados['totalQuestoes']) *
                                    100)
                                .toDouble()
                          : 0.0),
              );
            },
          ),
        ],
      ),

      // Mantida isolada fora do shell (apenas se for o padrão desejado de tela cheia para fazer a prova)
      GoRoute(
        path: '/executar-simulado',
        builder: (context, state) => const SimuladoPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página não encontrada!'))),
  );
}
