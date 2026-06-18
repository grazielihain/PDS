import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 📦 Injetado Riverpod
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/organisms/menu_lateral_organism.dart';
import 'package:rumo_quiz/shared/widgets/organisms/carrossel_patrocinadores.dart';
// 🔥 Importamos o provedor White Label para usar o cache de memória gratuito
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
    // ✨ ESCUTA EM TEMPO REAL: Monitora o canal de dados do usuário
    final usuarioAsync = ref.watch(usuarioStreamProvider);

    // Exibe o carregamento inicial caso os dados ainda estejam vindo do Firestore
    if (usuarioAsync.isLoading && !usuarioAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🛡️ CAST CORRIGIDO: Garante ao Dart que o retorno é um mapa válido
    final dadosUsuario = usuarioAsync.value as Map<String, dynamic>?;

    // Redireciona de forma segura caso o estado seja nulo (deslogado)
    if (dadosUsuario == null && !usuarioAsync.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🎨 SUBTAREFA 2.2: Lendo dados dinâmicos do Estado Global White Label (Riverpod)
    final estadoWhiteLabel = ref.watch(whiteLabelProvider);

    // 🛡️ ACESSO VIA MAPA: Sincronizado dinamicamente
    final String avatar = dadosUsuario?['avatarEmoji'] ?? '👨‍🎓';
    final String nomeAluno = dadosUsuario?['nome'] ?? 'Estudante';
    final String tipoAcesso = (dadosUsuario?['role'] ?? 'Acesso')
        .toString()
        .trim();

    // Captura segura de propriedades vindas do Provider Global White Label
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

    // Fallbacks visuais automáticos pedidos na especificação técnica
    final String iNstituicaoNome = dadosUsuario?['instituicao'] ?? 'Rumo Quiz';
    final String? logoInstituicao =
        logoDoBanco ?? dadosUsuario?['logoInstituicao'];

    // 🛡️ TRAVA DE SEGURANÇA: Limitado a no máximo 5 itens com Fallback para lista vazia
    final List<String> patrocinadoresUrls = patrocinadoresBrutos
        .take(5)
        .toList();

    final Color corPrimaria = (tipoAcesso == 'Admin')
        ? Colors.indigo.shade50
        : _converterHexParaCor(
            corHexDoBanco ?? dadosUsuario?['corCustomizada'],
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 900;

        return Scaffold(
          drawer: isWeb
              ? null
              : const MenuLateralOrganism(isWebMode: false, isExpanded: true),
          appBar: AppBar(
            backgroundColor: corPrimaria,
            foregroundColor: (tipoAcesso == 'Admin')
                ? Colors.black87
                : Colors.white,
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
            title: Row(
              children: [
                if (logoInstituicao != null && logoInstituicao.isNotEmpty) ...[
                  Image.network(
                    logoInstituicao,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Icon(
                      Icons.school_outlined,
                      color: (tipoAcesso == 'Admin')
                          ? Colors.black87
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  Icon(
                    Icons.school_outlined,
                    color: (tipoAcesso == 'Admin')
                        ? Colors.black87
                        : Colors.white,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    iNstituicaoNome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
                      nomeAluno,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tipoAcesso,
                      style: TextStyle(
                        fontSize: 11,
                        color: (tipoAcesso == 'Admin')
                            ? Colors.black54
                            : Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
              IconButton(
                icon: Icon(
                  Icons.logout_outlined,
                  color: (tipoAcesso == 'Admin')
                      ? Colors.black87
                      : Colors.white,
                ),
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
          body: Row(
            children: [
              if (isWeb)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _menuWebExpandido ? 260 : 70,
                  // 🛡️ CORRIGIDO: O prefixo 'const' foi removido aqui para permitir os dados dinâmicos do menu
                  child: MenuLateralOrganism(
                    isWebMode: true,
                    isExpanded: _menuWebExpandido,
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
  }
}
