import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/organisms/menu_lateral_organism.dart';
import 'package:rumo_quiz/shared/widgets/organisms/carrossel_patrocinadores.dart';
import 'package:rumo_quiz/features/auth/presentation/providers/white_label_notifier.dart';

class MainLayoutShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayoutShell({super.key, required this.child});

  @override
  ConsumerState<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends ConsumerState<MainLayoutShell> {
  bool _menuWebExpandido = true;

  Color _converterHexParaCor(String? hex) {
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
    final usuarioAsync = ref.watch(usuarioStreamProvider);

    if (usuarioAsync.isLoading && !usuarioAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dadosUsuario = usuarioAsync.value;

    if (dadosUsuario == null && !usuarioAsync.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final estadoWhiteLabel = ref.watch(whiteLabelProvider);

    final String avatar = dadosUsuario?['avatarEmoji'] ?? '👨‍🎓';
    final String nomeUsuario = dadosUsuario?['nome'] ?? 'Usuário';
    final String tipoAcesso = (dadosUsuario?['role'] ?? 'Acess3')
        .toString()
        .trim();

    String? corHexDoBanco;
    String? logoDoBanco;
    List<String> patrocinadoresBrutos = [];

    if (estadoWhiteLabel != null) {
      try {
        corHexDoBanco = estadoWhiteLabel.toString().contains('corPrimariaHex')
            ? (estadoWhiteLabel as dynamic).corPrimariaHex
            : (estadoWhiteLabel as dynamic).primaryColorHex;

        logoDoBanco = estadoWhiteLabel.toString().contains('logoUrl')
            ? (estadoWhiteLabel as dynamic).logoUrl
            : (estadoWhiteLabel as dynamic).logo;

        final listaExtraida =
            estadoWhiteLabel.toString().contains('patrocinadores')
            ? (estadoWhiteLabel as dynamic).patrocinadores
            : [];
        patrocinadoresBrutos = List<String>.from(listaExtraida ?? []);
      } catch (_) {}
    }

    final String instituicaoNome = dadosUsuario?['instituicao'] ?? 'Rumo Quiz';
    final String? logoInstituicao =
        logoDoBanco ?? dadosUsuario?['logoInstituicao'];
    final List<String> patrocinadoresUrls = patrocinadoresBrutos
        .take(5)
        .toList();

    final bool isMaster = tipoAcesso.toLowerCase() == 'master';
    final Color corPrimaria = isMaster
        ? Colors.purple.shade800
        : _converterHexParaCor(
            corHexDoBanco ?? dadosUsuario?['corCustomizada'],
          );

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
                    tooltip: _menuWebExpandido
                        ? 'Recolher Menu'
                        : 'Expandir Menu',
                    onPressed: () =>
                        setState(() => _menuWebExpandido = !_menuWebExpandido),
                  )
                : null,
            title: isWeb
                ? Row(
                    children: [
                      if (logoInstituicao != null &&
                          logoInstituicao.isNotEmpty &&
                          !isMaster) ...[
                        Image.network(
                          logoInstituicao,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.school_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ] else ...[
                        Icon(
                          isMaster
                              ? Icons.admin_panel_settings_outlined
                              : Icons.school_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          isMaster
                              ? 'Rumo Quiz — Ecossistema Master'
                              : instituicaoNome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text(
                    isMaster ? 'Painel Corporativo' : nomeUsuario,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isMaster ? 'Diretor Master' : tipoAcesso,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
              IconButton(
                icon: const Icon(Icons.logout_outlined, color: Colors.white),
                tooltip: 'Sair do Sistema',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          // 🛠️ CORREÇÃO AQUI: Se for Web, limitamos a altura interna do corpo para forçar o Scaffold
          // a manter o espaço do bottomNavigationBar visível na janela do navegador.
          body: SizedBox(
            height: constraints.maxHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // Força os filhos a respeitarem o limite vertical
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
                if (isWeb)
                  VerticalDivider(width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: ClipRect(
                    // Impede transbordo visual de sub-listas longas sobre o rodapé
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CarrosselPatrocinadores(
            logosUrls: patrocinadoresUrls,
            corCustomizadaInstituicao: corPrimaria,
          ),
        );
      },
    );
  }
}
