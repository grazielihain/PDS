import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class MenuLateralOrganism extends StatelessWidget {
  final bool isWebMode;
  final bool isExpanded;
  final String avatarEmoji;
  final String nomeUsuario;
  final String tipoAcesso;
  final Color corPrimaria;
  final String instituicaoId;
  final String logoInstituicaoUrl;

  const MenuLateralOrganism({
    super.key,
    this.isWebMode = false,
    this.isExpanded = true,
    required this.avatarEmoji,
    required this.nomeUsuario,
    this.tipoAcesso = 'Acess3',
    this.corPrimaria = Colors.blue,
    this.instituicaoId = '',
    this.logoInstituicaoUrl = '',
  });

  String get _tituloPerfil {
    switch (tipoAcesso) {
      case 'Master':
        return 'Portal Master';
      case 'Admin':
        return 'Portal do Administrador';
      case 'Acess2':
        return 'Portal do Gestor';
      default:
        return 'Portal do Aluno';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mostrarTexto = !isWebMode || isExpanded;

    final bool fundoEscuro =
        ThemeData.estimateBrightnessForColor(corPrimaria) == Brightness.dark;
    final Color corTextoCabecalho = fundoEscuro ? Colors.white : Colors.black87;
    final Color corSubtitulo = fundoEscuro
        ? Colors.white.withAlpha(180)
        : Colors.black54;

    Widget conteudoMenu = Column(
      children: [
        // CABEÇALHO DO MENU 
        if (mostrarTexto)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: corPrimaria),
            padding: const EdgeInsets.fromLTRB(12, 36, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Linha: logos + botão fechar (mobile)
                Row(
                  children: [
                    // Logo Rumo Quiz (somente mobile)
                    if (!isWebMode)
                      Image.asset(
                        'assets/images/logo_rumo_quiz_sem_slogan.png',
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.quiz,
                              size: 13,
                              color: corTextoCabecalho.withAlpha(200),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Rumo Quiz',
                              style: TextStyle(
                                fontSize: 10,
                                color: corTextoCabecalho.withAlpha(200),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isWebMode && logoInstituicaoUrl.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.network(
                          logoInstituicaoUrl,
                          height: 18,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, _) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Botão fechar (somente mobile/drawer)
                    if (!isWebMode)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.chevron_left,
                          size: 22,
                          color: corTextoCabecalho,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(avatarEmoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(height: 4),
                Text(
                  nomeUsuario,
                  style: TextStyle(
                    color: corTextoCabecalho,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _tituloPerfil,
                  style: TextStyle(color: corSubtitulo, fontSize: 11),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 80,
            child: Center(
              child: Text(avatarEmoji, style: const TextStyle(fontSize: 32)),
            ),
          ),

        // ITENS DE MENU (scrolláveis) 
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: _buildItensMenu(context, mostrarTexto),
          ),
        ),

        const Divider(height: 1),

        // BOTÃO SAIR 
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
                if (context.mounted) context.go('/login');
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

  List<Widget> _buildItensMenu(BuildContext context, bool mostrarTexto) {
    switch (tipoAcesso) {
      case 'Master':
        return [
          _buildItem(
            context: context,
            icon: Icons.dashboard_outlined,
            label: 'Home',
            route: '/master-painel',
            tabIndex: 0,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.business_outlined,
            label: 'Instituições',
            route: '/master-painel',
            tabIndex: 1,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.gavel_outlined,
            label: 'Auditoria',
            route: '/master-painel',
            tabIndex: 2,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.person_outline,
            label: 'Meu Perfil',
            route: '/master-painel',
            tabIndex: 3,
            mostrarTexto: mostrarTexto,
          ),
        ];

      case 'Admin':
        return [
          _buildItem(
            context: context,
            icon: Icons.analytics_outlined,
            label: 'Home',
            route: '/admin-painel',
            tabIndex: 0,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.palette_outlined,
            label: 'Painel Admin',
            route: '/admin-painel',
            tabIndex: 1,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.category_outlined,
            label: 'Categorias',
            route: '/admin-painel',
            tabIndex: 2,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.quiz_outlined,
            label: 'Questões',
            route: '/admin-painel',
            tabIndex: 3,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.message_outlined,
            label: 'Mensagens',
            route: '/admin-painel',
            tabIndex: 4,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.stars_outlined,
            label: 'Gamificação',
            route: '/admin-painel',
            tabIndex: 5,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.people_outline,
            label: 'Usuários',
            route: '/admin-painel',
            tabIndex: 6,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.gavel_outlined,
            label: 'Auditoria',
            route: '/admin-painel',
            tabIndex: 7,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.person_outline,
            label: 'Meu Perfil',
            route: '/admin-painel',
            tabIndex: 8,
            mostrarTexto: mostrarTexto,
          ),
        ];

      case 'Acess2':
        return [
          _buildItem(
            context: context,
            icon: Icons.analytics_outlined,
            label: 'Home',
            route: '/admin-painel',
            tabIndex: 0,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.category_outlined,
            label: 'Categorias',
            route: '/admin-painel',
            tabIndex: 1,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.quiz_outlined,
            label: 'Questões',
            route: '/admin-painel',
            tabIndex: 2,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.message_outlined,
            label: 'Mensagens',
            route: '/admin-painel',
            tabIndex: 3,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.people_outline,
            label: 'Usuários',
            route: '/admin-painel',
            tabIndex: 4,
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.person_outline,
            label: 'Meu Perfil',
            route: '/admin-painel',
            tabIndex: 5,
            mostrarTexto: mostrarTexto,
          ),
        ];

      default: // Acess3
        return [
          _buildItem(
            context: context,
            icon: Icons.dashboard_outlined,
            label: 'Home / Dashboard',
            route: '/quiz-selection',
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.play_lesson_outlined,
            label: 'Fazer Quiz',
            route: '/fazer-quiz',
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.bar_chart_outlined,
            label: 'Meus Resultados',
            route: '/meus-resultados',
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.history,
            label: 'Histórico de Simulados',
            route: '/historico',
            mostrarTexto: mostrarTexto,
          ),
          _buildItem(
            context: context,
            icon: Icons.person_outline,
            label: 'Meu Perfil',
            route: '/perfil',
            mostrarTexto: mostrarTexto,
          ),
        ];
    }
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required bool mostrarTexto,
    int tabIndex = 0,
  }) {
    final currentUri = GoRouterState.of(context).uri;
    final currentTab =
        int.tryParse(currentUri.queryParameters['tab'] ?? '0') ?? 0;
    final bool ativo = currentUri.path == route && currentTab == tabIndex;

    return Tooltip(
      message: mostrarTexto ? '' : label,
      child: ListTile(
        contentPadding: mostrarTexto
            ? const EdgeInsets.symmetric(horizontal: 16)
            : const EdgeInsets.symmetric(horizontal: 23),
        leading: Icon(icon, color: ativo ? corPrimaria : null),
        title: mostrarTexto
            ? Text(
                label,
                style: TextStyle(
                  color: ativo ? corPrimaria : null,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                ),
              )
            : null,
        selected: ativo,
        selectedTileColor: corPrimaria.withAlpha(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          final router = GoRouter.of(context);
          final fullRoute = tabIndex > 0 ? '$route?tab=$tabIndex' : route;
          final extraData =
              (instituicaoId.isNotEmpty &&
                      (route == '/admin-painel' ||
                          route == '/master-painel'))
                  ? <String, dynamic>{'instituicaoId': instituicaoId}
                  : null;

          if (!isWebMode) {        
            Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (extraData != null) {
                router.go(fullRoute, extra: extraData);
              } else {
                router.go(fullRoute);
              }
            });
          } else {
            if (extraData != null) {
              context.go(fullRoute, extra: extraData);
            } else {
              context.go(fullRoute);
            }
          }
        },
      ),
    );
  }
}
