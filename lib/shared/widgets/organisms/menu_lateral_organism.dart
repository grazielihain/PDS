import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/prova/presentation/pages/quiz_selection_page.dart';
import '../../../features/prova/presentation/pages/historico_pages.dart';

class MenuLateralOrganism extends StatelessWidget {
  const MenuLateralOrganism({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // TOPO DO MENU (Dados do Aluno)
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🐱', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text(
                    'Rumo Quiz', 
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const QuizSelectionPage()),
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
                MaterialPageRoute(builder: (context) => const QuizSelectionPage()),
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

          // 5. ABA: MEU PERFIL
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Meu Perfil'),
            onTap: () {
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aba Meu Perfil em desenvolvimento...')),
              );
            },
          ),
          
          const Spacer(),
          const Divider(),
          
          // BOTÃO SAIR
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair do Aplicativo', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}