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
  Map<String, dynamic>? _dadosUsuario;
  bool _carregandoUsuario = true;
  StreamSubscription<DocumentSnapshot>? _usuarioSubscription;

  @override
  void initState() {
    super.initState();
    _escutarDadosUsuarioTempoReal();
  }

  @override
  void dispose() {
    _usuarioSubscription?.cancel();
    super.dispose();
  }

  void _escutarDadosUsuarioTempoReal() {
    final user = FirebaseAuth.instance.currentUser;
    
    // 🛡️ SEGURANÇA: Se o usuário não estiver autenticado, impede tela vermelha e joga pro login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return;
    }

    // Escuta em tempo real o documento do usuário
    _usuarioSubscription = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .snapshots()
        .listen(
      (doc) {
        if (!mounted) return;
        if (doc.exists) {
          setState(() {
            _dadosUsuario = doc.data();
            _carregandoUsuario = false;
          });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Mapeamento seguro com Fallbacks caso as chaves não existam no Firestore
    final String avatar = _dadosUsuario?['avatarEmoji'] ?? '👨‍🎓';
    final String nomeAluno = _dadosUsuario?['nome'] ?? 'Estudante';
    final String iNstituicaoNome = _dadosUsuario?['instituicao'] ?? 'Instituição';
    final String? logoInstituicao = _dadosUsuario?['logoInstituicao'];
    final String tipoAcesso = (_dadosUsuario?['role'] ?? 'Acesso').toString().trim();
    final String? corHex = _dadosUsuario?['corCustomizada'];
    
    // Extração das logos dos patrocinadores cadastradas no documento do usuário/instituição
    final List<String> patrocinadoresUrls = List<String>.from(_dadosUsuario?['patrocinadores'] ?? []);

    final Color corPrimaria = (tipoAcesso == 'Admin')
        ? Colors.indigo.shade50
        : _converterHexParaCor(corHex);

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
            foregroundColor: (tipoAcesso == 'Admin') ? Colors.black87 : Colors.white,
            elevation: 2,
            leading: isWeb
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: _menuWebExpandido ? 'Recolher Menu' : 'Expandir Menu',
                    onPressed: () => setState(() => _menuWebExpandido = !_menuWebExpandido),
                  )
                : null,
            title: Row(
              children: [
                if (logoInstituicao != null && logoInstituicao.isNotEmpty) ...[
                  Image.network(
                    logoInstituicao,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        Icon(Icons.school_outlined, color: (tipoAcesso == 'Admin') ? Colors.black87 : Colors.white),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  Icon(Icons.school_outlined, color: (tipoAcesso == 'Admin') ? Colors.black87 : Colors.white),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    iNstituicaoNome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      tipoAcesso,
                      style: TextStyle(
                        fontSize: 11,
                        color: (tipoAcesso == 'Admin') ? Colors.black54 : Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
              IconButton(
                icon: Icon(Icons.logout_outlined, color: (tipoAcesso == 'Admin') ? Colors.black87 : Colors.white),
                tooltip: 'Sair do Sistema',
                onPressed: () async {
                  _usuarioSubscription?.cancel(); // Cancela o Listener antes do Logout
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
          // Conectamos os dados reais capturados do Firestore diretamente no Rodapé dinâmico
          bottomNavigationBar: CarrosselPatrocinadores(
            logosUrls: patrocinadoresUrls,
            corCustomizadaInstituicao: corPrimaria,
          ),
        );
      },
    );
  }
}