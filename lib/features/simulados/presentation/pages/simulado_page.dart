import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/questao_model.dart';
import '../../data/models/revisao_questao_model.dart';
import '../controllers/simulado_controller.dart';
import '../providers/quiz_session_provider.dart';

class SimuladoPage extends ConsumerWidget {
  const SimuladoPage({Key? key}) : super(key: key);

  Future<void> _processarEnvioSimulado({
    required BuildContext context,
    required QuizSessionState sessionState,
    required QuizSessionNotifier sessionNotifier,
    required dynamic controllerNotifier,
  }) async {
    debugPrint('======= PROCESSANDO ENVIO DO SIMULADO =======');

    int totalAcertos = 0;
    List<Map<String, dynamic>> listaRevisaoJson = [];

    try {
      for (var item in sessionState.questoes) {
        final dynamic q = item;
        final String questaoId = q.id ?? '';
        final List<String> opcoes = List<String>.from(q.opcoes ?? []);
        final int respostaCerta = q.respostaCorretaIndex ?? 0;

        final respAluno = sessionState.respostasSelecionadas[questaoId];
        final int indexAluno = respAluno != null
            ? opcoes.indexOf(respAluno)
            : -1;

        if (indexAluno != -1 && indexAluno == respostaCerta) {
          totalAcertos++;
        }

        listaRevisaoJson.add({
          'opcaoEscolhidaIndex': indexAluno == -1 ? null : indexAluno,
          'questao': {
            'id': questaoId,
            'pergunta': q.pergunta ?? '',
            'opcoes': opcoes,
            'respostaCorretaIndex': respostaCerta,
            'nota': 1.0,
          },
        });
      }
    } catch (e) {
      debugPrint('Erro no mapeamento local das questões: $e');
    }

    double notaCalculada = sessionState.questoes.isNotEmpty
        ? (totalAcertos / sessionState.questoes.length) * 10.0
        : 0.0;

    try {
      await controllerNotifier.finalizarEGravarSimulado(
        questoesDaProva: sessionState.questoes
            .map((item) => item as QuestaoModel)
            .toList(),
        respostasAluno: sessionState.respostasSelecionadas,
        notaCalculada: notaCalculada,
        totalAcertos: totalAcertos,
        listaRevisao: sessionState.questoes.map((item) {
          final q = item as QuestaoModel;
          final respAluno = sessionState.respostasSelecionadas[q.id];
          final int indexAluno = respAluno != null
              ? q.opcoes.indexOf(respAluno)
              : -1;

          return RevisaoQuestaoModel(
            questao: q,
            opcaoEscolhidaIndex: indexAluno == -1 ? null : indexAluno,
          );
        }).toList(),
      );
    } catch (erroFirebase) {
      debugPrint('Aviso: Erro ao persistir no banco: $erroFirebase');
    }

    if (context.mounted) {
      final bool provaPorAssunto = sessionState.modoProva == 'assunto';

      context.go(
        '/resultado',
        extra: {
          'questoes': sessionState.questoes,
          'acertos': totalAcertos,
          'totalQuestoes': sessionState.questoes.length,
          'notaObtida': notaCalculada,
          'categoria': sessionState.categoriaId,
          'revisaoQuestoes': listaRevisaoJson,
          'isPorAssunto': provaPorAssunto,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuizSessionState sessionState = ref.watch(quizSessionProvider);
    final QuizSessionNotifier sessionNotifier = ref.read(
      quizSessionProvider.notifier,
    );

    final controllerState = ref.watch(simuladoControllerProvider);
    final controllerNotifier = ref.read(simuladoControllerProvider.notifier);

    final double larguraTela = MediaQuery.of(context).size.width;
    final bool isMobile = larguraTela < 600;
    final int tempoRestante = sessionState.tempoRestanteSegundos;
    final bool possuiTempo = tempoRestante > 0 || sessionState.tempoEncerrado;

    if (possuiTempo && (tempoRestante <= 0 || sessionState.tempoEncerrado)) {
      Future.microtask(() {
        if (context.mounted) {
          _processarEnvioSimulado(
            context: context,
            sessionState: sessionState,
            sessionNotifier: sessionNotifier,
            controllerNotifier: controllerNotifier,
          );
        }
      });
    }

    if (controllerState is AsyncLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (sessionState.questoes.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Nenhuma questão carregada.')),
      );
    }

    final questaoAtual =
        sessionState.questoes[sessionState.indiceQuestaoAtual] as QuestaoModel;
    final respostaSelecionadaTexto =
        sessionState.respostasSelecionadas[questaoAtual.id];

    final bool emAlertaCritico = tempoRestante <= 300;
    final Color corDoCronometro = emAlertaCritico
        ? Colors.red.shade700
        : const Color(0xFF1E3A8A);

    String formatarTempo(int totalSegundos) {
      final int minutos = totalSegundos ~/ 60;
      final int segundos = totalSegundos % 60;
      return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    }

    final int questoesRespondidas = sessionState.respostasSelecionadas.length;
    final double percentualProgresso = sessionState.questoes.isNotEmpty
        ? (sessionState.indiceQuestaoAtual + 1) / sessionState.questoes.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.school, color: Color(0xFF1E3A8A), size: 28),
            const SizedBox(width: 8),
            Text(
              'Rumo Quiz',
              style: TextStyle(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 18 : 22,
              ),
            ),
          ],
        ),
        actions: [
          if (possuiTempo && tempoRestante > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: emAlertaCritico
                        ? Colors.red.shade50
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: corDoCronometro, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        emAlertaCritico
                            ? Icons.timer_sharp
                            : Icons.timer_outlined,
                        color: corDoCronometro,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatarTempo(tempoRestante),
                        style: TextStyle(
                          color: corDoCronometro,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: percentualProgresso,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            minHeight: 4,
          ),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (possuiTempo && emAlertaCritico && tempoRestante > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Atenção! Restam menos de 5 minutos para o fim da sua prova.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'QUESTÃO ${sessionState.indiceQuestaoAtual + 1} DE ${sessionState.questoes.length}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '$questoesRespondidas respondidas',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      questaoAtual.pergunta,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: questaoAtual.opcoes.length,
                        itemBuilder: (context, index) {
                          final opcaoTexto = questaoAtual.opcoes[index];
                          final estaSelecionado =
                              respostaSelecionadaTexto == opcaoTexto;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            decoration: BoxDecoration(
                              color: estaSelecionado
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: estaSelecionado
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade300,
                                width: estaSelecionado ? 2.0 : 1.0,
                              ),
                              boxShadow: estaSelecionado
                                  ? [
                                      BoxShadow(
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: estaSelecionado
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade100,
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: estaSelecionado
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
                                  fontWeight: estaSelecionado
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: estaSelecionado
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF2563EB),
                                    )
                                  : null,
                              onTap: () =>
                                  sessionNotifier.selecionarAlternativa(
                                    questaoAtual.id,
                                    opcaoTexto,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🏛️ RODAPÉ INTEGRADO (Botões de Navegação + Patrocinadores)
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Linha de Botões Anterior / Próxima
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: isMobile ? 110 : 140,
                            height: 44,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.arrow_back_ios, size: 14),
                              label: const Text('Anterior'),
                              onPressed: sessionState.indiceQuestaoAtual > 0
                                  ? sessionNotifier.questaoAnterior
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          if (sessionState.indiceQuestaoAtual ==
                              sessionState.questoes.length - 1)
                            SizedBox(
                              width: isMobile ? 160 : 200,
                              height: 44,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Finalizar Simulado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => _processarEnvioSimulado(
                                  context: context,
                                  sessionState: sessionState,
                                  sessionNotifier: sessionNotifier,
                                  controllerNotifier: controllerNotifier,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: isMobile ? 110 : 140,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: sessionNotifier.proximaQuestao,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Próxima',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 8),

                      // 🛡️ SUB-RODAPÉ DE PATROCINADORES / REALIZAÇÃO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Realização e Apoio:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.gavel,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'TRT-4',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.account_balance,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Rumo Cultural',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
