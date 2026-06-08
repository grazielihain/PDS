import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizSelectionPage extends ConsumerWidget {
  const QuizSelectionPage({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bem-vindo ao Rumo Quiz!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione um dos questionários abaixo para iniciar:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 4,
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
                title: const Text(
                  'Quiz de Engenharia de Software I',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: const Text('10 Questões • Tempo: 20 min'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue,
                ),
                onTap: () {
                  // Ação futura para abrir o quiz
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
