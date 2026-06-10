import 'package:flutter/material.dart';
import '../../domain/models/revisao_questao_model.dart';

class CardQuestaoRevisaoMolecule extends StatelessWidget {
  final int numeroQuestao;
  final RevisaoQuestaoModel revisao;

  const CardQuestaoRevisaoMolecule({
    super.key,
    required this.numeroQuestao,
    required this.revisao,
  });

  @override
  Widget build(BuildContext context) {
    final questao = revisao.questao;
    final marcouCorreto = revisao.opcaoEscolhidaIndex == questao.respostaCorretaIndex;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: marcouCorreto ? Colors.green.shade300 : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da Questão (Número + Status + Pontuação)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questão $numeroQuestao',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: marcouCorreto ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        marcouCorreto ? Icons.check_circle : Icons.cancel,
                        color: marcouCorreto ? Colors.green.shade700 : Colors.red.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        marcouCorreto ? 'Acertou (+${questao.nota} pts)' : 'Errou (0.0 pts)',
                        style: TextStyle(
                          color: marcouCorreto ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Enunciado da Questão
            Text(
              questao.pergunta,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Lista de Alternativas Estilizadas
            ...List.generate(questao.opcoes.length, (index) {
              final alternativaTexto = questao.opcoes[index];
              final foiAEscolhidaPeloAluno = revisao.opcaoEscolhidaIndex == index;
              final ehAGabaritoCorreto = questao.respostaCorretaIndex == index;

              // Lógica de Cores do Atomic Design para as Linhas de Alternativa
              Color corFundo = Colors.transparent;
              Color corBorda = Colors.grey.shade300;
              IconData? iconeFeedback;
              Color corConteudo = Colors.black87;

              if (ehAGabaritoCorreto) {
                corFundo = Colors.green.shade50;
                corBorda = Colors.green.shade600;
                corConteudo = Colors.green.shade900;
                iconeFeedback = Icons.check;
              } else if (foiAEscolhidaPeloAluno && !marcouCorreto) {
                corFundo = Colors.red.shade50;
                corBorda = Colors.red.shade600;
                corConteudo = Colors.red.shade900;
                iconeFeedback = Icons.close;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: corFundo,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: corBorda, width: 1.2),
                ),
                child: Row(
                  children: [
                    // Letra da alternativa (A, B, C, D...)
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: foiAEscolhidaPeloAluno 
                          ? (marcouCorreto ? Colors.green : Colors.red) 
                          : Colors.grey.shade200,
                      child: Text(
                        String.fromCharCode(65 + index), // Converte 0 em 'A', 1 em 'B'...
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                          color: foiAEscolhidaPeloAluno ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Texto da alternativa
                    Expanded(
                      child: Text(
                        alternativaTexto,
                        style: TextStyle(
                          fontSize: 14, 
                          color: corConteudo,
                          fontWeight: (ehAGabaritoCorreto || foiAEscolhidaPeloAluno) 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                        ),
                      ),
                    ),

                    // Ícone indicador (Sinalizador de erro ou acerto)
                    if (iconeFeedback != null)
                      Icon(iconeFeedback, size: 18, color: corBorda),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}