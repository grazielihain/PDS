import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/organisms/menu_lateral_organism.dart';
import 'package:rumo_quiz/shared/widgets/organisms/carrossel_patrocinadores.dart';

class MainLayoutShell extends StatefulWidget {
  final Widget child;

  const MainLayoutShell({super.key, required this.child});

  @override
  State<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends State<MainLayoutShell> {
  bool _menuWebExpandido = true;

  // Variáveis para guardar os dados do usuário em memória (Otimização Anti-Leitura)
  Map<String, dynamic>? _dadosUsuario;
  bool _carregandoUsuario = true;

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuarioUnicaVez();
  }

  // 🎯 ESTRATÉGIA PLANO GRÁTIS: Busca os dados apenas uma vez ao entrar no App
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
            _carregandoUsuario = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do usuário: $e');
    }
    setState(() => _carregandoUsuario = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoUsuario) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Mapeamento dos dados cacheados em memória
    final String avatar = _dadosUsuario?['avatarEmoji'] ?? '🐱';
    final String nomeAluno = _dadosUsuario?['nome'] ?? 'Estudante';
    final String instituicao =
        _dadosUsuario?['instituicao'] ?? 'Instituição não informada';
    final String tipoAcesso = _dadosUsuario?['role'] ?? 'Estudante';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 900;

        return Scaffold(
          drawer: isWeb
              ? null
              : MenuLateralOrganism(
                  isWebMode: false,
                  avatarEmoji: avatar,
                  nomeAluno: nomeAluno,
                ),
          appBar: AppBar(
            backgroundColor: Colors.blue.shade700,
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
            title: Row(
              children: [
                const Icon(Icons.school_outlined, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Rumo Quiz',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.business,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          instituicao,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
          body: Row(
            children: [
              if (isWeb) ...[
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
                VerticalDivider(width: 1, color: Colors.grey.shade300),
              ],

              // 📺 CONTEÚDO PRINCIPAL VOLTOU AO ORIGINAL
              // Mantendo apenas o widget.child puro para evitar empilhamentos que quebram layouts filhos
              Expanded(child: widget.child),
            ],
          ),

          // 🟢 SOLUÇÃO DEFINITIVA: Injetado na propriedade nativa de navegação inferior do Scaffold pai
          bottomNavigationBar: const CarrosselPatrocinadores(
            logosUrls:
                [], // Vazio para testar se ele vai injetar o Rumo Quiz e a Instituição automaticamente
            corCustomizadaInstituicao:
                null, // No futuro, passe a cor vinda do seu Firebase aqui!
          ),
        );
      },
    );
  }
}
