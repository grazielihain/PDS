import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/shared/widgets/organisms/carrossel_patrocinadores.dart';
import '../../data/models/questao_model.dart';
import '../../data/models/revisao_questao_model.dart';
import '../controllers/simulado_controller.dart';
import '../providers/quiz_session_provider.dart';

class SimuladoPage extends ConsumerStatefulWidget {
  const SimuladoPage({super.key});

  @override
  ConsumerState<SimuladoPage> createState() => _SimuladoPageState();
}

class _SimuladoPageState extends ConsumerState<SimuladoPage> {
  // ── ESTADO DA SHELL (mesmo cabeçalho/rodapé do sistema) ───────────────────
  bool _dadosCarregados = false;
  String _avatar = '👨‍🎓';
  String _nomeUsuario = 'Usuário';
  String _nomeInstituicao = 'Instituição';
  String? _logoUrl;
  Color _corPrimaria = const Color(0xFF1E3A8A);
  List<String> _patrocinadoresUrls = [];

  // ── ESTADO DO QUIZ ────────────────────────────────────────────────────────
  bool _submissaoEmProgresso = false;
  final ScrollController _carrosselController = ScrollController();
  int _ultimoIndiceCarrossel = -1;
  DateTime? _horarioInicio;

  @override
  void initState() {
    super.initState();
    _horarioInicio = DateTime.now();
    _carregarDadosShell();
  }

  @override
  void dispose() {
    _carrosselController.dispose();
    super.dispose();
  }

  // ── CARREGAMENTO DOS DADOS DA SHELL ───────────────────────────────────────

