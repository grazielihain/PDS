import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

// Importações dos seus componentes oficiais
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

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuarioUnicaVez();
  }

  Future<void> _buscarDadosUsuarioUnicaVez() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _dadosUsuario = doc.data();
          });
        }
      }
      setState(() => _carregandoUsuario = false);
    } catch (e) {
      debugPrint('Erro ao carregar dados do usuário: $e');
      setState(() => _carregandoUsuario = false);
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

    // Variáveis reais extraídas do documento NoSQL do Firestore
    final String avatar = _dadosUsuario?['avatarEmoji'] ?? '👨‍🎓';
    final String nomeAluno = _dadosUsuario?['nome'] ?? 'Estudante';
    final String instituicao = _dadosUsuario?['instituicao'] ?? 'Instituição';
    final String? logoInstituicao = _dadosUsuario?['logoInstituicao'];
    final String tipoAcesso = (_dadosUsuario?['role'] ?? 'Acess3')
        .toString()
        .trim();
    final String? corHex = _dadosUsuario?['corCustomizada'];

    final Color corPrimaria = (tipoAcesso == 'Admin')
        ? Colors.indigo.shade50
        : _converterHexParaCor(corHex);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Define se a tela está sendo exibida em ambiente Web/Desktop ou Mobile
        final isWeb = constraints.maxWidth > 900;

        return Scaffold(
          // 🍔 1. MENU SANDUÍCHE MOBILE (Aparece em telas menores)
          drawer: isWeb
              ? null
              : MenuLateralOrganism(
                  isWebMode: false,
                  isExpanded: true,
                  avatarEmoji: avatar,
                  nomeAluno: nomeAluno,
                ),

          // 🏷️ 2. CABEÇALHO UNIFICADO E RESPONSIVO (Logo + Nome)
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
                : null, // No celular o Flutter insere o ícone de hambúrguer automaticamente
            title: Row(
              children: [
                if (logoInstituicao != null && logoInstituicao.isNotEmpty) ...[
                  Image.network(
                    logoInstituicao,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.school_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  const Icon(Icons.school_outlined, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    instituicao,
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
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],

              // 🚪 ÍCONE DE SAIR NO LADO DIREITO (FUNCIONANDO)
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

          // 📺 3. CORPO DISTRIBUÍDO (Barra lateral se for Web + Miolo da página correspondente)
          body: Row(
            children: [
              if (isWeb)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _menuWebExpandido
                      ? 260
                      : 70, // Retrai para ícones ao invés de sumir tudo!
                  child: MenuLateralOrganism(
                    isWebMode: true,
                    isExpanded: _menuWebExpandido,
                    avatarEmoji: avatar,
                    nomeAluno: nomeAluno,
                  ),
                ),
              if (isWeb) VerticalDivider(width: 1, color: Colors.grey.shade300),

              // Garante que o miolo da tela se espalhe ocupando todo o restante da janela
              Expanded(child: widget.child),
            ],
          ),

          // 🦶 4. RODAPÉ ORIGINAL DE PATROCINADORES
          bottomNavigationBar: const CarrosselPatrocinadores(),
        );
      },
    );
  }
}
