import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rumo_quiz/features/prova/data/providers/prova_provider.dart';
import 'resultado_prova_page.dart';
import '../../../../shared/widgets/organisms/menu_lateral_organism.dart';

class HistoricoPage extends ConsumerWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historicoAsyncValue = ref.watch(streamHistoricoAlunoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Provas',
        ), // Ajustado para bater com a aba do Figma
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),

      // 🟢 ADICIONADO: Injeta o menu lateral sanduíche aqui também!
      drawer: const MenuLateralOrganism(),

      body: historicoAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Erro ao carregar histórico: $err')),
        data: (listaHistorico) {
          if (listaHistorico.isEmpty) {
            return const Center(
              child: Text(
                'Você ainda não realizou nenhum simulado.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listaHistorico.length,
            itemBuilder: (context, index) {
              final historico = listaHistorico[index];

              final porcentagemAcerto = historico.notaMaxima > 0
                  ? (historico.notaObtida / historico.notaMaxima) * 100
                  : 0.0;

              final corDestaque = porcentagemAcerto >= 70
                  ? Colors.green.shade700
                  : Colors.orange.shade800;
              final dataFormatada = DateFormat(
                'dd/MM/yyyy - HH:mm',
              ).format(historico.dataHora);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        historico.tituloProva,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Realizado em: $dataFormatada',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Acertos: ${historico.acertos} de ${historico.totalQuestoes}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aproveitamento: ${porcentagemAcerto.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: corDestaque,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: corDestaque.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${historico.notaObtida.toStringAsFixed(1)} / ${historico.notaMaxima.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: corDestaque,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // SEÇÃO ADICIONADA: Botão "Ver Detalhes" para reabrir a foto do resultado
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('Ver Detalhes'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultadoProvaPage(
                                  tituloProva: historico.tituloProva,
                                  acertos: historico.acertos,
                                  totalQuestoes: historico.totalQuestoes,
                                  notaObtida: historico.notaObtida,
                                  notaMaxima: historico.notaMaxima,
                                  tempoUtilizadoSegundos:
                                      historico.tempoUtilizadoSegundos,
                                  // Envia a lista real do banco, permitindo a inspeção histórica
                                  revisaoQuestoes: historico.revisaoQuestoes,                                  
                                  mensagemFinalizacaoAdmin:
                                      historico.mensagemFinalizacaoAdmin,
                                  pontosGamificacao:
                                      historico.pontosGamificacao,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