  Future<void> _carregarDadosShell() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _dadosCarregados = true);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};

      final String avatar = userData['avatarEmoji'] as String? ?? '👨‍🎓';
      final String nome = userData['nome'] as String? ?? 'Usuário';
      final String instId = userData['instituicaoId'] as String? ?? '';

      if (instId.isEmpty) {
        if (mounted) {
          setState(() {
            _avatar = avatar;
            _nomeUsuario = nome;
            _dadosCarregados = true;
          });
        }
        return;
      }

      final instDoc = await FirebaseFirestore.instance
          .collection('instituicoes')
          .doc(instId)
          .get();
      final instData = instDoc.data() ?? {};

      final String nomeInst = instData['nome'] as String? ?? 'Instituição';
      final String logoUrl = instData['logoUrl'] as String? ?? '';
      final String corHex =
          (instData['corHexadecimal'] ?? instData['corHex'] ?? '') as String;
      final List<String> parceiros = List<String>.from(
        instData['patrocinadoresUrls'] ?? instData['patrocinios'] ?? [],
      );

      Color cor = const Color(0xFF1E3A8A);
      if (corHex.isNotEmpty) {
        try {
          final hex = corHex.replaceAll('#', '');
          if (hex.length == 6) cor = Color(int.parse('FF$hex', radix: 16));
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _avatar = avatar;
          _nomeUsuario = nome;
          _nomeInstituicao = nomeInst;
          _logoUrl = logoUrl.isNotEmpty ? logoUrl : null;
          _corPrimaria = cor;
          _patrocinadoresUrls = parceiros;
          _dadosCarregados = true;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar shell do simulado: $e');
      if (mounted) setState(() => _dadosCarregados = true);
    }
  }

  Color get _corTextoAppBar =>
      ThemeData.estimateBrightnessForColor(_corPrimaria) == Brightness.dark
          ? Colors.white
          : Colors.black87;

  // ── SUBMISSÃO ─────────────────────────────────────────────────────────────

  Future<void> _processarEnvioSimulado({
    required QuizSessionState sessionState,
    required dynamic controllerNotifier,
  }) async {
    if (_submissaoEmProgresso) return;
    if (!mounted) return;
    setState(() => _submissaoEmProgresso = true);

    int totalAcertos = 0;
    final List<Map<String, dynamic>> listaRevisaoJson = [];

    try {
      for (final item in sessionState.questoes) {
        final dynamic q = item;
        final String questaoId = q.id ?? '';
        final List<String> opcoes = List<String>.from(q.opcoes ?? []);
        final int respostaCerta = q.respostaCorretaIndex ?? 0;

        final respAluno = sessionState.respostasSelecionadas[questaoId];
        final int indexAluno =
            respAluno != null ? opcoes.indexOf(respAluno) : -1;

        if (indexAluno != -1 && indexAluno == respostaCerta) totalAcertos++;

        listaRevisaoJson.add({
          'opcaoEscolhidaIndex': indexAluno == -1 ? null : indexAluno,
          'questao': {
            'id': questaoId,
            'pergunta': q.pergunta ?? '',
            'opcoes': opcoes,
            'respostaCorretaIndex': respostaCerta,
            'nota': 1.0,
            'categoriaId': q.categoriaId ?? '',
            'assuntoId': q.assuntoId ?? '',
            'justificativa': q.justificativa ?? '',
          },
        });
      }
    } catch (e) {
      debugPrint('Erro no mapeamento das questões: $e');
    }

    final double notaCalculada = sessionState.questoes.isNotEmpty
        ? (totalAcertos / sessionState.questoes.length) * 10.0
        : 0.0;

    final int segundosUsados = _horarioInicio != null
        ? DateTime.now().difference(_horarioInicio!).inSeconds
        : 0;

    int pontosObtidos = 0;
    try {
      pontosObtidos = await controllerNotifier.finalizarEGravarSimulado(
        questoesDaProva:
            sessionState.questoes.map((item) => item as QuestaoModel).toList(),
        respostasAluno: sessionState.respostasSelecionadas,
        notaCalculada: notaCalculada,
        totalAcertos: totalAcertos,
        tempoUtilizadoSegundos: segundosUsados,
        listaRevisao: sessionState.questoes.map((item) {
          final q = item as QuestaoModel;
          final respAluno = sessionState.respostasSelecionadas[q.id];
          final int indexAluno =
              respAluno != null ? q.opcoes.indexOf(respAluno) : -1;
          return RevisaoQuestaoModel(
            questao: q,
            opcaoEscolhidaIndex: indexAluno == -1 ? null : indexAluno,
          );
        }).toList(),
      ) as int;
    } catch (e) {
      debugPrint('Aviso: Erro ao persistir no banco: $e');
    }

    if (mounted) {
      context.go('/resultado', extra: {
        'questoes': sessionState.questoes,
        'acertos': totalAcertos,
        'totalQuestoes': sessionState.questoes.length,
        'notaObtida': notaCalculada,
        'categoria': sessionState.categoriaNome.isNotEmpty
            ? sessionState.categoriaNome
            : sessionState.categoriaId,
        'revisaoQuestoes': listaRevisaoJson,
        'isPorAssunto': sessionState.modoProva == 'assunto',
        'pontosGamificacao': pontosObtidos,
        'tempoUtilizadoSegundos': segundosUsados,
      });
    }
  }

  Future<void> _confirmarFinalizar({
    required QuizSessionState sessionState,
    required dynamic controllerNotifier,
  }) async {
    final int respondidas = sessionState.respostasSelecionadas.length;
    final int total = sessionState.questoes.length;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Prova'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Você respondeu $respondidas de $total questões.'),
            if (respondidas < total) ...[
              const SizedBox(height: 8),
              Text(
                '${total - respondidas} questão(ões) em branco serão contadas como erro.',
                style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Deseja finalizar a prova agora?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _processarEnvioSimulado(
        sessionState: sessionState,
        controllerNotifier: controllerNotifier,
      );
    }
  }

  Future<void> _confirmarSairSemConcluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair sem concluir?'),
        content: const Text(
          'Ao sair, o progresso desta prova será descartado.\n'
          'Nenhum ponto será computado e o simulado não será registrado no histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar prova'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      ref.read(quizSessionProvider.notifier).resetarSimulado();
      context.go('/quiz-selection');
    }
  }

  String _formatarTempo(int s) {
    final m = s ~/ 60;
    final seg = s % 60;
    return '${m.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  // ── CARROSSEL ─────────────────────────────────────────────────────────────

  void _scrollParaQuestao(int indice) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_carrosselController.hasClients) return;
      const double cardWidth = 42.0;
      final double viewport =
          _carrosselController.position.viewportDimension;
      final double maxScroll =
          _carrosselController.position.maxScrollExtent;
      final double target =
          (indice * cardWidth) - (viewport / 2) + (cardWidth / 2);
      _carrosselController.animateTo(
        target.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Aguarda dados da shell antes de renderizar
    if (!_dadosCarregados) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final sessionState = ref.watch(quizSessionProvider);
    final sessionNotifier = ref.read(quizSessionProvider.notifier);
    final controllerState = ref.watch(simuladoControllerProvider);
    final controllerNotifier = ref.read(simuladoControllerProvider.notifier);

    final double larguraTela = MediaQuery.of(context).size.width;
    final bool isWeb = larguraTela > 900;
    final bool isMobile = larguraTela < 600;

    final int tempoRestante = sessionState.tempoRestanteSegundos;
    final bool possuiTempo =
        tempoRestante > 0 || sessionState.tempoEncerrado;
    final bool emAlertaCritico = possuiTempo && tempoRestante <= 300;

    // Auto-submit quando o cronômetro encerra — guarded por flag
    if (!_submissaoEmProgresso && sessionState.tempoEncerrado) {
      Future.microtask(() {
        if (mounted) {
          _processarEnvioSimulado(
            sessionState: sessionState,
            controllerNotifier: controllerNotifier,
          );
        }
      });
    }

    if (_submissaoEmProgresso || controllerState is AsyncLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (sessionState.questoes.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('Nenhuma questão carregada.')));
    }

    final int indiceAtual = sessionState.indiceQuestaoAtual;
    final int totalQuestoes = sessionState.questoes.length;
    final int respondidas = sessionState.respostasSelecionadas.length;

    if (indiceAtual != _ultimoIndiceCarrossel) {
      _ultimoIndiceCarrossel = indiceAtual;
      _scrollParaQuestao(indiceAtual);
    }

    final questaoAtual =
        sessionState.questoes[indiceAtual] as QuestaoModel;
    final respostaSelecionada =
        sessionState.respostasSelecionadas[questaoAtual.id];

    final double progresso =
        totalQuestoes > 0 ? (indiceAtual + 1) / totalQuestoes : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // ── CABEÇALHO: igual ao MainLayoutShell, sem menu lateral ─────────
      appBar: AppBar(
        backgroundColor: _corPrimaria,
        foregroundColor: _corTextoAppBar,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (_logoUrl != null) ...[
              Image.network(
                _logoUrl!,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => Icon(
                  Icons.school_outlined,
                  color: _corTextoAppBar,
                ),
              ),
              const SizedBox(width: 10),
            ] else ...[
              Icon(Icons.school_outlined, color: _corTextoAppBar),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                _nomeInstituicao,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _corTextoAppBar,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Info do usuário (web)
          if (isWeb) ...[
            Text(_avatar, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nomeUsuario,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _corTextoAppBar,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ] else ...[
            // Mobile: só avatar
            Text(_avatar, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],
        ],
      ),

      // ── RODAPÉ: CarrosselPatrocinadores igual ao MainLayoutShell ──────
      bottomNavigationBar: CarrosselPatrocinadores(
        logosUrls: _patrocinadoresUrls,
        logoInstituicaoUrl: _logoUrl ?? '',
        corCustomizadaInstituicao: _corPrimaria,
      ),

      body: Column(
        children: [
          // Barra de progresso
          LinearProgressIndicator(
            value: progresso,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
                _corPrimaria.withValues(alpha: 0.6)),
            minHeight: 4,
          ),

          // Alerta 5 min: faixa vermelha largura total
          if (possuiTempo && emAlertaCritico && tempoRestante > 0)
            Container(
              width: double.infinity,
              color: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Atenção! Menos de 5 minutos restantes!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Conteúdo da questão
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Número da questão + respondidas + cronômetro centralizado
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _corPrimaria.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'QUESTÃO ${indiceAtual + 1} DE $totalQuestoes',
                                style: TextStyle(
                                  color: _corPrimaria,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '$respondidas respondidas',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                        if (possuiTempo && tempoRestante > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: emAlertaCritico ? Colors.red : _corPrimaria,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: emAlertaCritico
                                  ? Colors.red.withValues(alpha: 0.06)
                                  : _corPrimaria.withValues(alpha: 0.06),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 14, color: emAlertaCritico ? Colors.red : _corPrimaria),
                                const SizedBox(width: 4),
                                Text(
                                  _formatarTempo(tempoRestante),
                                  style: TextStyle(
                                    color: emAlertaCritico ? Colors.red : _corPrimaria,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Enunciado
                    Text(
                      questaoAtual.pergunta,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Alternativas
                    Expanded(
                      child: ListView.builder(
                        itemCount: questaoAtual.opcoes.length,
                        itemBuilder: (context, index) {
                          final opcaoTexto = questaoAtual.opcoes[index];
                          final selecionada =
                              respostaSelecionada == opcaoTexto;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: selecionada
                                  ? _corPrimaria.withValues(alpha: 0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selecionada
                                    ? _corPrimaria
                                    : Colors.grey.shade300,
                                width: selecionada ? 2.0 : 1.0,
                              ),
                              boxShadow: selecionada
                                  ? [
                                      BoxShadow(
                                        color: _corPrimaria.withValues(
                                            alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: selecionada
                                    ? _corPrimaria
                                    : Colors.grey.shade100,
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: selecionada
                                        ? Colors.white
                                        : const Color(0xFF4B5563),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              title: Text(
                                opcaoTexto,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  color: const Color(0xFF374151),
                                  fontWeight: selecionada
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: selecionada
                                  ? Icon(Icons.check_circle,
                                      color: _corPrimaria)
                                  : null,
                              onTap: () =>
                                  sessionNotifier.selecionarAlternativa(
                                      questaoAtual.id, opcaoTexto),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),

          // ── CARROSSEL + BOTÃO FINALIZAR ───────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── CARROSSEL DE QUESTÕES ──────────────────────────
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.chevron_left, size: 26),
                          color: indiceAtual > 0
                              ? _corPrimaria
                              : Colors.grey.shade300,
                          onPressed: indiceAtual > 0
                              ? sessionNotifier.questaoAnterior
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 44),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ListView.builder(
                              controller: _carrosselController,
                              scrollDirection: Axis.horizontal,
                              itemCount: totalQuestoes,
                              itemBuilder: (ctx, i) {
                                final qi = sessionState.questoes[i]
                                    as QuestaoModel;
                                final respondida = sessionState
                                    .respostasSelecionadas
                                    .containsKey(qi.id);
                                final isAtual = i == indiceAtual;

                                return GestureDetector(
                                  onTap: () => sessionNotifier
                                      .irParaQuestao(i),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isAtual
                                          ? _corPrimaria
                                          : respondida
                                              ? const Color(0xFF10B981)
                                              : Colors.grey.shade100,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isAtual
                                            ? _corPrimaria
                                            : respondida
                                                ? const Color(0xFF10B981)
                                                : Colors.grey.shade300,
                                        width: isAtual ? 2 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: isAtual || respondida
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.chevron_right, size: 26),
                          color: indiceAtual < totalQuestoes - 1
                              ? _corPrimaria
                              : Colors.grey.shade300,
                          onPressed: indiceAtual < totalQuestoes - 1
                              ? sessionNotifier.proximaQuestao
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 44),
                        ),
                      ],
                    ),

                    // Legenda
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 4, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendaItem(
                              color: _corPrimaria, label: 'Atual'),
                          const SizedBox(width: 16),
                          const _LegendaItem(
                              color: Color(0xFF10B981),
                              label: 'Respondida'),
                          const SizedBox(width: 16),
                          _LegendaItem(
                              color: Colors.grey.shade300,
                              label: 'Não respondida'),
                        ],
                      ),
                    ),

                    // ── BOTÕES FINALIZAR / SAIR SEM CONCLUIR ──────────
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.exit_to_app, size: 18),
                              label: Text(
                                isMobile ? 'Sair' : 'Sair sem concluir',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              onPressed: _confirmarSairSemConcluir,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.white, size: 18),
                              label: Text(
                                isMobile
                                    ? 'Finalizar ($respondidas/$totalQuestoes)'
                                    : 'Finalizar Prova — $respondidas de $totalQuestoes respondidas',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _confirmarFinalizar(
                                sessionState: sessionState,
                                controllerNotifier: controllerNotifier,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}
