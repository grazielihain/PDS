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
import '../../features/simulados/presentation/pages/fazer_quiz_page.dart';
import '../../features/simulados/presentation/pages/meus_resultados_page.dart';
import '../../features/auth/presentation/pages/meu_perfil_page.dart';
import '../../features/simulados/presentation/pages/historico_simulado_page.dart';
import '../presentation/pages/main_layout_shell.dart';
import '../../features/simulados/presentation/pages/simulado_page.dart';

// 👑 IMPORTS DO PAINEL ADMINISTRATIVO
import 'package:rumo_quiz/features/admin/presentation/pages/painel_admin_page.dart';
import 'package:rumo_quiz/features/admin/presentation/pages/painel_master_page.dart';

/// Busca nome do aluno, mensagem de resultado e dados da instituição em paralelo.
/// Retorna (nome, mensagem, nomeInstituicao, logoUrl).
Future<(String, String, String, String?)> _fetchResultadoMeta(
  String? uid,
  Map<String, dynamic> dados,
  double taxaAcerto,
) async {
  String nome = dados['nomeDoAluno'] as String? ?? dados['nomeAluno'] as String? ?? 'Estudante';
  String mensagem = '';
  String instituicao = dados['instituicaoDoAluno'] as String? ?? dados['instituicao'] as String? ?? 'Minha Instituição';
  String? logoUrl = dados['logoUrl'] as String?;

  if (uid == null) return (nome, mensagem, instituicao, logoUrl);

  try {
    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final userData = userDoc.data() ?? {};
    nome = userData['nome'] as String? ?? nome;

    final instId = (dados['instituicaoId'] as String?)?.isNotEmpty == true
        ? dados['instituicaoId'] as String
        : userData['instituicaoId'] as String? ?? '';

    if (instId.isNotEmpty) {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('mensagens_resultado')
            .where('instituicaoId', isEqualTo: instId)
            .get(),
        FirebaseFirestore.instance.collection('instituicoes').doc(instId).get(),
      ]);

      final msgSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      for (final doc in msgSnap.docs) {
        final md = doc.data();
        final de = (md['de'] as num? ?? 0).toDouble();
        final ate = (md['ate'] as num? ?? 100).toDouble();
        if (taxaAcerto >= de && taxaAcerto < ate) {
          mensagem = md['texto'] as String? ?? '';
          break;
        }
      }

      final instDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      if (instDoc.exists) {
        final instData = instDoc.data() ?? {};
        if (instituicao == 'Minha Instituição') {
          instituicao = instData['nome'] as String? ?? instituicao;
        }
        logoUrl ??= instData['logoUrl'] as String?;
      }
    }
  } catch (e) {
    debugPrint('Aviso: erro ao buscar meta do resultado: $e');
  }

  return (nome, mensagem, instituicao, logoUrl);
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // 🚪 1. ROTA DE LOGIN (fora do shell — sem cabeçalho/rodapé)
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // 🎯 2. EXECUÇÃO DO SIMULADO (fullscreen — fora do shell por design)
      GoRoute(
        path: '/executar-simulado',
        builder: (context, state) => const SimuladoPage(),
      ),

      // 🏠 3. SHELL GLOBAL — envolve todas as páginas autenticadas
      //    Provê: cabeçalho (AppBar), menu lateral e rodapé (carrossel)
      //    para TODOS os níveis de acesso (Master, Admin, Acess2, Acess3)
      ShellRoute(
        builder: (context, state, child) {
          return MainLayoutShell(child: child);
        },
        routes: [
          // ── PAINEL MASTER ──────────────────────────────────────────────
          GoRoute(
            path: '/master-painel',
            builder: (context, state) => const PainelMasterPage(),
          ),

          // ── PAINEL ADMIN / ACESS2 ─────────────────────────────────────
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
            builder: (context, state) {
              final params = state.extra as Map<String, dynamic>? ?? {};
              final idDaInstituicao =
                  params['instituicaoId']?.toString() ?? 'ulbra-01';
              return PainelAdminPage(substituicaoInstituicaoId: idDaInstituicao);
            },
          ),

          // ── PÁGINAS DO ALUNO (Acess3) ──────────────────────────────────
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

          // ── RESULTADO DO SIMULADO (dentro do shell para ter cabeçalho) ─
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

              return FutureBuilder<(String, String, String, String?)>(
                future: _fetchResultadoMeta(uid, dados, taxaAcerto),
                builder: (context, snapshot) {
                  final meta = snapshot.data;
                  final nomeAluno = meta?.$1 ?? dados['nomeDoAluno'] ?? dados['nomeAluno'] ?? 'Estudante';
                  final mensagem = meta?.$2 ?? '';
                  final instituicao = meta?.$3 ?? dados['instituicaoDoAluno'] ?? dados['instituicao'] ?? 'Minha Instituição';
                  final logoUrl = meta?.$4 ?? dados['logoUrl'] as String?;

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
                        dados['tempoUtilizadoSegundos'] ?? 0,
                    revisaoQuestoes: listaModelos,
                    mensagemFinalizacaoAdmin: mensagem,
                    pontosGamificacao: dados['pontosGamificacao'] ?? 0,
                    nomeDoAluno: nomeAluno,
                    instituicaoDoAluno: instituicao,
                    logoUrl: logoUrl,
                    taxaAcerto: taxaAcerto,
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
