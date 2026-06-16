import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoricoCardMolecule extends StatelessWidget {
  final String categoria;
  final String tipoProva;
  final String? assunto;
  final int acertos;
  final int totalQuestoes;
  final double pontosProva;
  final int pontosGamificacao;
  final DateTime dataConclusao;
  final VoidCallback onTapVisualizar;

  const HistoricoCardMolecule({
    super.key,
    required this.categoria,
    required this.tipoProva,
    this.assunto,
    required this.acertos,
    required this.totalQuestoes,
    required this.pontosProva,
    required this.pontosGamificacao,
    required this.dataConclusao,
    required this.onTapVisualizar,
  });

  @override
  Widget build(BuildContext context) {
    final String dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(dataConclusao);
    final bool isPorAssunto = tipoProva.toLowerCase().contains('assunto');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTapVisualizar,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      categoria,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tipoProva,
                      style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (isPorAssunto && assunto != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Assunto: $assunto',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acertos: $acertos / $totalQuestoes',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dataFormatada,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Regra de negócio explícita do prompt: Prova por Assunto mostra emoticon fofo no lugar de pontos normais
                      if (isPorAssunto)
                        const Text(
                          '🐱 Padrão',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        )
                      else
                        Text(
                          '${pontosProva.toStringAsFixed(1)} Pts',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '+$pontosGamificacao Bônus (Acumulado)',
                        style: TextStyle(color: Colors.amber.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}