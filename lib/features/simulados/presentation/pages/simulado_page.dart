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

  // ⚡ GATILHO UNIFICADO DE ENVIO AUTOMÁTICO OU MANUAL (Evita duplicação de lógica)
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

    debugPrint('Acertos calculados: $totalAcertos | Nota: $notaCalculada');

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
      debugPrint('Gravação no Firebase concluída com sucesso!');
    } catch (erroFirebase) {
      debugPrint(
        'Aviso: Erro ao persistir no banco (mas avançando): $erroFirebase',
      );
    }

    if (context.mounted) {
      debugPrint('Redirecionando para /resultado...');
      context.go(
        '/resultado',
        extra: {
          'questoes': sessionState.questoes,
          'acertos': totalAcertos,
          'totalQuestoes': sessionState.questoes.length,
          'NotaObtida': notaCalculada,
          'categoria': sessionState.categoriaId,
          'revisaoQuestoes': listaRevisaoJson,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧠 Tipagem estrita com as classes reais que você enviou
    final QuizSessionState sessionState = ref.watch(quizSessionProvider);
    final QuizSessionNotifier sessionNotifier = ref.read(
      quizSessionProvider.notifier,
    );

    final controllerState = ref.watch(simuladoControllerProvider);
    final controllerNotifier = ref.read(simuladoControllerProvider.notifier);

    // 🖥️ Captura de informações de responsividade estrutural
    final double larguraTela = MediaQuery.of(context).size.width;
    final bool isMobile = larguraTela < 600;

    // ⏳ Leitura direta das variáveis do seu QuizSessionState
    final int tempoRestante = sessionState.tempoRestanteSegundos;

    // Dedução lógica real: se o estado marca tempo maior que zero, a prova tem tempo controlado
    final bool possuiTempo = tempoRestante > 0 || sessionState.tempoEncerrado;

    // ⏰ 🚨 GATILHO DE ENCERRAMENTO FORÇADO (US 15)
    // Se a prova possui controle de tempo e o timer chegou a zero ou disparou flag de encerrado
    if (possuiTempo && (tempoRestante <= 0 || sessionState.tempoEncerrado)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processarEnvioSimulado(
          context: context,
          sessionState: sessionState,
          sessionNotifier: sessionNotifier,
          controllerNotifier: controllerNotifier,
        );
      });
    }

    if (controllerState is AsyncLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Gravando seu histórico de simulados...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (controllerState is AsyncError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Erro ao processar simulado: ${controllerState.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/quiz-selection'),
                  child: const Text('Voltar para Início'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (sessionState.questoes.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Nenhuma questão carregada para este simulado.'),
        ),
      );
    }

    final questaoAtual =
        sessionState.questoes[sessionState.indiceQuestaoAtual] as QuestaoModel;
    final respostaSelecionadaTexto =
        sessionState.respostasSelecionadas[questaoAtual.id];

    // Lógica Cromática Baseada no seu aviso de 5 minutos (300 segundos)
    final bool emAlertaCritico = tempoRestante <= 300;
    final Color corDoCronometro = emAlertaCritico
        ? Colors.red.shade700
        : Colors.blue.shade800;

    // Formatação de Segundos para String legível MM:SS
    String formatarTempo(int totalSegundos) {
      final int minutos = totalSegundos ~/ 60;
      final int segundos = totalSegundos % 60;
      return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Questão ${sessionState.indiceQuestaoAtual + 1} de ${sessionState.questoes.length}',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          // ⏱️ Widget do Cronômetro que consome as suas variáveis
          if (possuiTempo && tempoRestante > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: emAlertaCritico
                        ? Colors.red.shade100
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
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
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🚨 Banner de Alerta usando o 'emAlertaCritico' computado com segurança
              if (possuiTempo && emAlertaCritico && tempoRestante > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Atenção! Restam menos de 5 minutos para o fim da sua prova.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Enunciado da Pergunta
              Text(
                questaoAtual.pergunta,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Lista de Alternativas Dinâmicas
              Expanded(
                child: ListView.builder(
                  itemCount: questaoAtual.opcoes.length,
                  itemBuilder: (context, index) {
                    final opcaoTexto = questaoAtual.opcoes[index];
                    final estaSelecionado =
                        respostaSelecionadaTexto == opcaoTexto;

                    return Card(
                      elevation: estaSelecionado ? 3 : 1,
                      color: estaSelecionado ? Colors.blue.shade50 : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: estaSelecionado
                              ? Colors.blue.shade700
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: estaSelecionado
                              ? Colors.blue.shade700
                              : Colors.grey.shade200,
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: estaSelecionado
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          opcaoTexto,
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                        trailing: estaSelecionado
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : null,
                        onTap: () {
                          sessionNotifier.selecionarAlternativa(
                            questaoAtual.id,
                            opcaoTexto,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Rodapé de Ações Responsivo
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão Anterior
                      SizedBox(
                        width: isMobile ? 110 : 140,
                        height: 45,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          label: const Text('Anterior'),
                          onPressed: sessionState.indiceQuestaoAtual > 0
                              ? sessionNotifier.questaoAnterior
                              : null,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      // Botão Próxima ou Finalizar Simulado
                      if (sessionState.indiceQuestaoAtual ==
                          sessionState.questoes.length - 1)
                        SizedBox(
                          width: isMobile ? 160 : 200,
                          height: 45,
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
                              backgroundColor: Colors.green.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: isMobile ? 110 : 140,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: sessionNotifier.proximaQuestao,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Próxima'),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
