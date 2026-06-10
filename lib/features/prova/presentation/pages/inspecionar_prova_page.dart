import 'package:flutter/material.dart';
import '../../domain/models/revisao_questao_model.dart';
import '../molecules/card_questao_revisao_molecule.dart';

class InspecionarProvaPage extends StatelessWidget {
  final String tituloProva;
  final List<RevisaoQuestaoModel> revisaoQuestoes;

  const InspecionarProvaPage({
    super.key,
    required this.tituloProva,
    required this.revisaoQuestoes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revisão: $tituloProva'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Blindagem Web para não esticar
          child: revisaoQuestoes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.find_in_page_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma questão disponível para revisão.',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: revisaoQuestoes.length,
                  itemBuilder: (context, index) {
                    return CardQuestaoRevisaoMolecule(
                      numeroQuestao: index + 1,
                      revisao: revisaoQuestoes[index],
                    );
                  },
                ),
        ),
      ),
    );
  }
}