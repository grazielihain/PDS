import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// IMPORTS DOS MODELOS E PROVÍDERS
import 'package:rumo_quiz/features/prova/domain/models/historico_model.dart';
import 'package:rumo_quiz/features/prova/data/providers/prova_provider.dart';

// IMPORTS DAS PÁGINAS (ABAS DO MENU)
import 'package:rumo_quiz/features/prova/presentation/pages/historico_pages.dart';
//import 'package:rumo_quiz/features/prova/presentation/pages/resultado_prova_page.dart';

// Tela de seleção de provas/Home
import 'package:rumo_quiz/features/prova/presentation/pages/quiz_selection_page.dart';

class MenuLateralWidget extends StatelessWidget {
  const MenuLateralWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // TOPO DO MENU LATERAL (Dados do Aluno)
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🐱',
                    style: TextStyle(fontSize: 40),
                  ), // Avatar temporário
                  SizedBox(height: 8),
                  Text(
                    'Rumo Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Portal do Aluno',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // 1. ABA: HOME / DASHBOARD
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Home / Dashboard'),
            onTap: () {
              Navigator.pop(context); // Fecha o menu lateral

              // Se você tiver uma tela chamada DashboardPage ou HomePage, chame ela aqui.
              // Por enquanto, como a listagem de provas é a tela inicial do aluno, vamos mantê-la:
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
              // Abre a tela de histórico que lista todas as notas e gráficos
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

          // 5. ABA: MEU PERFIL
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Meu Perfil'),
            onTap: () {
              Navigator.pop(context);
              // Mantém o aviso amigável até você criar o arquivo dessa página
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Aba Meu Perfil em desenvolvimento (Ajustes de Avatar/Senha)...',
                  ),
                ),
              );
            },
          ),

          const Spacer(), // Empurra o botão de sair para o final da tela
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
