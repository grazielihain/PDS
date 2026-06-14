import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/prova_model.dart';
import '../providers/prova_provider.dart';
import '../providers/quiz_session_provider.dart'; // 🔄 Importado o provedor de sessão correto

class QuizSelectionPage extends ConsumerWidget {
  const QuizSelectionPage({super.key});

  // Função auxiliar para buscar o perfil do usuário logado diretamente no Firestore
  Future<Map<String, dynamic>?> _buscarPerfilUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      return doc.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _buscarPerfilUsuario(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(
              child: Text('Erro ao carregar perfil do usuário.'),
            );
          }

          final dadosUsuario = userSnapshot.data!;
          final instituicaoId =
              dadosUsuario['instituicaoId'] ?? 'NENHUM ID ENCONTRADO';
          final nomeAluno = dadosUsuario['nome'] ?? 'Estudante';

          // Assistimos o provider passando o ID
          final provasAsyncValue = ref.watch(
            listaQuestoesFirestoreProvider(instituicaoId),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $nomeAluno!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sua instituição cadastrada é: $instituicaoId',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecione um dos questionários abaixo para iniciar:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: provasAsyncValue.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        Center(child: Text('Erro ao buscar quizzes: $err')),
                    data: (listaProvas) {
                      if (listaProvas.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum quiz disponível para sua instituição no momento.',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: listaProvas.length,
                        itemBuilder: (context, index) {
                          // 🧠 Agora cada item da lista é uma QuestaoModel vinda do provider
                          final questao = listaProvas[index];

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: const Icon(
                                Icons.assignment,
                                size: 40,
                                color: Colors.blue,
                              ),
                              // 🔄 Trocado prova.titulo por questao.pergunta (ou assuntoId se preferir um título curto)
                              title: Text(
                                'Simulado de ${questao.categoriaId.toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              // 🔄 Trocado prova.descricao pelos detalhes da categoria e assunto da questão
                              subtitle: Text(
                                'Assunto: ${questao.assuntoId}\nQuestão ID: ${questao.id}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.blue,
                              ),
                              onTap: () {
                                // 🧠 Alimenta o motor de sessão com os dados da questão clicada
                                ref.read(quizSessionProvider.notifier).iniciarSimulado(
                                      categoriaId: questao.categoriaId, 
                                      modoProva: 'completa',
                                      assunto: questao.assuntoId,
                                      questoesDisponiveisNoBanco: const [], 
                                      qtdSolicitada: 10, 
                                      tempoMinutos: 30, // Definido um tempo padrão seguro (ex: 30 min) já que a questão não possui tempo próprio
                                    );

                                // 🚀 Navega de forma segura
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
          );
        },
      ),
    );
  }
}