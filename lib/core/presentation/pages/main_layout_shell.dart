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
  Map<String, dynamic>? _dadosUsuario;
  bool _carregandoUsuario = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuarioUmaVez(); // 🛡️ Substituído snapshots() por leitura única
  }

  /// 💰 PROTEÇÃO DO PLANO GRATUITO: Faz um único get() e guarda em cache local
  Future<void> _carregarDadosUsuarioUmaVez() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (mounted && doc.exists) {
        setState(() {
          _dadosUsuario = doc.data();
          _carregandoUsuario = false;
        });
      } else {
        if (mounted) setState(() => _carregandoUsuario = false);
      }
    } catch (e) {
      debugPrint('Erro ao ler usuário: $e');
      if (mounted) setState(() => _carregandoUsuario = false);
    }
  }

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
    if (_carregandoUsuario) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🎨 SUBTAREFA 2.2: Lendo dados dinâmicos do Estado Global White Label (Riverpod)
    final estadoWhiteLabel = ref.watch(whiteLabelProvider);

    final String avatar = _dadosUsuario?['avatarEmoji'] ?? '👨‍🎓';
    final String nomeAluno = _dadosUsuario?['nome'] ?? 'Estudante';
    final String tipoAcesso = (_dadosUsuario?['role'] ?? 'Acesso')
        .toString()
        .trim();

    // Captura segura de propriedades vindas do Provider Global White Label
    String? corHexDoBanco;
    String? logoDoBanco;
    List<String> patrocinadoresBrutos = [];

    if (estadoWhiteLabel != null) {
      try {
        // Mapeia de forma flexível dependendo de como as propriedades estão nomeadas no seu modelo
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
    final String iNstituicaoNome = _dadosUsuario?['instituicao'] ?? 'Rumo Quiz';
    final String? logoInstituicao =
        logoDoBanco ?? _dadosUsuario?['logoInstituicao'];

    // 🛡️ TRAVA DE SEGURANÇA: Limitado a no máximo 5 itens com Fallback para lista vazia (controlada pelo carrossel)
    final List<String> patrocinadoresUrls = patrocinadoresBrutos
        .take(5)
        .toList();

    final Color corPrimaria = (tipoAcesso == 'Admin')
        ? Colors.indigo.shade50
        : _converterHexParaCor(
            corHexDoBanco ?? _dadosUsuario?['corCustomizada'],
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
                  avatarEmoji: avatar,
                  nomeAluno: nomeAluno,
                ),
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
                  child: MenuLateralOrganism(
                    isWebMode: true,
                    isExpanded: _menuWebExpandido,
                    avatarEmoji: avatar,
                    nomeAluno: nomeAluno,
                  ),
                ),
              if (isWeb) VerticalDivider(width: 1, color: Colors.grey.shade300),
              Expanded(child: widget.child),
            ],
          ),
          bottomNavigationBar: CarrosselPatrocinadores(
            logosUrls:
                patrocinadoresUrls, // Injeta a lista blindada de até 5 itens
            corCustomizadaInstituicao: corPrimaria,
          ),
        );
      },
    );
  }
}
