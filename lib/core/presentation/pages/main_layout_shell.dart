import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/organisms/menu_lateral_organism.dart';
import 'package:rumo_quiz/shared/widgets/organisms/carrossel_patrocinadores.dart';
import 'package:rumo_quiz/core/router/app_router.dart';

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
  bool _dialogPrimeiroAcessoMostrado = false;

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

          // Alimenta o cache de role após o frame atual para evitar rebuild em cascata
          final roleAtual = (dados['role'] ?? 'Acess3').toString().trim();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            UserRoleCache().update(roleAtual);
          });

          // Quando a instituição do usuário mudar, recarrega os dados dela
          final novoId = (dados['instituicaoId'] ?? '').toString();
          if (novoId.isNotEmpty && novoId != _instituicaoIdAtual) {
            _instituicaoIdAtual = novoId;
            _escutarInstituicao(novoId);
          }

          // Primeiro acesso: sugere troca de senha (delay garante que a navegação já concluiu)
          final primeiroAcesso = dados['primeiroAcesso'] as bool? ?? false;
          if (primeiroAcesso && !_dialogPrimeiroAcessoMostrado) {
            _dialogPrimeiroAcessoMostrado = true;
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) _mostrarDialogoPrimeiroAcesso(user.uid);
            });
          }
        } else {
          // Documento removido: conta desativada — forçar logout
          setState(() => _carregandoUsuario = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            UserRoleCache().clear();
            FirebaseAuth.instance.signOut();
            context.go('/login');
          });
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

  Future<void> _mostrarDialogoPrimeiroAcesso(String uid) async {
    Future<void> marcarConcluido() => FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({'primeiroAcesso': false});

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFF1E3A8A)),
            SizedBox(width: 10),
            Text('Bem-vindo ao Rumo Quiz!'),
          ],
        ),
        content: const Text(
          'Esta é sua primeira vez acessando o sistema. '
          'Recomendamos que você altere a senha padrão cadastrada pelo administrador '
          'por uma senha pessoal para maior segurança.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await marcarConcluido();
            },
            child: const Text('Lembrar depois'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await marcarConcluido();
              if (mounted) context.go('/perfil');
            },
            child: const Text('Alterar senha agora'),
          ),
        ],
      ),
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
                if (isWeb) ...[
                  Image.asset(
                    'assets/images/logo_rumo_quiz_sem_slogan.png',
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                      width: 1, height: 28, color: corTextoAppBar.withAlpha(80)),
                  const SizedBox(width: 8),
                ],
                if (tipoAcesso == 'Master') ...[
                  // Master: exibe apenas a marca Rumo Quiz no cabeçalho
                  if (!isWeb)
                    Image.asset(
                      'assets/images/logo_rumo_quiz_sem_slogan.png',
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  if (!isWeb) const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Portal Master',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: corTextoAppBar,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
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
                  UserRoleCache().clear();
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
            logosUrls: tipoAcesso == 'Master' ? const [] : patrocinadoresUrls,
            logoInstituicaoUrl: tipoAcesso == 'Master' ? '' : logoInstituicaoUrl,
            corCustomizadaInstituicao: corPrimaria,
            somenteMarca: tipoAcesso == 'Master',
          ),
        );
      },
    );
  }
}
