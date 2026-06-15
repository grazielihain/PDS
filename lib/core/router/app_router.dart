import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ✅ MODELOS (Mantidos 100% Intactos)
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';
import 'package:rumo_quiz/features/simulados/data/models/questao_model.dart';

// ✅ SUAS PÁGINAS REAIS
import 'package:rumo_quiz/features/simulados/presentation/pages/resultado_simulado_page.dart';
import 'package:rumo_quiz/features/admin/presentation/pages/painel_admin_page.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/simulado_page.dart';
import 'package:rumo_quiz/features/auth/presentation/pages/login_page.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/quiz_selection_page.dart';

// 📍 NOVAS PÁGINAS QUE VOCÊ LOCALIZOU
import 'package:rumo_quiz/features/simulados/presentation/pages/historico_page.dart';
import 'package:rumo_quiz/features/auth/presentation/pages/meu_perfil_page.dart';

// 🍔 ORGANISMOS SHARED (Menu Lateral e Rodapé Dinâmico)
import 'package:rumo_quiz/shared/widgets/organisms/menu_lateral_organism.dart';
import 'package:rumo_quiz/shared/widgets/organisms/carrossel_patrocinadores.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // 🚪 1. ROTA DE LOGIN (Fora do menu/rodapé)
      GoRoute(path: '/', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // 🎯 2. ROTA DE EXECUÇÃO DO SIMULADO (Tela cheia para foco total)
      GoRoute(
        path: '/executar-simulado',
        builder: (context, state) => const SimuladoPage(),
      ),

      // 🎯 3. ROTA DO RESULTADO DO SIMULADO (Sua lógica de dados complexa - Intocada)
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

          final listaModelos = (listaCrua as List<dynamic>).map((item) {
            final mapaItem = item as Map<String, dynamic>? ?? {};
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
                    'Questão sem enunciado',
                opcoes: listaOpcoes,
                respostaCorretaIndex: mapaQuestao['respostaCorretaIndex'] ?? 0,
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
              opcaoEscolhidaIndex: mapaItem['opcaoEscolhidaIndex'] ?? 0,
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
                dados['mensagemFinalizacaoAdmin'] ?? 'Parabéns!',
            pontosGamificacao: dados['pontosGamificacao'] ?? 0,
            nomeDoAluno: dados['nomeDoAluno'] ?? 'Estudante',
            instituicaoDoAluno:
                dados['instituicaoDoAluno'] ?? 'Minha Instituição',
            logoUrl: dados['logoUrl'],
            taxaAcerto: (dados['taxaAcerto'] as num?)?.toDouble() ?? 0.0,
          );
        },
      ),

      // 👑 4. NAVEGAÇÃO ESTRUTURADA (Casca Visual com Menu Lateral e Rodapé Patrocinadores)
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            // Cabeçalho unificado do App
            appBar: AppBar(
              title: const Text('Rumo Quiz'),
              backgroundColor: Colors.blue.shade700,
            ),
            // O seu Organismo de Menu Lateral original integrado
            drawer: const MenuLateralOrganism(
              avatarEmoji: '👨‍🎓',
              nomeAluno: 'Estudante Rumo Quiz',
            ),
            // Conteúdo principal reativo que altera baseado na rota atual
            body: child,
            // 🦶 O seu Organismo de Rodapé Dinâmico e Reativo integrado perfeitamente!
            bottomNavigationBar: const SafeArea(
              child: SizedBox(
                height:
                    60, // Ajuste a altura de acordo com o design do seu carrossel
                child: CarrosselPatrocinadores(),
              ),
            ),
          );
        },
        routes: [
          // Rota: Fazer Quiz / Simulados
          GoRoute(
            path: '/quiz-selection',
            builder: (context, state) => const QuizSelectionPage(),
          ),

          // Rota: Histórico de Provas / Meus Resultados (Resolvendo de vez o PageNotFound)
          GoRoute(
            path: '/historico',
            builder: (context, state) => const HistoricoProvasPage(),
          ),

          // Rota: Meu Perfil
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const MeuPerfilPage(),
          ),
        ],
      ),

      // 🎯 ROTA DO PAINEL DO ADMINISTRADOR (White Label)
      GoRoute(
        path: '/admin-painel',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>? ?? {};
          final idDaInstituicao =
              params['instituicaoId']?.toString() ?? 'ulbra-01';
          return PainelAdminPage(substituicaoInstituicaoId: idDaInstituicao);
        },
      ),

      // 🛠️ ROTA DE TESTE DIRETA PARA A BANCA DO TCC
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            const PainelAdminPage(substituicaoInstituicaoId: 'ulbra-01'),
      ),
    ],
  );
}
