import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Import adicionado para buscar o nome real no banco
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 🔄 Imports blindados apontando para a pasta unificada de simulados
import 'package:rumo_quiz/features/simulados/data/models/questao_model.dart';
import 'package:rumo_quiz/features/simulados/data/models/revisao_questao_model.dart';
import 'package:rumo_quiz/features/simulados/presentation/pages/resultado_simulado_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/simulados/presentation/pages/quiz_selection_page.dart';
import '../../features/auth/presentation/pages/meu_perfil_page.dart';
import '../../features/simulados/presentation/pages/historico_simulado_page.dart';
import '../presentation/pages/main_layout_shell.dart';
import '../../features/simulados/presentation/pages/simulado_page.dart';

// 👑 NOVOS IMPORTS DO PAINEL ADMINISTRATIVO (Adicionados para a Sprint)
import 'package:rumo_quiz/features/admin/presentation/pages/painel_admin_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // 🚪 1. ROTA DE LOGIN
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // 👑 2. ROTAS ADMINISTRATIVAS (White Label - Admin e Acess2)
      GoRoute(
        path: '/admin-painel',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>? ?? {};
          final idDaInstituicao =
              params['instituicaoId']?.toString() ?? 'ulbra-01';
          return PainelAdminPage(substituicaoInstituicaoId: idDaInstituicao);
        },
      ),

      // Rota de atalho para testes rápidos do Admin
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            const PainelAdminPage(substituicaoInstituicaoId: 'ulbra-01'),
      ),

      // 👑 3. ENVELOPE GLOBAL DO SISTEMA (Seu MainLayoutShell Original Reativado!)
      ShellRoute(
        builder: (context, state, child) {
          return MainLayoutShell(child: child);
        },
        routes: [
          // Tela: Seleção de Quiz
          GoRoute(
            path: '/quiz-selection',
            builder: (context, state) => const QuizSelectionPage(),
          ),

          // Tela: Meu Perfil
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const MeuPerfilPage(),
          ),

          // Tela: Histórico de Provas (Ajustado o construtor para HistoricoPage)
          GoRoute(
            path: '/historico',
            builder: (context, state) => const HistoricoSimuladoPage(),
          ),

          // 🎯 Página de resultados (Herda o cabeçalho, menu e rodapé do seu MainLayoutShell)
          GoRoute(
            path: '/resultado',
            builder: (context, state) {
              final dados = state.extra as Map<String, dynamic>? ?? {};

              // 1. CAPTURA A LISTA CORRETA: Mapeado com o nome salvo no Firebase ('listaRevisaoJson')
              final listaCrua =
                  dados['listaRevisaoJson'] ??
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
                  ),
                  // 2. CAPTURA O ÍNDICE CORRETO: Fica no nó pai do item do laço
                  opcaoEscolhidaIndex:
                      mapaItem['opcaoEscolhidaIndex'] ??
                      mapaQuestao['opcaoEscolhidaIndex'] ??
                      mapaQuestao['alternativaRespondidaIndex'] ??
                      mapaQuestao['opcaoSelecionadaIndex'] ??
                      mapaQuestao['respostaAlunoIndex'] ??
                      0,
                );
              }).toList();

              // ⚡ Captura o UID do usuário logado no momento da visualização
              final uid = FirebaseAuth.instance.currentUser?.uid;

              // Fallback de segurança caso não exista um usuário ativo no Firebase Auth
              if (uid == null) {
                return ResultadoSimuladoPage(
                  tituloSimulado:
                      dados['categoria'] ??
                      dados['tipoProva'] ??
                      'Simulado Realizado',
                  acertos: dados['acertos'] ?? 0,
                  totalQuestoes: dados['totalQuestoes'] ?? 0,
                  erros:
                      (dados['totalQuestoes'] ?? 0) - (dados['acertos'] ?? 0),
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
              }

              // 🔄 Busca em tempo real na coleção 'usuarios' para garantir o nome atualizado
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(uid)
                    .get(),
                builder: (context, snapshot) {
                  String nomeRealDoBanco = 'Estudante';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final dadosUsuario =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    nomeRealDoBanco = dadosUsuario?['nome'] ?? 'Estudante';
                  }

                  return ResultadoSimuladoPage(
                    tituloSimulado:
                        dados['categoria'] ??
                        dados['tipoProva'] ??
                        'Simulado Realizado',
                    acertos: dados['acertos'] ?? 0,
                    totalQuestoes: dados['totalQuestoes'] ?? 0,
                    erros:
                        (dados['totalQuestoes'] ?? 0) - (dados['acertos'] ?? 0),
                    notaObtida:
                        (dados['notaObtida'] as num?)?.toDouble() ?? 0.0,
                    notaMaxima:
                        (dados['notaMaxima'] as num?)?.toDouble() ?? 10.0,
                    tempoUtilizadoSegundos:
                        dados['tempoUtilizadoSegundos'] ?? 0,
                    revisaoQuestoes: listaModelos,
                    mensagemFinalizacaoAdmin:
                        dados['mensagemFinalizacaoAdmin'] ??
                        'Parabéns pela conclusão!',
                    pontosGamificacao: dados['pontosGamificacao'] ?? 0,

                    // 🔥 Injeta o nome real e atualizado vindo da sua única fonte de verdade (Firestore)
                    nomeDoAluno: nomeRealDoBanco,

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
              );
            },
          ),
        ],
      ),

      // 🎯 4. EXECUÇÃO DO SIMULADO (Isolada fora do shell para tela cheia de foco)
      GoRoute(
        path: '/executar-simulado',
        builder: (context, state) => const SimuladoPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página não encontrada!'))),
  );
}
