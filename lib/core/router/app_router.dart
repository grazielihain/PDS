import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/features/prova/domain/models/questao_model.dart';
import 'package:rumo_quiz/features/prova/domain/models/revisao_questao_model.dart';
import 'package:rumo_quiz/features/prova/presentation/pages/resultado_prova_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/prova/presentation/pages/quiz_selection_page.dart';
import '../../features/auth/presentation/pages/meu_perfil_page.dart';
import '../../features/prova/presentation/pages/historico_page.dart'; // 🟢 Importado
import '../presentation/pages/main_layout_shell.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // 🚪 Fora do cabeçalho fixo (Tela Cheia)
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
          // Aba: Fazer Quiz / Simulados
          GoRoute(
            path: '/quiz-selection',
            builder: (context, state) => const QuizSelectionPage(),
          ),
          // Aba: Meu Perfil
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const MeuPerfilPage(),
          ),
          // Aba: Meus Resultados / Histórico (🟢 INCLUÍDO NO SISTEMA FIXO)
          GoRoute(
            path: '/historico',
            builder: (context, state) => const HistoricoProvasPage(),
          ),
        ],
      ),

      // 📝 Tela de execução ou resultados críticos (se optar por rodar por fora)
      GoRoute(
        path: '/resultado',
        builder: (context, state) {
          // 1. Coleta o mapa genérico do Firestore passado pelo botão "Ver Detalhes"
          final dados = state.extra as Map<String, dynamic>? ?? {};

          // 2. Extrai e converte a lista de revisão para o formato correto (Duplicidade Removida!)
          final listaCrua =
              dados['revisaoQuestoes'] ??
              dados['questoes'] ??
              dados['listaQuestoes'] ??
              [];
          final listaModelos = (listaCrua as List<dynamic>).map((q) {
            final mapaQuestao = q as Map<String, dynamic>? ?? {};

            // Captura as opções/alternativas com segurança
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
              // Aceita tanto a nomenclatura da revisão direta quanto a salva no histórico
              opcaoEscolhidaIndex:
                  mapaQuestao['opcaoEscolhidaIndex'] ??
                  mapaQuestao['alternativaRespondidaIndex'] ??
                  mapaQuestao['opcaoSelecionadaIndex'] ??
                  mapaQuestao['respostaAlunoIndex'],
            );
          }).toList();

          // 3. Injeta todos os parâmetros necessários no construtor da sua página
          return ResultadoProvaPage(
            tituloProva:
                dados['categoria'] ??
                dados['tipoProva'] ??
                'Simulado Realizado',
            acertos: dados['acertos'] ?? 0,
            totalQuestoes: dados['totalQuestoes'] ?? 0,

            // 🟢 1. Adicionado o parâmetro 'erros' calculando a diferença
            erros: (dados['totalQuestoes'] ?? 0) - (dados['acertos'] ?? 0),

            notaObtida: (dados['NotaObtida'] as num?)?.toDouble() ?? 0.0,
            notaMaxima: (dados['notaMaxima'] as num?)?.toDouble() ?? 10.0,
            tempoUtilizadoSegundos: dados['tempoUtilizadoSegundos'] ?? 0,
            revisaoQuestoes: listaModelos,
            mensagemFinalizacaoAdmin:
                dados['mensagemFinalizacaoAdmin'] ?? 'Parabéns pela conclusão!',
            pontosGamificacao: dados['pontosGamificacao'] ?? 0,

            // 🟢 2. CORREÇÃO DO ERRO: Buscando os dados do aluno e instituição do mapa 'dados'
            // (Caso não existam no mapa, ele usa os valores padrões textuais)
            nomeDoAluno:
                dados['nomeDoAluno'] ?? dados['nomeAluno'] ?? 'Estudante',
            instituicaoDoAluno:
                dados['instituicaoDoAluno'] ??
                dados['instituicao'] ??
                'Minha Instituição',
            logoUrl: dados['logoUrl'], // Aceita nulo caso não exista no mapa
            // 🟢 3. Adicionado o cálculo da taxa de acerto caso não venha pronta do banco/mapa
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
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página não encontrada!'))),
  );
}
