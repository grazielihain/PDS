import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rumo_quiz/features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/organisms/menu_lateral_organism.dart';
import 'package:rumo_quiz/shared/widgets/organisms/carrossel_patrocinadores.dart';
import 'package:rumo_quiz/features/auth/presentation/providers/white_label_notifier.dart';
import '../../router/app_router.dart';

class MainLayoutShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayoutShell({super.key, required this.child});

  @override
  ConsumerState<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends ConsumerState<MainLayoutShell> {
  bool _menuWebExpandido = true;
  static const Color corLilasMaster = Color(0xFF9C27B0);

  Color _converterHexParaColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blue.shade700;
    try {
      final hexLimpo = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexLimpo', radix: 16));
    } catch (e) {
      return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAsync = ref.watch(userProfileProvider);
    final estadoWhiteLabel = ref.watch(whiteLabelProvider);

    // Tratamento de estados assíncronos da sessão do usuário de forma segura
    return usuarioAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => const Scaffold(body: Center(child: Text('Erro ao carregar sessão.'))),
      data: (dadosUsuario) {
        if (dadosUsuario == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/login');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final String avatar = dadosUsuario['avatar'] ?? dadosUsuario['avatarEmoji'] ?? '';
        final String nomeUsuario = dadosUsuario['nome'] ?? 'Usuário Master';
        final String tipoAcesso = (dadosUsuario['role'] ?? 'Master').toString().trim();

        // Tipagem estrita vinda do WhiteLabelState blindado (Sem dynamic perigoso)
        String? corHexDoBanco = estadoWhiteLabel?.corPrimariaHex;
        String? logoDoBanco = estadoWhiteLabel?.logoUrlDoBanco;
        List<String> patrocinadoresBrutos = estadoWhiteLabel?.patrocinadores ?? [];

        final String instituicaoNome = (tipoAcesso.toLowerCase() == 'master')
            ? 'Rumo Quiz Ecossistema'
            : (dadosUsuario['instituicao'] ?? 'Rumo Quiz');

        final String? logoInstituicao = logoDoBanco ?? dadosUsuario['logoInstituicao'];
        final List<String> patrocinadoresUrls = patrocinadoresBrutos.take(5).toList();

        final Color corPrimaria = (tipoAcesso.toLowerCase() == 'master')
            ? corLilasMaster
            : _converterHexParaColor(corHexDoBanco ?? dadosUsuario['corCustomizada']);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWeb = constraints.maxWidth > 900;
            return Scaffold(
              drawer: isWeb
                  ? null
                  : MenuLateralOrganism(
                      isWebMode: false,
                      isExpanded: true,
                      userName: nomeUsuario,
                      userRole: tipoAcesso,
                      logoInstituicao: logoInstituicao,
                    ),
              appBar: AppBar(
                backgroundColor: corPrimaria,
                foregroundColor: Colors.white,
                elevation: 2,
                leading: isWeb
                    ? IconButton(
                        icon: const Icon(Icons.menu),
                        tooltip: _menuWebExpandido ? 'Recolher Menu' : 'Expandir Menu',
                        onPressed: () => setState(() => _menuWebExpandido = !_menuWebExpandido),
                      )
                    : null,
                title: Text(
                  instituicaoNome,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  if (isWeb) ...[
                    Text(avatar, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeUsuario,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          tipoAcesso,
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    icon: const Icon(Icons.logout_outlined, color: Colors.white),
                    tooltip: 'Sair do Sistema',
                    onPressed: () async {
                      // Deslogar via Provider especializado (Inversão de Dependência)
                      await ref.read(authDataSourceProvider).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Row(
                children: [
                  if (isWeb)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _menuWebExpandido ? 260 : 70,
                      child: MenuLateralOrganism(
                        isWebMode: true,
                        isExpanded: _menuWebExpandido,
                        userName: nomeUsuario,
                        userRole: tipoAcesso,
                        logoInstituicao: logoInstituicao,
                      ),
                    ),
                  if (isWeb) VerticalDivider(width: 1, color: Colors.grey.shade300),
                  Expanded(child: widget.child),
                ],
              ),
              bottomNavigationBar: CarrosselPatrocinadores(
                logosUrls: patrocinadoresUrls,
                corCustomizadaInstituicao: corPrimaria,
              ),
            );
          },
        );
      },
    );
  }
}