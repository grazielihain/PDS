import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/features/auth/presentation/providers/white_label_notifier.dart';
import '../../data/models/prova_model.dart';
import '../providers/simulado_provider.dart';
import '../providers/quiz_session_provider.dart';

class QuizSelectionPage extends ConsumerWidget {
  const QuizSelectionPage({super.key});

  // Função auxiliar para buscar o perfil do usuário logado diretamente no Firestore
  Future<Map<String, dynamic>?> _buscarPerfilUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        return doc.data();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎨 CAPTURA DA IDENTIDADE VISUAL WHITE LABEL
    final dynamic estadoWhiteLabel = ref.watch(whiteLabelProvider);
    Color corPrimariaExibicao = Colors.blue.shade700;

    try {
      if (estadoWhiteLabel != null) {
        String? hexObtido;
        if (estadoWhiteLabel.toString().contains('corPrimariaHex')) {
          hexObtido = estadoWhiteLabel.corPrimariaHex;
        } else if (estadoWhiteLabel.toString().contains('primaryColorHex')) {
          hexObtido = estadoWhiteLabel.primaryColorHex;
        }

        if (hexObtido != null && hexObtido.isNotEmpty) {
          final valorInteiro = int.tryParse(hexObtido.replaceAll('#', '0xFF'));
          if (valorInteiro != null) {
            corPrimariaExibicao = Color(valorInteiro);
          }
        }
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _buscarPerfilUsuario(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Fallback seguro caso o Firestore falhe ou o documento não exista
          final userNativo = FirebaseAuth.instance.currentUser;
          final dadosUsuario = userSnapshot.data;
          
          final instituicaoId = dadosUsuario?['instituicaoId'] ?? 'NENHUM ID ENCONTRADO';
          final nomeAluno = dadosUsuario?['nome'] ?? userNativo?.displayName ?? 'Estudante';

          // Assistimos o provider passando o ID de isolamento da instituição
          final provasAsyncValue = ref.watch(
            listaQuestoesFirestoreProvider(instituicaoId),
          );

          return Padding(
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
                    'Ambiente Académico: $instituicaoId',
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
                  child: provasAsyncValue.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Text(
                        'Erro ao buscar quizzes: $err',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    data: (listaProvas) {
                      if (listaProvas.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'Nenhum quiz disponível para sua instituição no momento.',
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

                      return ListView.builder(
                        itemCount: listaProvas.length,
                        itemBuilder: (context, index) {
                          final questao = listaProvas[index];

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
                                'Simulado de ${questao.categoriaId.toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Assunto: ${questao.assuntoId}\nFiltro: Exclusivo da sua instituição',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: corPrimariaExibicao,
                              ),
                              onTap: () {
                                // Injeta a lista real contendo as questões validadas do banco
                                ref.read(quizSessionProvider.notifier).iniciarSimulado(
                                      categoriaId: questao.categoriaId,
                                      modoProva: 'completa',
                                      assunto: questao.assuntoId,
                                      questoesDisponiveisNoBanco: listaProvas,
                                      qtdSolicitada: 10,
                                      tempoMinutos: 6,
                                    );

                                // Navegação segura via GoRouter
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