import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/white_label_notifier.dart';

class LandingPage extends ConsumerStatefulWidget {
  final int initialTab;
  const LandingPage({super.key, this.initialTab = 0});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _ocultarSenha = true;
  bool _carregando = false;

  // ── Paleta Rumo Quiz (verde-teal + laranja) ────────────────────────────────
  static const _verdePrimario = Color(0xFF0A3D34); // verde escuro base
  static const _verdeAqua = Color(0xFF2D9C8B);     // verde aqua médio
  static const _menta = Color(0xFF82C9BF);          // menta claro
  static const _laranja = Color(0xFFE8831A);        // laranja quente
  static const _pessego = Color(0xFFF0C4A0);        // pêssego pastel
  static const _verdeBg = Color(0xFFE8F5F2);        // fundo verde suave
  static const _laranjaBg = Color(0xFFFFF4EA);      // fundo laranja suave
  static const _cremeBg = Color(0xFFFBFDF8);        // fundo creme
  static const _whatsapp = Color(0xFF25D366);

  // ── Dados de contato ───────────────────────────────────────────────────────
  static const _email = 'rumoquiz@gmail.com';
  static const _whatsappNumero = '+55 (51) 9 9330-9135';
  // ────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  void _copiar(String texto, String label) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado!'),
        duration: const Duration(seconds: 2),
        backgroundColor: _verdeAqua,
      ),
    );
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      final userModel = await ref
          .read(authDataSourceProvider)
          .loginWithEmailAndPassword(
            _emailCtrl.text.trim(),
            _senhaCtrl.text.trim(),
          );
      await ref
          .read(whiteLabelProvider.notifier)
          .inicializarIdentidade(userModel.institutionId, '');
      if (!mounted) return;
      final role = userModel.role.toLowerCase().trim();
      if (role == 'master') {
        context.go('/master-painel');
      } else if (role == 'admin' || role == 'acess2') {
        context.go('/admin', extra: {'instituicaoId': userModel.institutionId});
      } else {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();
          final isPrimeiro = doc.data()?['primeiroLogin'] as bool? ?? false;
          if (isPrimeiro && mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Bem-vindo(a)!'),
                content: const Text(
                  'Este é o seu primeiro acesso.\n\nPor segurança, recomendamos '
                  'que você altere sua senha em "Meu Perfil" assim que possível.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uid)
                .update({'primeiroLogin': false});
          }
        }
        if (mounted) context.go('/quiz-selection');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarModalRecuperarSenha() {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar Senha'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Digite seu e-mail cadastrado. Enviaremos um link para redefinir sua senha.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Insira seu e-mail' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref
                    .read(authNotifierProvider.notifier)
                    .recuperarSenha(emailCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link de recuperação enviado!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cremeBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/images/logo_rumo_quiz.png',
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz, color: _verdePrimario, size: 28),
              SizedBox(width: 8),
              Text(
                'Rumo Quiz',
                style: TextStyle(
                  color: _verdePrimario,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _laranja,
          indicatorWeight: 3,
          labelColor: _verdePrimario,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined, size: 18), text: 'Início'),
            Tab(icon: Icon(Icons.login_outlined, size: 18), text: 'Acessar'),
            Tab(
              icon: Icon(Icons.contact_support_outlined, size: 18),
              text: 'Contato',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInicio(),
          _buildLogin(),
          _buildContato(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  ABA INÍCIO
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildInicio() {
    final largura = MediaQuery.of(context).size.width;
    final isMobile = largura < 700;
    final hPad = isMobile ? 24.0 : (largura < 1100 ? 64.0 : 120.0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(isMobile, hPad),
          _buildDispositivosSection(isMobile, hPad),
          _buildComoFunciona(isMobile, hPad),
          _buildRecursos(isMobile, hPad),
          _buildFooter(isMobile),
        ],
      ),
    );
  }

  // ── HERO ────────────────────────────────────────────────────────────────────

  Widget _buildHero(bool isMobile, double hPad) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_verdePrimario, _verdeAqua],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 72),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo_rumo_quiz.png',
            height: isMobile ? 80 : 110,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.quiz, size: 90, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            'Plataforma de Simulados Educacionais',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 24 : 38,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'Prepare sua instituição para o sucesso. Questões personalizadas, '
              'gamificação e acompanhamento de desempenho — tudo em um só lugar, '
              'na web e no mobile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: isMobile ? 15 : 17,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.login),
                label: const Text(
                  'Acessar a Plataforma',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _laranja,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.chat_outlined),
                label: const Text(
                  'Fale Conosco',
                  style: TextStyle(fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          // badges web + mobile
          Wrap(
            spacing: 24,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildBadge(Icons.computer_outlined, 'Acesso Web'),
              _buildBadge(Icons.phone_android_outlined, 'App Mobile'),
              _buildBadge(Icons.palette_outlined, 'White-label'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _pessego, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── SEÇÃO DISPOSITIVOS ───────────────────────────────────────────────────────

  Widget _buildDispositivosSection(bool isMobile, double hPad) {
    return Container(
      color: _cremeBg,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 72),
      child: Column(
        children: [
          const Text(
            'Disponível na Web e no Mobile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _verdePrimario,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Acesse de qualquer dispositivo, sem configuração adicional.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 48),
          isMobile
              ? Column(
                  children: [
                    _buildDispositivoCard(
                      icone: Icons.computer_outlined,
                      titulo: 'Navegador Web',
                      descricao:
                          'Acesse diretamente pelo navegador, sem instalação. '
                          'Interface adaptada para telas grandes com painel completo.',
                      cor: _verdeAqua,
                      mockup: _buildBrowserMockup(_screenshot('assets/images/screenshot_home_estudante.png', _buildDashboardMockupContent())),
                    ),
                    const SizedBox(height: 32),
                    _buildDispositivoCard(
                      icone: Icons.phone_android_outlined,
                      titulo: 'App Mobile',
                      descricao:
                          'Interface otimizada para smartphones. '
                          'Realize simulados onde estiver, de forma rápida e prática.',
                      cor: _laranja,
                      mockup: _buildPhoneMockup(_screenshot('assets/images/screenshot_mobile_quiz.png', _buildQuizMockupContent())),
                    ),
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildDispositivoCard(
                          icone: Icons.computer_outlined,
                          titulo: 'Navegador Web',
                          descricao:
                              'Acesse diretamente pelo navegador, sem instalação. '
                              'Interface adaptada para telas grandes com painel completo.',
                          cor: _verdeAqua,
                          mockup:
                              _buildBrowserMockup(_screenshot('assets/images/screenshot_home_estudante.png', _buildDashboardMockupContent())),
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _buildDispositivoCard(
                          icone: Icons.phone_android_outlined,
                          titulo: 'App Mobile',
                          descricao:
                              'Interface otimizada para smartphones. '
                              'Realize simulados onde estiver, de forma rápida e prática.',
                          cor: _laranja,
                          mockup: _buildPhoneMockup(_screenshot('assets/images/screenshot_mobile_quiz.png', _buildQuizMockupContent())),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDispositivoCard({
    required IconData icone,
    required String titulo,
    required String descricao,
    required Color cor,
    required Widget mockup,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: cor.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _verdePrimario,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          mockup,
        ],
      ),
    );
  }

  // ── COMO FUNCIONA ────────────────────────────────────────────────────────────

  Widget _buildComoFunciona(bool isMobile, double hPad) {
    return Column(
      children: [
        Container(
          color: _verdeBg,
          padding: EdgeInsets.fromLTRB(hPad, 64, hPad, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Como Funciona',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _verdePrimario,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Três etapas para transformar o aprendizado da sua instituição.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
            ],
          ),
        ),
        _buildPassoSection(
          numero: 1,
          titulo: 'Configuração Administrativa',
          descricao:
              'O administrador cadastra categorias de questões, cria o banco de '
              'perguntas personalizado para a instituição e configura as regras '
              'de pontuação e gamificação.',
          bgColor: _verdeBg,
          hPad: hPad,
          isMobile: isMobile,
          mockup: _buildBrowserMockup(_screenshot('assets/images/screenshot_admin_categorias.png', _buildAdminMockupContent())),
          mockupNaDireita: true,
        ),
        _buildPassoSection(
          numero: 2,
          titulo: 'Realização do Simulado',
          descricao:
              'O aluno acessa pelo celular ou navegador, escolhe a categoria e '
              'responde as questões dentro do tempo determinado. A interface é '
              'intuitiva e funciona perfeitamente em qualquer dispositivo.',
          bgColor: _laranjaBg,
          hPad: hPad,
          isMobile: isMobile,
          mockup: _buildPhoneMockup(_screenshot('assets/images/screenshot_mobile_quiz.png', _buildQuizMockupContent())),
          mockupNaDireita: false,
        ),
        _buildPassoSection(
          numero: 3,
          titulo: 'Resultado e Evolução',
          descricao:
              'Ao finalizar, o aluno recebe o resultado detalhado com acertos, '
              'erros e pontuação acumulada. O histórico completo fica disponível '
              'para acompanhar a evolução ao longo do tempo.',
          bgColor: _verdeBg,
          hPad: hPad,
          isMobile: isMobile,
          mockup: _buildBrowserMockup(_screenshot('assets/images/screenshot_resultado_simulado.png', _buildResultadoMockupContent())),
          mockupNaDireita: true,
        ),
      ],
    );
  }

  Widget _buildPassoSection({
    required int numero,
    required String titulo,
    required String descricao,
    required Color bgColor,
    required double hPad,
    required bool isMobile,
    required Widget mockup,
    required bool mockupNaDireita,
  }) {
    final textPart = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _laranja,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              '$numero',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: _verdePrimario,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          descricao,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
            height: 1.75,
          ),
        ),
      ],
    );

    final mockupPart = Center(child: mockup);

    return Container(
      color: bgColor,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 60),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textPart,
                const SizedBox(height: 40),
                mockupPart,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: mockupNaDireita
                  ? [
                      Expanded(child: textPart),
                      const SizedBox(width: 64),
                      Expanded(child: mockupPart),
                    ]
                  : [
                      Expanded(child: mockupPart),
                      const SizedBox(width: 64),
                      Expanded(child: textPart),
                    ],
            ),
    );
  }

  // ── RECURSOS ─────────────────────────────────────────────────────────────────

  Widget _buildRecursos(bool isMobile, double hPad) {
    return Container(
      color: _verdePrimario,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Por que usar o Rumo Quiz?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recursos pensados para gestores, professores e alunos.',
            style: TextStyle(color: _menta, fontSize: 15),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 28,
            runSpacing: 20,
            children: [
              _buildRecursoItem(
                Icons.category_outlined,
                'Questões personalizadas por categoria e assunto',
              ),
              _buildRecursoItem(
                Icons.stars_outlined,
                'Gamificação com pontuação e ranking',
              ),
              _buildRecursoItem(
                Icons.history_outlined,
                'Histórico completo de simulados realizados',
              ),
              _buildRecursoItem(
                Icons.devices_outlined,
                'Web e mobile — sem instalação',
              ),
              _buildRecursoItem(
                Icons.palette_outlined,
                'Identidade visual personalizada (white-label)',
              ),
              _buildRecursoItem(
                Icons.analytics_outlined,
                'Painel administrativo com indicadores',
              ),
              _buildRecursoItem(
                Icons.people_outline,
                'Gestão completa de usuários e acessos',
              ),
              _buildRecursoItem(
                Icons.message_outlined,
                'Mensagens motivacionais ao fim do simulado',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecursoItem(IconData icone, String texto) {
    return SizedBox(
      width: 290,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _laranja.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: _pessego, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SCREENSHOT HELPER ────────────────────────────────────────────────────────
  // Tenta carregar asset real; usa widget Flutter como fallback se não encontrar.
  Widget _screenshot(String assetPath, Widget fallback) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  // ── FOOTER ────────────────────────────────────────────────────────────────────

  Widget _buildFooter(bool isMobile) {
    return Container(
      color: const Color(0xFF061F1A),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo_rumo_quiz_sem_slogan.png',
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'Rumo Quiz',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => _tabController.animateTo(0),
                child: Text(
                  'Início',
                  style: TextStyle(color: _menta.withAlpha(200)),
                ),
              ),
              Text('•', style: TextStyle(color: Colors.white.withAlpha(60))),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text(
                  'Acessar',
                  style: TextStyle(color: _menta.withAlpha(200)),
                ),
              ),
              Text('•', style: TextStyle(color: Colors.white.withAlpha(60))),
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: Text(
                  'Contato',
                  style: TextStyle(color: _menta.withAlpha(200)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} Rumo Quiz — Todos os direitos reservados.',
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  DEVICE MOCKUPS — FRAME
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildBrowserMockup(Widget content) {
    return Container(
      width: 480,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Chrome do navegador
          Container(
            height: 32,
            color: const Color(0xFFF0F0F0),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F57)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF28C840)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'rumoquiz.com.br',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildPhoneMockup(Widget content) {
    return Container(
      width: 189,
      height: 396,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(29),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 12, 7, 8),
        child: Column(
          children: [
            // Notch
            Container(
              width: 60,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D1A),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => CircleAvatar(radius: 4, backgroundColor: color);

  // ══════════════════════════════════════════════════════════════════════════════
  //  DEVICE MOCKUPS — CONTEÚDO (mini UI da aplicação)
  // ══════════════════════════════════════════════════════════════════════════════

  // Dashboard do aluno (para seção dispositivos)
  Widget _buildDashboardMockupContent() {
    return Container(
      color: const Color(0xFFF4FAF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            color: _verdePrimario,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.quiz, size: 8, color: Colors.white),
                const SizedBox(width: 4),
                const Text(
                  'Rumo Quiz',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.person_outline, size: 8, color: Colors.white),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Olá, Estudante!',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: _verdePrimario,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _miniMetricCard('12', 'Simulados', _verdeAqua),
                    const SizedBox(width: 4),
                    _miniMetricCard('87%', 'Acertos', _laranja),
                    const SizedBox(width: 4),
                    _miniMetricCard('340', 'Pontos', _menta),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Categorias',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: _verdePrimario,
                  ),
                ),
                const SizedBox(height: 3),
                _miniCatRow(Icons.calculate_outlined, 'Matemática', 0.7),
                const SizedBox(height: 2),
                _miniCatRow(Icons.language_outlined, 'Português', 0.5),
                const SizedBox(height: 2),
                _miniCatRow(Icons.history_edu_outlined, 'História', 0.85),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Painel admin — configuração (passo 1)
  Widget _buildAdminMockupContent() {
    return Container(
      color: const Color(0xFFF4FAF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            color: _verdePrimario,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Row(
              children: [
                Icon(Icons.settings, size: 8, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Painel Admin',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Categorias',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: _verdePrimario,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _laranja,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '+ Nova',
                        style: TextStyle(fontSize: 6, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                _adminCatRow(Icons.calculate_outlined, 'Matemática', '45 questões', Colors.blue.shade300),
                const SizedBox(height: 3),
                _adminCatRow(Icons.language_outlined, 'Português', '38 questões', Colors.green.shade300),
                const SizedBox(height: 3),
                _adminCatRow(Icons.history_edu_outlined, 'História', '29 questões', Colors.orange.shade300),
                const SizedBox(height: 3),
                _adminCatRow(Icons.science_outlined, 'Ciências', '21 questões', Colors.purple.shade300),
                const SizedBox(height: 6),
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 8, color: Colors.grey),
                    const SizedBox(width: 3),
                    const Text(
                      '48 usuários cadastrados',
                      style: TextStyle(fontSize: 6, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quiz — realização do simulado (passo 2 / seção mobile)
  Widget _buildQuizMockupContent() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            color: _verdeAqua,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Simulado • 3/10',
                      style: TextStyle(
                        fontSize: 7,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.timer_outlined, size: 8, color: Colors.white),
                    const SizedBox(width: 2),
                    const Text(
                      '4:32',
                      style: TextStyle(fontSize: 7, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 0.3,
                    minHeight: 4,
                    backgroundColor: Colors.white.withAlpha(60),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Qual é a capital do Brasil?',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: _verdePrimario,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 7),
                _quizOption('São Paulo', false),
                const SizedBox(height: 3),
                _quizOption('Brasília', true),
                const SizedBox(height: 3),
                _quizOption('Rio de Janeiro', false),
                const SizedBox(height: 3),
                _quizOption('Belo Horizonte', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Resultado do simulado (passo 3)
  Widget _buildResultadoMockupContent() {
    return Container(
      color: const Color(0xFFF4FAF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 22,
            color: _verdePrimario,
            child: const Center(
              child: Text(
                'Resultado de Simulado',
                style: TextStyle(
                  fontSize: 7,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 0.8,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(_verdeAqua),
                        ),
                        const Text(
                          '80%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _verdePrimario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _resultBadge('8 acertos', Colors.green.shade400),
                      const SizedBox(width: 6),
                      _resultBadge('2 erros', Colors.red.shade300),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars, size: 10, color: _laranja),
                      const SizedBox(width: 3),
                      const Text(
                        '+120 pontos',
                        style: TextStyle(
                          fontSize: 8,
                          color: _laranja,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _verdeAqua,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Ver revisão completa',
                      style: TextStyle(fontSize: 7, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mini helpers para os mockups ─────────────────────────────────────────────

  Widget _miniMetricCard(String valor, String label, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: cor.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniCatRow(IconData icon, String label, double progress) {
    return Row(
      children: [
        Icon(icon, size: 8, color: _verdeAqua),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 6)),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(_verdeAqua),
            ),
          ),
        ),
      ],
    );
  }

  Widget _adminCatRow(IconData icon, String label, String count, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 8, color: cor),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 7)),
          const Spacer(),
          Text(count, style: const TextStyle(fontSize: 6, color: Colors.grey)),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right, size: 8, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _quizOption(String texto, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? _verdeAqua.withAlpha(40) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? _verdeAqua : Colors.grey.shade200,
          width: selected ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? _verdeAqua : Colors.grey.shade400,
                width: 0.8,
              ),
              color: selected ? _verdeAqua : Colors.transparent,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontSize: 7,
              color: selected ? _verdeAqua : Colors.grey.shade700,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBadge(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withAlpha(30),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 7,
          color: cor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  ABA ACESSAR (LOGIN)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_rumo_quiz.png',
                height: 90,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.school, size: 70, color: _verdePrimario),
              ),
              const SizedBox(height: 28),
              const Text(
                'Acesse sua conta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _verdePrimario,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entre com o e-mail e senha cadastrados pela sua instituição.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 36),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Insira seu e-mail' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaCtrl,
                      obscureText: _ocultarSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarSenha
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _ocultarSenha = !_ocultarSenha,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Insira sua senha' : null,
                      onFieldSubmitted: (_) => _fazerLogin(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _mostrarModalRecuperarSenha,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _carregando
                          ? const Center(
                              key: ValueKey('loading'),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: CircularProgressIndicator(
                                  color: _verdeAqua,
                                ),
                              ),
                            )
                          : FilledButton(
                              key: const ValueKey('btn'),
                              onPressed: _fazerLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: _verdePrimario,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Entrar',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  ABA CONTATO
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildContato() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Entre em contato',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _verdePrimario,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Para suporte técnico, parcerias ou mais informações sobre a '
                'plataforma Rumo Quiz, utilize os canais abaixo.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 48),
              _buildContatoCard(
                icone: Icons.email_outlined,
                titulo: 'E-mail',
                valor: _email,
                cor: _verdeAqua,
                onCopiar: () => _copiar(_email, 'E-mail'),
              ),
              const SizedBox(height: 16),
              _buildContatoCard(
                icone: Icons.chat_outlined,
                titulo: 'WhatsApp',
                valor: _whatsappNumero,
                cor: _whatsapp,
                onCopiar: () => _copiar(_whatsappNumero, 'Número'),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _verdeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _menta.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      color: _verdeAqua,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Atendimento: Segunda a Sexta, das 9h às 18h',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'O Rumo Quiz é uma plataforma white-label. Entre em contato '
                      'para conhecer os planos e implantar na sua instituição.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContatoCard({
    required IconData icone,
    required String titulo,
    required String valor,
    required Color cor,
    required VoidCallback onCopiar,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: cor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Copiar',
            child: IconButton(
              onPressed: onCopiar,
              icon: const Icon(Icons.copy_outlined, size: 20),
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
