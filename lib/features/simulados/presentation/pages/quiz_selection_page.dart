import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/features/auth/presentation/providers/white_label_notifier.dart';
import '../../data/models/questao_model.dart'; // 🌟 Corrigido para importar QuestaoModel
import '../providers/simulado_provider.dart';
import '../providers/quiz_session_provider.dart';

class QuizSelectionPage extends ConsumerWidget {
  const QuizSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎨 CAPTURA DA IDENTIDADE VISUAL WHITE LABEL
    final estadoWhiteLabel = ref.watch(whiteLabelProvider);
    Color corPrimariaExibicao = Colors.blue.shade700;

    final hexObtido = estadoWhiteLabel.corPrimariaHex;
    if (hexObtido != null && hexObtido.isNotEmpty) {
      final valorInteiro = int.tryParse(hexObtido.replaceAll('#', '0xFF'));
      if (valorInteiro != null) {
        corPrimariaExibicao = Color(valorInteiro);
      }
    }

    // 🏎️ ECONOMIA DE LEITURAS: Recupera o ID da instituição direto da memória RAM
    final instituicaoId = estadoWhiteLabel.instituicao?.id ?? 'ulbra-01';
    final nomeAluno = FirebaseAuth.instance.currentUser?.displayName ?? 'Estudante';

    // Escuta o provider que retorna List<QuestaoModel>
    final questoesAsyncValue = ref.watch(
      listaQuestoesFirestoreProvider(instituicaoId),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $nomeAluno!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: corPrimariaExibicao.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Ambiente Acadêmico: ${estadoWhiteLabel.instituicao?.nome ?? instituicaoId.toUpperCase()}',
                style: TextStyle(
                  fontSize: 13,
                  color: corPrimariaExibicao,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecione um dos questionários abaixo para iniciar:',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: questoesAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    'Erro ao buscar simulados: $err',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (listaQuestoes) {
                  if (listaQuestoes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Nenhum simulado disponível para sua instituição no momento.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // 🏎️ INTELIGÊNCIA ECONÔMICA: Agrupa as questões por categorias únicas na memória RAM
                  // Isso impede leituras repetitivas no banco para gerar "listas de provas"
                  final categoriasUnicas = <String, List<QuestaoModel>>{};
                  for (var q in listaQuestoes) {
                    final cat = q.categoriaId.isEmpty ? 'Geral' : q.categoriaId;
                    categoriasUnicas.putIfAbsent(cat, () => []).add(q);
                  }

                  final chavesCategorias = categoriasUnicas.keys.toList();

                  return ListView.builder(
                    itemCount: chavesCategorias.length,
                    itemBuilder: (context, index) {
                      final categoriaNome = chavesCategorias[index];
                      final questoesDaCategoria = categoriasUnicas[categoriaNome] ?? [];
                      final primeiroRegistro = questoesDaCategoria.first;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: corPrimariaExibicao.withOpacity(0.1),
                            child: Icon(
                              Icons.assignment_outlined,
                              color: corPrimariaExibicao,
                            ),
                          ),
                          title: Text(
                            'Simulado de ${categoriaNome.toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Assunto principal: ${primeiroRegistro.assuntoId}\nQuantidade: ${questoesDaCategoria.length} questões disponíveis',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: corPrimariaExibicao,
                          ),
                          onTap: () {
                            // Injeta as questões filtradas na sessão ativa do simulado
                            ref.read(quizSessionProvider.notifier).iniciarSimulado(
                                  categoriaId: categoriaNome,
                                  modoProva: 'completa',
                                  assunto: primeiroRegistro.assuntoId,
                                  questoesDisponiveisNoBanco: questoesDaCategoria,
                                  qtdSolicitada: 10,
                                  tempoMinutos: 15,
                                );

                            context.go('/executar-simulado');
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}