import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/prova_model.dart';
import '../../data/providers/prova_provider.dart';
import '../pages/quiz_run_page.dart';

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
      appBar: AppBar(
        title: const Text('Quizzes Disponíveis'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
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
            listaProvasProvider(instituicaoId),
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
                // TEXTO VAI MOSTRAR O ID DIRETO NA TELA:
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
                          final prova = listaProvas[index];

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
                              title: Text(
                                prova.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                '${prova.descricao}\nTempo: ${prova.tempoEmMinutos} min',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.blue,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QuizRunPage(prova: prova),
                                  ),
                                );
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
