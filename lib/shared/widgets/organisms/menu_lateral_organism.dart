import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ✨ PROVIDER REATIVO VIA MAP: Entrega as atualizações do banco em tempo real
final usuarioStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null);
});

class MenuLateralOrganism extends ConsumerWidget {
  final bool isWebMode;
  final bool isExpanded;

  const MenuLateralOrganism({
    super.key,
    this.isWebMode = false,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostrarTexto = !isWebMode || isExpanded;

    // ✨ ESCUTANDO O STREAM DO USUÁRIO
    final usuarioAsync = ref.watch(usuarioStreamProvider);
    final dadosUsuario = usuarioAsync.value as Map<String, dynamic>?;

    // 🔒 MANUTENÇÃO INTEGRA: Preservando os avatares e nomes reativos do início
    final String avatarEmoji = dadosUsuario?['avatarEmoji'] ?? '🐱';
    final String nomeAluno = dadosUsuario?['nome'] ?? 'Estudante';
    final String role = dadosUsuario?['role'] ?? 'Acess3';

    Widget conteudoMenu = Column(
      children: [
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
                  Text(
                    'Nível: $role',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 20),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 🌐 ABAS COMUNS (Todos os níveis enxergam)
              _buildItemMenu(
                context: context,
                icon: Icons.play_lesson_outlined,
                label: 'Fazer Quiz / Simulados',
                route: '/quiz-selection',
                mostrarTexto: mostrarTexto,
              ),
              _buildItemMenu(
                context: context,
                icon: Icons.history,
                label: 'Histórico de Provas',
                route: '/historico',
                mostrarTexto: mostrarTexto,
              ),
              _buildItemMenu(
                context: context,
                icon: Icons.person_outline,
                label: 'Meu Perfil',
                route: '/perfil',
                mostrarTexto: mostrarTexto,
              ),

              // 👑 ABAS EXCLUSIVAS: ADMIN E MASTER
              if (role == 'Admin' || role == 'Master') ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Divider(),
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Painel Conteúdo (Admin)',
                  route: '/admin',
                  mostrarTexto: mostrarTexto,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Cadastrar Usuários',
                  route: '/cadastro-usuarios',
                  mostrarTexto: mostrarTexto,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.analytics_outlined,
                  label: 'Dashboard Analítico',
                  route: '/dashboard-analitico',
                  mostrarTexto: mostrarTexto,
                ),
              ],

              // 🔴 ABAS EXCLUSIVAS: SOMENTE MASTER
              if (role == 'Master') ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Divider(),
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.gavel_outlined,
                  label: 'Controladoria Master',
                  route: '/master-home',
                  mostrarTexto: mostrarTexto,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.lock_clock_outlined,
                  label: 'Logs e Auditoria',
                  route: '/auditoria-master',
                  mostrarTexto: mostrarTexto,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.sports_esports_outlined,
                  label: 'Configurar Recompensas',
                  route: '/configuracao-gamificacao',
                  mostrarTexto: mostrarTexto,
                ),
              ],
            ],
          ),
        ),

        const Divider(),
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