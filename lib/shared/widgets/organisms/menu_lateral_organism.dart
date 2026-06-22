import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final String? userName;
  final String? userRole;
  final String? logoInstituicao;

  const MenuLateralOrganism({
    super.key,
    this.isWebMode = false,
    this.isExpanded = true,
    this.userName,
    this.userRole,
    this.logoInstituicao,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostrarTexto = !isWebMode || isExpanded;
    final usuarioAsync = ref.watch(usuarioStreamProvider);
    final dadosUsuario = usuarioAsync.value as Map<String, dynamic>?;

    final String avatarEmoji = dadosUsuario?['avatarEmoji'] ?? '🐱';
    final String nomeAluno = userName ?? dadosUsuario?['nome'] ?? 'Estudante';
    final String role = userRole ?? dadosUsuario?['role'] ?? 'Acess3';
    final String? logoUrl = logoInstituicao ?? dadosUsuario?['logoInstituicao'];

    final bool isMaster = role.toLowerCase() == 'master';
    final bool isAdmin = role.toLowerCase() == 'admin';

    final Color corCabecalho = isMaster ? const Color(0xFF9C27B0) : Colors.blue.shade700;

    Widget conteudoMenu = Column(
      children: [
        if (mostrarTexto)
          DrawerHeader(
            decoration: BoxDecoration(color: corCabecalho),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isWebMode && logoUrl != null && logoUrl.isNotEmpty) ...[
                    Image.network(
                      logoUrl,
                      height: 45,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Text(avatarEmoji, style: const TextStyle(fontSize: 40)),
                    ),
                    const SizedBox(height: 6),
                  ] else if (!isWebMode) ...[
                    const Icon(Icons.school, size: 40, color: Colors.white),
                    const SizedBox(height: 6),
                  ] else ...[
                    Text(avatarEmoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    nomeAluno,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Nível: $role',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              // Abas do Aluno Comum
              if (!isMaster && !isAdmin) ...[
                _buildItemMenu(
                  context: context,
                  icon: Icons.play_lesson_outlined,
                  label: 'Fazer Quiz / Simulados',
                  route: '/quiz-selection',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.history,
                  label: 'Histórico de Provas',
                  route: '/historico',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Meu Perfil',
                  route: '/perfil',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
              ],

              // Abas do Administrador Comum
              if (isAdmin) ...[
                _buildItemMenu(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Meu Perfil',
                  route: '/perfil',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
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
                  corDestaque: corCabecalho,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Cadastrar Usuários',
                  route: '/cadastro-usuarios',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.analytics_outlined,
                  label: 'Dashboard Analítico',
                  route: '/dashboard-analitico',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
              ],

              // 🔴 ABAS SOLICITADAS: EXCLUSIVAS DO USUÁRIO MASTER
              if (isMaster) ...[
                _buildItemMenu(
                  context: context,
                  icon: Icons.home_max,
                  label: 'Home Master',
                  route: '/master/home',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.gavel_outlined,
                  label: 'Controladoria',
                  route: '/master/controladoria',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.business,
                  label: 'Instituições',
                  route: '/master/instituicoes',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.lock_clock_outlined,
                  label: 'Auditoria',
                  route: '/master/auditoria',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
                ),
                _buildItemMenu(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Meu Perfil',
                  route: '/master/perfil',
                  mostrarTexto: mostrarTexto,
                  corDestaque: corCabecalho,
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
              // CORREÇÃO: Fecha o drawer verificando se existe um Navigator ativo no contexto do botão
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
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
    required Color corDestaque,
  }) {
    final String rotaAtual = GoRouterState.of(context).matchedLocation;
    final bool isSelected = rotaAtual == route;

    return Tooltip(
      message: mostrarTexto ? '' : label,
      child: ListTile(
        contentPadding: mostrarTexto
            ? const EdgeInsets.symmetric(horizontal: 16)
            : const EdgeInsets.symmetric(horizontal: 23),
        leading: Icon(
          icon,
          color: isSelected ? corDestaque : null,
        ),
        title: mostrarTexto 
            ? Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? corDestaque : null,
                ),
              ) 
            : null,
        selected: isSelected,
        selectedTileColor: corDestaque.withOpacity(0.08),
        onTap: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          context.go(route);
        },
      ),
    );
  }
}