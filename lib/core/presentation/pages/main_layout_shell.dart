import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/organisms/menu_lateral_organism.dart';
import 'package:rumo_quiz/shared/widgets/organisms/carrossel_patrocinadores.dart';

class MainLayoutShell extends StatefulWidget {
  final Widget child;
  const MainLayoutShell({super.key, required this.child});

  @override
  State<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends State<MainLayoutShell> {
  bool _menuWebExpandido = true;

  // Dados do usuário logado
  Map<String, dynamic>? _dadosUsuario;
  bool _carregandoUsuario = true;
  StreamSubscription<DocumentSnapshot>? _usuarioSubscription;

  // Dados da instituição vinculada ao usuário
  Map<String, dynamic>? _dadosInstituicao;
  StreamSubscription<DocumentSnapshot>? _instituicaoSubscription;
  String _instituicaoIdAtual = '';

  @override
  void initState() {
    super.initState();
    _escutarDadosUsuarioTempoReal();
  }

  @override
  void dispose() {
    _usuarioSubscription?.cancel();
    _instituicaoSubscription?.cancel();
    super.dispose();
  }

  void _escutarDadosUsuarioTempoReal() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return;
    }

    _usuarioSubscription = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .snapshots()
        .listen(
      (doc) {
        if (!mounted) return;
        if (doc.exists) {
          final dados = doc.data() as Map<String, dynamic>;
          setState(() {
            _dadosUsuario = dados;
            _carregandoUsuario = false;
          });

          // Quando a instituição do usuário mudar, recarrega os dados dela
          final novoId = (dados['instituicaoId'] ?? '').toString();
          if (novoId.isNotEmpty && novoId != _instituicaoIdAtual) {
            _instituicaoIdAtual = novoId;
            _escutarInstituicao(novoId);
          }
        } else {
          setState(() => _carregandoUsuario = false);
        }
      },
      onError: (error) {
        debugPrint('Erro no stream do usuário: $error');
        if (mounted) setState(() => _carregandoUsuario = false);
      },
    );
  }

  void _escutarInstituicao(String instituicaoId) {
    _instituicaoSubscription?.cancel();
    _instituicaoSubscription = FirebaseFirestore.instance
        .collection('instituicoes')
        .doc(instituicaoId)
        .snapshots()
        .listen(
      (doc) {
        if (!mounted) return;
        if (doc.exists) {
          setState(
            () => _dadosInstituicao = doc.data() as Map<String, dynamic>,
          );
        }
      },
      onError: (e) => debugPrint('Erro no stream da instituição: $e'),
    );
  }

  Color _converterHexParaCor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blue.shade700;
    try {
      final hexLimpo = hex.replaceAll('#', '');
      if (hexLimpo.length != 6) return Colors.blue.shade700;
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

    // Dados do usuário
    final String avatar = _dadosUsuario?['avatarEmoji'] ?? '👨‍🎓';
    final String nomeUsuario = _dadosUsuario?['nome'] ?? 'Usuário';
    final String tipoAcesso =
        (_dadosUsuario?['role'] ?? 'Acess3').toString().trim();

    // Dados da instituição (fonte de verdade: coleção 'instituicoes')
    final String nomeInstituicao =
        _dadosInstituicao?['nome'] ?? 'Instituição';
    final String logoInstituicaoUrl =
        (_dadosInstituicao?['logoUrl'] ?? '').toString();
    final String corHex =
        (_dadosInstituicao?['corHexadecimal'] ??
                _dadosInstituicao?['corHex'] ??
                '')
            .toString();
    final List<String> patrocinadoresUrls = List<String>.from(
      _dadosInstituicao?['patrocinadoresUrls'] ??
          _dadosInstituicao?['patrocinios'] ??
          [],
    );

    final Color corPrimaria = tipoAcesso == 'Master'
        ? const Color(0xFF66BB6A)
        : _converterHexParaCor(corHex.isNotEmpty ? corHex : null);

    // Cor do texto baseada no brilho do fundo
    final bool fundoEscuro =
        ThemeData.estimateBrightnessForColor(corPrimaria) == Brightness.dark;
    final Color corTextoAppBar = fundoEscuro ? Colors.white : Colors.black87;

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
                  nomeUsuario: nomeUsuario,
                  tipoAcesso: tipoAcesso,
                  corPrimaria: corPrimaria,
                  instituicaoId: _instituicaoIdAtual,
                  logoInstituicaoUrl: logoInstituicaoUrl,
                ),
          appBar: AppBar(
            backgroundColor: corPrimaria,
            foregroundColor: corTextoAppBar,
            elevation: 2,
            leading: isWeb
                ? IconButton(
                    icon: Icon(Icons.menu, color: corTextoAppBar),
                    tooltip:
                        _menuWebExpandido ? 'Recolher Menu' : 'Expandir Menu',
                    onPressed: () =>
                        setState(() => _menuWebExpandido = !_menuWebExpandido),
                  )
                : null,
            title: Row(
              children: [
                if (logoInstituicaoUrl.isNotEmpty) ...[
                  Image.network(
                    logoInstituicaoUrl,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Icon(
                      Icons.school_outlined,
                      color: corTextoAppBar,
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  Icon(Icons.school_outlined, color: corTextoAppBar),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    nomeInstituicao,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: corTextoAppBar,
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
                      nomeUsuario,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: corTextoAppBar,
                      ),
                    ),
                    Text(
                      tipoAcesso,
                      style: TextStyle(
                        fontSize: 11,
                        color: corTextoAppBar.withAlpha(180),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
              IconButton(
                icon: Icon(Icons.logout_outlined, color: corTextoAppBar),
                tooltip: 'Sair do Sistema',
                onPressed: () async {
                  _usuarioSubscription?.cancel();
                  _instituicaoSubscription?.cancel();
                  await FirebaseAuth.instance.signOut();
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
                    avatarEmoji: avatar,
                    nomeUsuario: nomeUsuario,
                    tipoAcesso: tipoAcesso,
                    corPrimaria: corPrimaria,
                    instituicaoId: _instituicaoIdAtual,
                    logoInstituicaoUrl: logoInstituicaoUrl,
                  ),
                ),
              if (isWeb) VerticalDivider(width: 1, color: Colors.grey.shade300),
              Expanded(child: widget.child),
            ],
          ),
          bottomNavigationBar: CarrosselPatrocinadores(
            logosUrls: patrocinadoresUrls,
            logoInstituicaoUrl: logoInstituicaoUrl,
            corCustomizadaInstituicao: corPrimaria,
          ),
        );
      },
    );
  }
}
