import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Importação do provedor de abas unificado do Master
import 'package:rumo_quiz/features/master/presentation/providers/master_providers.dart';

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

    // ✨ ESCUTANDO O STREAM DO USUÁRIO
    final usuarioAsync = ref.watch(usuarioStreamProvider);
    final dadosUsuario = usuarioAsync.value;

    // 🔒 MANUTENÇÃO ÍNTEGRA COM PARÂMETROS ADICIONAIS
    final String avatarEmoji = dadosUsuario?['avatarEmoji'] ?? '🐱';
    final String nomeAluno = userName ?? dadosUsuario?['nome'] ?? 'Estudante';
    final String role = userRole ?? dadosUsuario?['role'] ?? 'Acess3';
    final String? logoUrl = logoInstituicao ?? dadosUsuario?['logoInstituicao'];

    // 🎨 Identidade de Cores por Herança Dinâmica: se for Master, usa lilás/purple corporativo fixo.
    final bool isMaster = role.toString().trim().toLowerCase() == 'master';
    final Color corTemaHeader = isMaster
        ? Colors.purple.shade800
        : Colors.blue.shade700;

    // Monitora a sub-aba ativa caso o usuário logado seja Master
    final abaAtivaMaster = ref.watch(masterAbaAtivaProvider);

    Widget conteudoMenu = Column(
      children: [
        if (mostrarTexto)
          DrawerHeader(
            decoration: BoxDecoration(color: corTemaHeader),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isWebMode &&
                      logoUrl != null &&
                      logoUrl.isNotEmpty &&
                      !isMaster) ...[
                    Image.network(
                      logoUrl,
                      height: 45,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Text(
                        avatarEmoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ] else if (!isWebMode) ...[
                    Icon(
                      isMaster
                          ? Icons.admin_panel_settings_outlined
                          : Icons.school,
                      size: 40,
                      color: Colors.white,
                    ),
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
                    isMaster ? 'Nível: Diretor Master' : 'Nível: $role',
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
              // 🌐 ABAS DO ALUNO (Ocultadas completamente se o usuário for Master)
              if (!isMaster) ...[
                _buildItemMenu(
                  context: context,
                  ref: ref,
                  icon: Icons.play_lesson_outlined,
                  label: 'Fazer Quiz / Simulados',
                  route: '/quiz-selection',
                  mostrarTexto: mostrarTexto,
                  isMaster: false,
                ),
                _buildItemMenu(
                  context: context,
                  ref: ref,
                  icon: Icons.history,
                  label: 'Histórico de Provas',
                  route: '/historico',
                  mostrarTexto: mostrarTexto,
                  isMaster: false,
                ),
              ],

              // 👤 ABA MEU PERFIL (Comportamento Adaptativo Dinâmico)
              _buildItemMenu(
                context: context,
                ref: ref,
                icon: Icons.person_outline,
                label: 'Meu Perfil',
                route: '/perfil',
                mostrarTexto: mostrarTexto,
                isMaster: isMaster,
                targetMasterIndex:
                    4, // Aloca a renderização do MeuPerfil dentro do contêiner Master
                isSelected: isMaster && abaAtivaMaster == 4,
              ),

              // 👑 ABAS EXCLUSIVAS: ADMIN (Master ignora e oculta)
              if (role.toLowerCase() == 'admin') ...[
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Divider(),
                ),
                _buildItemMenu(
                  context: context,
                  ref: ref,
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Painel Conteúdo (Admin)',
                  route: '/admin',
                  mostrarTexto: mostrarTexto,
                  isMaster: false,
                ),
                _buildItemMenu(
                  context: context,
                  ref: ref,
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Cadastrar Usuários',
                  route: '/cadastro-usuarios',
                  mostrarTexto: mostrarTexto,
                  isMaster: false,
                ),
                _buildItemMenu(
                  context: context,
                  ref: ref,
                  icon: Icons.analytics_outlined,
                  label: 'Dashboard Analítico',
                  route: '/dashboard-analitico',
                  mostrarTexto: mostrarTexto,
                  isMaster: false,
                ),
              ],

              // 🔴 PAINEL ESTRATÉGICO UNIFICADO: EXCLUSIVO MASTER
              if (isMaster) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Divider(),
                ),
                _buildItemMenu(
                  context: context,
                  ref: ref,
                  icon: Icons.dashboard_outlined,
                  label: 'Visão Geral (Master)',
                  route: '/master-home',
                  mostrarTexto: mostrarTexto,
                  isMaster: true,
                  targetMasterIndex: 0,
                  isSelected: abaAtivaMaster == 0,
                ),
                _buildItemMenu(
                  context: context,
                  ref: ref,
                  icon: Icons.gavel_outlined,
                  label: 'Controladoria Financeira',
                  route: '/master-home',
                  mostrarTexto: mostrarTexto,
                  isMaster: true,
                  targetMasterIndex: 1,
                  isSelected: abaAtivaMaster == 1,
                ),
                _buildItemMenu(
                  context: context,
                  ref: ref,
                  icon: Icons.business_outlined,
                  label: 'Gerenciar Instituições',
                  route: '/master-home',
                  mostrarTexto: mostrarTexto,
                  isMaster: true,
                  targetMasterIndex: 2,
                  isSelected: abaAtivaMaster == 2,
                ),
                _buildItemMenu(
                  context: context,
                  ref: ref,
                  icon: Icons.security_outlined,
                  label: 'Auditoria de Logs',
                  route: '/master-home',
                  mostrarTexto: mostrarTexto,
                  isMaster: true,
                  targetMasterIndex: 3,
                  isSelected: abaAtivaMaster == 3,
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
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required String route,
    required bool mostrarTexto,
    required bool isMaster,
    int? targetMasterIndex,
    bool isSelected = false,
  }) {
    // Determina a cor do ícone e do texto baseado na seleção do menu lateral unificado
    final Color? corItem = isSelected ? Colors.purple.shade700 : null;
    final FontWeight pesoTexto = isSelected
        ? FontWeight.bold
        : FontWeight.normal;

    return Tooltip(
      message: mostrarTexto ? '' : label,
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Colors.purple.withOpacity(0.08),
        contentPadding: mostrarTexto
            ? const EdgeInsets.symmetric(horizontal: 16)
            : const EdgeInsets.symmetric(horizontal: 23),
        leading: Icon(icon, color: corItem),
        title: mostrarTexto
            ? Text(
                label,
                style: TextStyle(color: corItem, fontWeight: pesoTexto),
              )
            : null,
        onTap: () {
          if (!isWebMode) Navigator.pop(context);

          // Se for Master e a ação for direcionada a uma sub-aba unificada
          if (isMaster && targetMasterIndex != null) {
            ref.read(masterAbaAtivaProvider.notifier).state = targetMasterIndex;
            // Garante que o container mãe está carregado na tela atual
            if (GoRouterState.of(context).matchedLocation != '/master-home') {
              context.go('/master-home');
            }
          } else {
            // Navegação por rotas tradicional para Alunos e Administradores
            context.go(route);
          }
        },
      ),
    );
  }
}
