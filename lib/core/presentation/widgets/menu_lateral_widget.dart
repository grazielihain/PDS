import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORTS DOS MODELOS E PROVÍDERS
import 'package:rumo_quiz/features/prova/domain/models/historico_model.dart';
import 'package:rumo_quiz/features/prova/data/providers/prova_provider.dart';

// IMPORTS DAS PÁGINAS (ABAS DO MENU)
import 'package:rumo_quiz/features/prova/presentation/pages/historico_pages.dart';
import 'package:rumo_quiz/features/prova/presentation/pages/quiz_selection_page.dart';
// 🟢 IMPORT DO PERFIL ADICIONADO
import 'package:rumo_quiz/features/auth/presentation/pages/meu_perfil_page.dart';

class MenuLateralWidget extends StatelessWidget {
  const MenuLateralWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          // 🟢 TOPO DO MENU LATERAL DINÂMICO (Busca os dados atualizados do Perfil)
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user?.uid)
                .get(),
            builder: (context, snapshot) {
              String avatar = '🐱';
              String nomeAluno = 'Estudante';

              if (snapshot.hasData && snapshot.data!.exists) {
                final dados = snapshot.data!.data() as Map<String, dynamic>?;
                avatar = dados?['avatarEmoji'] ?? '🐱';
                nomeAluno = dados?['nome'] ?? 'Estudante';
              }

              return DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue.shade700),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(avatar, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        nomeAluno,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Portal do Aluno',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 1. ABA: HOME / DASHBOARD
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Home / Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizSelectionPage(),
                ),
              );
            },
          ),

          // 2. ABA: FAZER QUIZ / SIMULADOS
          ListTile(
            leading: const Icon(Icons.play_lesson_outlined),
            title: const Text('Fazer Quiz / Simulados'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizSelectionPage(),
                ),
              );
            },
          ),

          // 3. ABA: MEUS RESULTADOS
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Meus Resultados'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HistoricoPage()),
              );
            },
          ),

          // 4. ABA: HISTÓRICO DE PROVAS
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Histórico de Provas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HistoricoPage()),
              );
            },
          ),

          // 5. ABA: MEU PERFIL (🟢 CORRIGIDO: Agora navega de verdade para a página)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Meu Perfil'),
            onTap: () {
              Navigator.pop(context); // Fecha o menu lateral
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MeuPerfilPage()),
              );
            },
          ),

          const Spacer(),
          const Divider(),

          // BOTÃO SAIR DO APP
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sair do Aplicativo',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
