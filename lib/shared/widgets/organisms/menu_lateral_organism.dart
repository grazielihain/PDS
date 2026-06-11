import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class MenuLateralOrganism extends StatelessWidget {
  final bool isWebMode;
  final bool isExpanded;
  final String avatarEmoji;
  final String nomeAluno;

  const MenuLateralOrganism({
    super.key,
    this.isWebMode = false,
    this.isExpanded = true,
    required this.avatarEmoji,
    required this.nomeAluno,
  });

  @override
  Widget build(BuildContext context) {
    final mostrarTexto = !isWebMode || isExpanded;

    Widget conteudoMenu = Column(
      children: [
        // CABEÇALHO DO MENU: Sincronizado instantaneamente via construtor
        if (mostrarTexto)
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(avatarEmoji, style: const TextStyle(fontSize: 40)),
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
          )
        else
          const SizedBox(height: 20),

        // 1. ABA: HOME / DASHBOARD
        _buildItemMenu(
          context: context,
          icon: Icons.dashboard_outlined,
          label: 'Home / Dashboard',
          route: '/quiz-selection',
          mostrarTexto: mostrarTexto,
        ),

        // 2. ABA: FAZER QUIZ / SIMULADOS
        _buildItemMenu(
          context: context,
          icon: Icons.play_lesson_outlined,
          label: 'Fazer Quiz / Simulados',
          route: '/quiz-selection',
          mostrarTexto: mostrarTexto,
        ),

        // 3. ABA: MEUS RESULTADOS
        _buildItemMenu(
          context: context,
          icon: Icons.bar_chart_outlined,
          label: 'Meus Resultados',
          route: '/historico',
          mostrarTexto: mostrarTexto,
        ),

        // 4. ABA: HISTÓRICO DE PROVAS
        _buildItemMenu(
          context: context,
          icon: Icons.history,
          label: 'Histórico de Provas',
          route: '/historico',
          mostrarTexto: mostrarTexto,
        ),

        // 5. ABA: MEU PERFIL
        _buildItemMenu(
          context: context,
          icon: Icons.person_outline,
          label: 'Meu Perfil',
          route: '/perfil',
          mostrarTexto: mostrarTexto,
        ),

        const Spacer(),
        const Divider(),

        // BOTÃO SAIR DO APP
        Tooltip(
          message: mostrarTexto ? '' : 'Sair do Aplicativo',
          child: ListTile(
            contentPadding: mostrarTexto
                ? const EdgeInsets.symmetric(horizontal: 16)
                : const EdgeInsets.symmetric(horizontal: 23),
            leading: const Icon(Icons.logout, color: Colors.red),
            title: mostrarTexto
                ? const Text(
                    'Sair do Aplicativo',
                    style: TextStyle(color: Colors.red),
                  )
                : null,
            onTap: () async {
              if (!isWebMode) Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                debugPrint('Erro ao deslogar: $e');
              }
            },
          ),
        ),
      ],
    );

    return isWebMode
        ? Container(color: Colors.white, child: conteudoMenu)
        : Drawer(child: conteudoMenu);
  }

  Widget _buildItemMenu({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required bool mostrarTexto,
  }) {
    return Tooltip(
      message: mostrarTexto ? '' : label,
      child: ListTile(
        contentPadding: mostrarTexto
            ? const EdgeInsets.symmetric(horizontal: 16)
            : const EdgeInsets.symmetric(horizontal: 23),
        leading: Icon(icon),
        title: mostrarTexto ? Text(label) : null,
        onTap: () {
          if (!isWebMode) Navigator.pop(context);
          context.go(route);
        },
      ),
    );
  }
}