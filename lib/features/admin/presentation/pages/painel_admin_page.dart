import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';

import '../../../auth/presentation/pages/meu_perfil_page.dart';
import 'tabs/admin_categorias_tab.dart';
import 'tabs/admin_gamificacao_tab.dart';
import 'tabs/admin_mensagens_tab.dart';
import 'tabs/admin_questoes_tab.dart';

class PainelAdminPage extends ConsumerStatefulWidget {
  final String substituicaoInstituicaoId;
  final int initialTab;

  const PainelAdminPage({
    super.key,
    required this.substituicaoInstituicaoId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<PainelAdminPage> createState() => _PainelAdminPageState();
}

class _PainelAdminPageState extends ConsumerState<PainelAdminPage> {
  late PageController _pageController;

  // Getter de compatibilidade — operações de painel que ainda não migraram
  // para AdminRemoteDataSource usam este getter enquanto a refatoração avança.
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Role and loading
  String _roleCriador = '';
  bool _carregando = true;
  Stream<QuerySnapshot>? _auditoriaStream;

  // Painel Administrativo – identidade visual
  final _formKeyIdentidade = GlobalKey<FormState>();
  final _nomeEscolaController = TextEditingController();
  String _corSelecionada = '#1565C0';
  String _logoUrl = '';
  String _mascoteUrl = '';
  List<String> _patrocinadoresUrls = [];
  Uint8List? _logoBytes;
  String _logoNomeArquivo = '';
  Uint8List? _mascoteBytes;
  String _mascoteNomeArquivo = '';
  List<Uint8List> _patrocinadorBytes = [];
  List<String> _patrocinadorNomes = [];
  bool _salvandoIdentidade = false;
  bool _salvandoPatrocinadores = false;

  static const List<Map<String, dynamic>> _coresPredefinidas = [
    {'nome': 'Azul Escuro', 'hex': '#1565C0'},
    {'nome': 'Azul Médio', 'hex': '#1E88E5'},
    {'nome': 'Azul Claro', 'hex': '#42A5F5'},
    {'nome': 'Verde Escuro', 'hex': '#2E7D32'},
    {'nome': 'Verde Médio', 'hex': '#43A047'},
    {'nome': 'Verde Claro', 'hex': '#66BB6A'},
    {'nome': 'Roxo', 'hex': '#6A1B9A'},
    {'nome': 'Roxo Claro', 'hex': '#AB47BC'},
    {'nome': 'Laranja', 'hex': '#E65100'},
    {'nome': 'Laranja Claro', 'hex': '#FFA726'},
    {'nome': 'Vermelho', 'hex': '#C62828'},
    {'nome': 'Cinza Azulado', 'hex': '#37474F'},
  ];

  // Usuários
  final _formKeyUsuario = GlobalKey<FormState>();
  final _nomeUsuarioController = TextEditingController();
  final _emailUsuarioController = TextEditingController();
  final _senhaUsuarioController = TextEditingController();
  String _roleSelecionada = 'Acess3';
  bool _ocultarSenha = true;
  bool _salvandoUsuario = false;
  bool _formularioUsuarioExpandido = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialTab);
    _carregarPerfil();
  }

  @override
  void didUpdateWidget(PainelAdminPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      // jumpToPage bypasses TabBarView's warp logic, which caused a
      // re-entrant _handlePageController → _warpToCurrentIndex loop that
      // left the PageView stuck between the target page and the next one.
      if (_pageController.hasClients) {
        _pageController.jumpToPage(widget.initialTab);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomeEscolaController.dispose();
    _nomeUsuarioController.dispose();
    _emailUsuarioController.dispose();
    _senhaUsuarioController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await _db.collection('usuarios').doc(uid).get();
      final role = (userDoc.data()?['role'] ?? 'Acess2').toString().trim();

      final instDoc = await _db
          .collection('instituicoes')
          .doc(widget.substituicaoInstituicaoId)
          .get();
      final inst = instDoc.data() ?? {};

      final hexArmazenado =
          (inst['corHexadecimal'] ?? inst['corHex'] ?? '#1565C0').toString();
      final corMapeada =
          _coresPredefinidas.any((c) => c['hex'] == hexArmazenado)
              ? hexArmazenado
              : '#1565C0';

      if (!mounted) return;
      setState(() {
        _roleCriador = role;
        _nomeEscolaController.text = inst['nome'] ?? '';
        _corSelecionada = corMapeada;
        _logoUrl = inst['logoUrl'] ?? '';
        _mascoteUrl = inst['mascoteUrl'] ?? '';
        _patrocinadoresUrls = List<String>.from(
          inst['patrocinadoresUrls'] ?? inst['patrocinios'] ?? [],
        );
        _carregando = false;
      });
      _reinicializarController(role);
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _reinicializarController(String role) {
    _auditoriaStream = ref.read(adminDataSourceProvider).streamAuditoria(
      widget.substituicaoInstituicaoId,
    );
    if (mounted) {
      setState(() {});
      // Jump to the requested tab after the PageView is laid out with
      // the correct number of children for this role.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final maxPage = role == 'Admin' ? 8 : 5;
        final target = widget.initialTab.clamp(0, maxPage);
        if (_pageController.hasClients &&
            (_pageController.page?.round() ?? 0) != target) {
          _pageController.jumpToPage(target);
        }
      });
    }
  }

  // ─────────────────────────── AUDITORIA ────────────────────────────────────

  /// Converte o toString() de um Map em linhas legíveis (• chave: valor)
  String _formatarRegistroAuditoria(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final text = raw.trim();
    if (!text.startsWith('{') || !text.endsWith('}')) return text;
    final inner = text.substring(1, text.length - 1);
    final linhas = <String>[];
    for (final parte in inner.split(RegExp(r',\s*(?=[a-zA-Z_])'))) {
      final idx = parte.indexOf(':');
      if (idx < 0) {
        linhas.add(parte.trim());
      } else {
        final chave = parte.substring(0, idx).trim();
        final valor = parte.substring(idx + 1).trim();
        // Omite campos técnicos volumosos
        if ({'revisaoQuestoes', 'imagens', 'alternativas'}.contains(chave)) continue;
        linhas.add('$chave: $valor');
      }
    }
    return linhas.join('\n');
  }

  Future<void> _registrarAuditoria(
    String acao,
    String tela,
    String detalhe,
    String antigo,
    String novo,
  ) async {
    await ref.read(adminDataSourceProvider).registrarAuditoria(
      instituicaoId: widget.substituicaoInstituicaoId,
      acao: acao,
      tela: tela,
      detalhe: detalhe,
      registroAntigo: antigo,
      registroNovo: novo,
    );
  }

  // ─────────────────────────── IMAGEM HELPERS ───────────────────────────────

  Future<void> _selecionarImagem(
      {required void Function(Uint8List, String) onBytes}) async {
    late final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        withData: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir o seletor de arquivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    if (file.bytes!.length > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem muito grande. Máximo: 2MB.')),
        );
      }
      return;
    }
    onBytes(file.bytes!, file.name);
  }

  // Logo e mascote usam path fixo (sobrescreve o arquivo anterior no Storage).
  // Patrocinadores usam timestamp pois múltiplos arquivos coexistem.
  Future<String> _uploadImagem(
      Uint8List bytes, String nome, String pasta) async {
    final ext =
        nome.contains('.') ? nome.split('.').last.toLowerCase() : 'png';
    final isFixo = pasta == 'logo' || pasta == 'mascote';
    final nomeArquivo = isFixo
        ? '$pasta.$ext'
        : '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path =
        'instituicoes/${widget.substituicaoInstituicaoId}/$pasta/$nomeArquivo';
    return ref.read(adminDataSourceProvider).uploadImagem(
          bytes: bytes,
          storagePath: path,
          contentType: 'image/$ext',
        );
  }

  Future<void> _excluirImagem({
    required String tipo,
    required String url,
    required VoidCallback onClear,
  }) async {
    final isLogo = tipo == 'logo';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir ${isLogo ? 'Logo' : 'Mascote'}'),
        content: Text(
          'Deseja remover ${isLogo ? 'a logo' : 'o mascote'} da instituição?\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      if (url.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (_) {}
      }
      await _db
          .collection('instituicoes')
          .doc(widget.substituicaoInstituicaoId)
          .update({'${tipo}Url': ''});
      onClear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLogo ? 'Logo removida com sucesso!' : 'Mascote removido com sucesso!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover: $e')),
        );
      }
    }
  }

  // ─────────────────────────── IDENTIDADE VISUAL ────────────────────────────

  Future<void> _salvarIdentidade() async {
    if (!_formKeyIdentidade.currentState!.validate()) return;
    setState(() => _salvandoIdentidade = true);
    try {
      final antigo = {
        'nome': _nomeEscolaController.text,
        'cor': _corSelecionada,
        'logoUrl': _logoUrl,
        'mascoteUrl': _mascoteUrl,
      }.toString();

      String novaLogoUrl = _logoUrl;
      if (_logoBytes != null) {
        novaLogoUrl = await _uploadImagem(_logoBytes!, _logoNomeArquivo, 'logo');
      }
      String novoMascoteUrl = _mascoteUrl;
      if (_mascoteBytes != null) {
        novoMascoteUrl =
            await _uploadImagem(_mascoteBytes!, _mascoteNomeArquivo, 'mascote');
      }

      final dados = {
        'nome': _nomeEscolaController.text.trim(),
        'corHexadecimal': _corSelecionada,
        'corHex': _corSelecionada,
        'logoUrl': novaLogoUrl,
        'mascoteUrl': novoMascoteUrl,
      };

      await ref.read(adminDataSourceProvider).salvarIdentidade(
            widget.substituicaoInstituicaoId, dados);

      await _registrarAuditoria(
        'ALTERAR',
        'Painel Administrativo',
        'Alterou a identidade visual da instituição',
        antigo,
        dados.toString(),
      );

      if (mounted) {
        setState(() {
          _logoUrl = novaLogoUrl;
          _mascoteUrl = novoMascoteUrl;
          _logoBytes = null;
          _logoNomeArquivo = '';
          _mascoteBytes = null;
          _mascoteNomeArquivo = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Identidade visual salva com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvandoIdentidade = false);
    }
  }

  Future<void> _adicionarPatrocinador() async {
    if (_patrocinadoresUrls.length + _patrocinadorBytes.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Limite máximo de 5 patrocinadores atingido.')),
        );
      }
      return;
    }
    await _selecionarImagem(onBytes: (bytes, nome) {
      setState(() {
        _patrocinadorBytes.add(bytes);
        _patrocinadorNomes.add(nome);
      });
    });
  }

  Future<void> _salvarPatrocinadores() async {
    setState(() => _salvandoPatrocinadores = true);
    try {
      final novasUrls = <String>[];
      for (var i = 0; i < _patrocinadorBytes.length; i++) {
        final url = await _uploadImagem(
          _patrocinadorBytes[i],
          _patrocinadorNomes[i],
          'patrocinadores',
        );
        novasUrls.add(url);
      }
      final todasUrls = [..._patrocinadoresUrls, ...novasUrls];

      await ref.read(adminDataSourceProvider).salvarPatrocinadores(
            widget.substituicaoInstituicaoId, todasUrls);

      await _registrarAuditoria(
        'ALTERAR',
        'Painel Administrativo',
        'Atualizou logos de patrocinadores (${novasUrls.length} novos)',
        _patrocinadoresUrls.toString(),
        todasUrls.toString(),
      );

      if (mounted) {
        setState(() {
          _patrocinadoresUrls = todasUrls;
          _patrocinadorBytes = [];
          _patrocinadorNomes = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Patrocinadores salvos com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar patrocinadores: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvandoPatrocinadores = false);
    }
  }

  // ─────────────────────────── USUÁRIOS ─────────────────────────────────────

  Future<void> _cadastrarNovoUsuario() async {
    if (!_formKeyUsuario.currentState!.validate()) return;
    setState(() => _salvandoUsuario = true);

    final email = _emailUsuarioController.text.trim();
    final senha = _senhaUsuarioController.text.trim();
    final roleDestino =
        _roleCriador == 'Acess2' ? 'Acess3' : _roleSelecionada;

    FirebaseApp? tempApp;
    try {
      // 1. Cria conta no Firebase Auth via app secundário sem deslogar o admin
      tempApp = await Firebase.initializeApp(
        name: 'criarUsuario_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final uid = cred.user!.uid;
      await tempAuth.signOut();

      // 2. Cria documento Firestore usando o UID real do Firebase Auth
      final novoUserMap = {
        'uid': uid,
        'nome': _nomeUsuarioController.text.trim(),
        'email': email,
        'role': roleDestino,
        'instituicaoId': widget.substituicaoInstituicaoId,
        'avatarEmoji': '🦁',
        'pontuacaoAcumulada': 0,
        'criadoPor': FirebaseAuth.instance.currentUser?.uid ?? 'Admin',
        'primeiroAcesso': true,
      };

      await _db.collection('usuarios').doc(uid).set(novoUserMap);

      await _registrarAuditoria(
        'CRIAR',
        'Usuários',
        'Cadastrou ${_nomeUsuarioController.text.trim()} ($roleDestino)',
        'Nenhum (Novo Registro)',
        novoUserMap.toString(),
      );

      _nomeUsuarioController.clear();
      _emailUsuarioController.clear();
      _senhaUsuarioController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Este e-mail já está cadastrado no sistema.';
        case 'invalid-email':
          msg = 'E-mail inválido.';
        case 'weak-password':
          msg = 'Senha fraca (mínimo 6 caracteres).';
        default:
          msg = 'Erro ao criar acesso: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar usuário: $e')),
        );
      }
    } finally {
      await tempApp?.delete();
      if (mounted) setState(() => _salvandoUsuario = false);
    }
  }

  // ─────────────────────────── BUILD ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAdmin = _roleCriador == 'Admin';

    final tabViews = isAdmin
        ? <Widget>[
            _buildHome(),
            _buildPainelAdministrativo(),
            AdminCategoriasTab(
              instituicaoId: widget.substituicaoInstituicaoId,
              roleCriador: _roleCriador,
              onAuditoria: _registrarAuditoria,
            ),
            AdminQuestoesTab(
              instituicaoId: widget.substituicaoInstituicaoId,
              roleCriador: _roleCriador,
              onAuditoria: _registrarAuditoria,
            ),
            AdminMensagensTab(
              instituicaoId: widget.substituicaoInstituicaoId,
              mascoteUrl: _mascoteUrl,
              onAuditoria: _registrarAuditoria,
            ),
            AdminGamificacaoTab(
              instituicaoId: widget.substituicaoInstituicaoId,
              onAuditoria: _registrarAuditoria,
            ),
            _buildUsuarios(),
            _buildAuditoria(),
            const MeuPerfilPage(),
          ]
        : <Widget>[
            _buildHome(),
            AdminCategoriasTab(
              instituicaoId: widget.substituicaoInstituicaoId,
              roleCriador: 'Acess2',
              onAuditoria: _registrarAuditoria,
            ),
            AdminQuestoesTab(
              instituicaoId: widget.substituicaoInstituicaoId,
              roleCriador: _roleCriador,
              onAuditoria: _registrarAuditoria,
            ),
            AdminMensagensTab(
              instituicaoId: widget.substituicaoInstituicaoId,
              mascoteUrl: _mascoteUrl,
              onAuditoria: _registrarAuditoria,
              somenteLeitura: true,
            ),
            _buildUsuarios(),
            const MeuPerfilPage(),
          ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: tabViews,
        ),
      ),
    );
  }

  // ─────────────────────────── HOME ─────────────────────────────────────────

  Widget _buildHome() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final inst = widget.substituicaoInstituicaoId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _roleCriador == 'Acess2'
                ? 'Painel Acess2'
                : 'Painel do Administrador',
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Gerencie conteúdo e acompanhe resultados.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final full = constraints.maxWidth < 600;
            final w = full ? constraints.maxWidth : 220.0;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _metricCard(
                  title: _roleCriador == 'Acess2'
                      ? 'Questões que Cadastrou'
                      : 'Total de Questões',
                  icon: Icons.description_outlined,
                  color: Colors.blue,
                  width: w,
                  future: _roleCriador == 'Acess2'
                      ? _db
                          .collection('questoes')
                          .where('instituicaoId', isEqualTo: inst)
                          .where('criadoPor', isEqualTo: uid)
                          .count()
                          .get()
                          .then((s) => (s.count ?? 0).toString())
                      : _db
                          .collection('questoes')
                          .where('instituicaoId', isEqualTo: inst)
                          .count()
                          .get()
                          .then((s) => (s.count ?? 0).toString()),
                ),
                _metricCard(
                  title: 'Total de Alunos',
                  icon: Icons.people_outline,
                  color: Colors.green,
                  width: w,
                  future: _db
                      .collection('usuarios')
                      .where('instituicaoId', isEqualTo: inst)
                      .where('role', isEqualTo: 'Acess3')
                      .count()
                      .get()
                      .then((s) => (s.count ?? 0).toString()),
                ),
                if (_roleCriador == 'Admin')
                  _metricCard(
                    title: 'Categorias Cadastradas',
                    icon: Icons.category_outlined,
                    color: Colors.purple,
                    width: w,
                    future: _db
                        .collection('categorias')
                        .where('instituicaoId', isEqualTo: inst)
                        .count()
                        .get()
                        .then((s) => (s.count ?? 0).toString()),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required IconData icon,
    required Color color,
    required double width,
    required Future<String> future,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(25),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                FutureBuilder<String>(
                  future: future,
                  builder: (_, snap) => Text(
                    snap.data ?? '–',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── PAINEL ADMINISTRATIVO ────────────────────────

  Widget _buildPainelAdministrativo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Identidade Visual ──
          const Text('Identidade Visual',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Form(
            key: _formKeyIdentidade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nomeEscolaController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Instituição *',
                    hintText: 'Ex: Faculdade Impacto',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Insira o nome da instituição'
                      : null,
                ),
                const SizedBox(height: 20),
                const Text('Cor da Instituição',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildSeletorCores(),
                const SizedBox(height: 20),
                const Text('Logo da Instituição',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildSeletorImagem(
                  bytes: _logoBytes,
                  urlExistente: _logoUrl,
                  nomeArquivo: _logoNomeArquivo,
                  onSelecionar: () => _selecionarImagem(
                    onBytes: (b, n) => setState(() {
                      _logoBytes = b;
                      _logoNomeArquivo = n;
                    }),
                  ),
                  onExcluir: () {
                    if (_logoBytes != null) {
                      setState(() {
                        _logoBytes = null;
                        _logoNomeArquivo = '';
                      });
                      return;
                    }
                    _excluirImagem(
                      tipo: 'logo',
                      url: _logoUrl,
                      onClear: () => setState(() {
                        _logoUrl = '';
                        _logoBytes = null;
                        _logoNomeArquivo = '';
                      }),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text('Mascote da Instituição',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildSeletorImagem(
                  bytes: _mascoteBytes,
                  urlExistente: _mascoteUrl,
                  nomeArquivo: _mascoteNomeArquivo,
                  onSelecionar: () => _selecionarImagem(
                    onBytes: (b, n) => setState(() {
                      _mascoteBytes = b;
                      _mascoteNomeArquivo = n;
                    }),
                  ),
                  onExcluir: () {
                    if (_mascoteBytes != null) {
                      setState(() {
                        _mascoteBytes = null;
                        _mascoteNomeArquivo = '';
                      });
                      return;
                    }
                    _excluirImagem(
                      tipo: 'mascote',
                      url: _mascoteUrl,
                      onClear: () => setState(() {
                        _mascoteUrl = '';
                        _mascoteBytes = null;
                        _mascoteNomeArquivo = '';
                      }),
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        _salvandoIdentidade ? null : _salvarIdentidade,
                    child: _salvandoIdentidade
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text('Salvar Identidade Visual'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          // ── Patrocinadores ──
          Row(
            children: [
              Expanded(
                child: Text(
                  'Patrocinadores no Rodapé (${_patrocinadoresUrls.length + _patrocinadorBytes.length}/5)',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _adicionarPatrocinador,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Logo'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Logos já salvas
          ..._patrocinadoresUrls.asMap().entries.map((e) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      e.value,
                      width: 60,
                      height: 30,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) =>
                          progress == null
                              ? child
                              : const SizedBox(
                                  width: 60,
                                  height: 30,
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5))),
                      errorBuilder: (ctx, err, st) => const Tooltip(
                        message: 'Storage não autorizado ou CORS ausente.',
                        child: Icon(Icons.broken_image,
                            size: 20, color: Colors.orange),
                      ),
                    ),
                  ),
                  title: Text('Patrocinador #${e.key + 1}',
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(e.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Excluir Patrocinador'),
                          content: Text(
                            'Deseja remover o patrocinador #${e.key + 1}?\nEsta ação atualizará o rodapé imediatamente.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                      if (confirmar != true) return;

                      final antigo = List<String>.from(_patrocinadoresUrls);
                      final novaLista = List<String>.from(_patrocinadoresUrls)
                        ..removeAt(e.key);
                      setState(() => _patrocinadoresUrls = novaLista);
                      await ref.read(adminDataSourceProvider).salvarPatrocinadores(
                            widget.substituicaoInstituicaoId, _patrocinadoresUrls);
                      await _registrarAuditoria(
                        'EXCLUIR',
                        'Painel Administrativo',
                        'Removeu patrocinador #${e.key + 1}',
                        antigo.toString(),
                        _patrocinadoresUrls.toString(),
                      );
                    },
                  ),
                ),
              )),
          // Logos staged (aguardando upload)
          ..._patrocinadorBytes.asMap().entries.map((e) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.orange.shade50,
                child: ListTile(
                  dense: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(e.value,
                        width: 60, height: 30, fit: BoxFit.contain),
                  ),
                  title: Text(_patrocinadorNomes[e.key],
                      style: const TextStyle(fontSize: 13)),
                  subtitle: const Text('Pendente de upload',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() {
                      _patrocinadorBytes.removeAt(e.key);
                      _patrocinadorNomes.removeAt(e.key);
                    }),
                  ),
                ),
              )),
          if (_patrocinadoresUrls.isEmpty && _patrocinadorBytes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum patrocinador cadastrado.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          if (_patrocinadorBytes.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                onPressed: _salvandoPatrocinadores
                    ? null
                    : _salvarPatrocinadores,
                child: _salvandoPatrocinadores
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : Text(
                        'Salvar ${_patrocinadorBytes.length} Logo(s) de Patrocinador'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeletorCores() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _coresPredefinidas.map((c) {
        final hex = c['hex'] as String;
        final colorVal =
            Color(int.parse(hex.replaceFirst('#', '0xFF')));
        final selected = _corSelecionada == hex;
        return Tooltip(
          message: c['nome'] as String,
          child: GestureDetector(
            onTap: () => setState(() => _corSelecionada = hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorVal,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: colorVal.withAlpha(100),
                          blurRadius: 6,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: selected
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 18)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeletorImagem({
    required Uint8List? bytes,
    required String urlExistente,
    required String nomeArquivo,
    required VoidCallback onSelecionar,
    VoidCallback? onExcluir,
  }) {
    Widget preview;
    if (bytes != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, height: 80, fit: BoxFit.contain),
      );
    } else if (urlExistente.isNotEmpty) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          urlExistente,
          height: 80,
          fit: BoxFit.contain,
          loadingBuilder: (ctx, child, progress) => progress == null
              ? child
              : const SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2))),
          errorBuilder: (ctx, err, st) => const Tooltip(
            message: 'Falha ao carregar imagem.\nVerifique regras do Storage e CORS.',
            child: Icon(Icons.broken_image, size: 40, color: Colors.orange),
          ),
        ),
      );
    } else {
      preview = Container(
        height: 80,
        width: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.image_outlined,
            color: Colors.grey, size: 40),
      );
    }

    return Row(
      children: [
        preview,
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: onSelecionar,
              icon: const Icon(Icons.upload_outlined, size: 16),
              label: const Text('Selecionar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
            if (onExcluir != null && (bytes != null || urlExistente.isNotEmpty)) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: onExcluir,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              bytes != null
                  ? nomeArquivo
                  : (urlExistente.isNotEmpty
                      ? 'Imagem atual'
                      : 'PNG, JPG, JPEG até 2MB'),
              style: TextStyle(
                  fontSize: 11,
                  color: bytes != null
                      ? Colors.green.shade700
                      : Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────── USUÁRIOS ─────────────────────────────────────

  Widget _buildUsuarios() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final formulario = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(
                () => _formularioUsuarioExpandido = !_formularioUsuarioExpandido),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Cadastro de Novos Usuários',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Icon(_formularioUsuarioExpandido
                      ? Icons.expand_less
                      : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_formularioUsuarioExpandido) ...[
            const SizedBox(height: 12),
            Form(
              key: _formKeyUsuario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            TextFormField(
              controller: _nomeUsuarioController,
              decoration:
                  const InputDecoration(labelText: 'Nome Completo *'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Campo obrigatório'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailUsuarioController,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: 'E-mail de Acesso *'),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'E-mail inválido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _senhaUsuarioController,
              obscureText: _ocultarSenha,
              decoration: InputDecoration(
                labelText: 'Senha Base *',
                suffixIcon: IconButton(
                  icon: Icon(_ocultarSenha
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _ocultarSenha = !_ocultarSenha),
                ),
              ),
              validator: (v) => v == null || v.length < 6
                  ? 'Mínimo 6 caracteres'
                  : null,
            ),
            const SizedBox(height: 12),
            if (_roleCriador == 'Admin') ...[
              DropdownButtonFormField<String>(
                initialValue: _roleSelecionada,
                decoration:
                    const InputDecoration(labelText: 'Nível de Acesso *'),
                items: const [
                  DropdownMenuItem(
                      value: 'Acess2',
                      child: Text('Acess2 (Gestor de Conteúdo)')),
                  DropdownMenuItem(
                      value: 'Acess3',
                      child: Text('Acess3 (Aluno / Estudante)')),
                ],
                onChanged: (v) =>
                    setState(() => _roleSelecionada = v ?? 'Acess3'),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nível configurado automaticamente: Acess3 (Aluno)',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w500),
                ),
              ),
            ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        _salvandoUsuario ? null : _cadastrarNovoUsuario,
                    child: _salvandoUsuario
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text('Registrar Usuário'),
                  ),
                ),
                ],      // fecha children do Form > Column
              ),        // fecha Column interno do Form
            ),          // fecha Form
          ],            // fecha if (_formularioUsuarioExpandido) ...[
        ],              // fecha children do Column externo
      );

      final usuariosStreamWidget = StreamBuilder<QuerySnapshot>(
        stream: ref.read(adminDataSourceProvider).streamUsuarios(
              instituicaoId: widget.substituicaoInstituicaoId,
              role: _roleCriador == 'Acess2' ? 'Acess3' : null,
              criadoPor: _roleCriador == 'Acess2' ? uid : null,
            ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Text('Nenhum usuário cadastrado.',
                style:
                    TextStyle(color: Colors.grey, fontSize: 12));
          }
          return ListView.builder(
            shrinkWrap: isMobile,
            physics: isMobile ? const NeverScrollableScrollPhysics() : null,
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final u =
                  docs[i].data() as Map<String, dynamic>;
              final podeDeletar = _roleCriador == 'Admin' ||
                  u['criadoPor'] == uid;
              return Card(
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(u['nome'] ?? 'Sem nome'),
                  subtitle: Text(
                      '${u['email']} • ${u['role']}'),
                  trailing: podeDeletar
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blue,
                                  size: 18),
                              tooltip: 'Editar usuário',
                              onPressed: () async {
                                final nomeCtrl = TextEditingController(text: u['nome'] ?? '');
                                final emailCtrl = TextEditingController(text: u['email'] ?? '');
                                final formKey = GlobalKey<FormState>();
                                String editRole = u['role'] ?? 'Acess3';
                                final salvo = await showDialog<bool>(
                                  context: context,
                                  builder: (dlgCtx) => StatefulBuilder(
                                    builder: (ctx, setDlg) => AlertDialog(
                                      title: const Text('Editar Usuário'),
                                      content: Form(
                                        key: formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextFormField(
                                              controller: nomeCtrl,
                                              decoration: const InputDecoration(labelText: 'Nome *'),
                                              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                                            ),
                                            const SizedBox(height: 12),
                                            TextFormField(
                                              controller: emailCtrl,
                                              decoration: const InputDecoration(labelText: 'E-mail'),
                                              keyboardType: TextInputType.emailAddress,
                                            ),
                                            if (_roleCriador == 'Admin') ...[
                                              const SizedBox(height: 12),
                                              DropdownButtonFormField<String>(
                                                key: ValueKey(editRole),
                                                initialValue: editRole,
                                                decoration: const InputDecoration(labelText: 'Nível de Acesso'),
                                                items: const [
                                                  DropdownMenuItem(value: 'Acess2', child: Text('Acess2 (Gestor)')),
                                                  DropdownMenuItem(value: 'Acess3', child: Text('Acess3 (Aluno)')),
                                                ],
                                                onChanged: (v) => setDlg(() => editRole = v ?? editRole),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dlgCtx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            if (formKey.currentState!.validate()) {
                                              Navigator.pop(dlgCtx, true);
                                            }
                                          },
                                          child: const Text('Salvar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                if (salvo == true) {
                                  final novoNome = nomeCtrl.text.trim();
                                  final novoEmail = emailCtrl.text.trim();
                                  await ref.read(adminDataSourceProvider).editarUsuario(docs[i].id, {
                                    'nome': novoNome,
                                    if (novoEmail.isNotEmpty) 'email': novoEmail,
                                    if (_roleCriador == 'Admin') 'role': editRole,
                                  });
                                  await _registrarAuditoria(
                                    'ALTERAR',
                                    'Usuários',
                                    'Editou usuário ${u['nome']} → $novoNome (role: $editRole)',
                                    u.toString(),
                                    'nome: $novoNome, email: $novoEmail, role: $editRole',
                                  );
                                }
                                nomeCtrl.dispose();
                                emailCtrl.dispose();
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18),
                              tooltip: 'Excluir usuário',
                              onPressed: () async {
                                final confirm =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (dlgCtx) => AlertDialog(
                                    title: const Text(
                                        'Excluir Usuário'),
                                    content: Text(
                                        'Excluir ${u['nome']}?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  dlgCtx, false),
                                          child: const Text(
                                              'Cancelar')),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  dlgCtx, true),
                                          child: const Text(
                                              'Excluir',
                                              style: TextStyle(
                                                  color:
                                                      Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(adminDataSourceProvider).excluirUsuario(docs[i].id);
                                  await _registrarAuditoria(
                                    'EXCLUIR',
                                    'Usuários',
                                    'Excluiu ${u['nome']} (${u['role']})',
                                    u.toString(),
                                    'Excluído',
                                  );
                                }
                              },
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      );

      final lista = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Últimos Usuários da Instituição',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (isMobile) usuariosStreamWidget else Expanded(child: usuariosStreamWidget),
        ],
      );

      if (isMobile) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                formulario,
                const Divider(height: 24),
                lista,
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: SingleChildScrollView(child: formulario)),
            const VerticalDivider(width: 32),
            Expanded(child: lista),
          ],
        ),
      );
    });
  }

  // ─────────────────────────── AUDITORIA VIEW ───────────────────────────────

  Widget _buildAuditoria() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auditoriaStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final auditDocs = List<QueryDocumentSnapshot>.from(snap.data?.docs ?? [])
          ..sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['dataHora'] as Timestamp?;
            final bTs = (b.data() as Map<String, dynamic>)['dataHora'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });
        final top10 = auditDocs.take(10).toList();
        if (top10.isEmpty) {
          return const Center(
            child: Text('Nenhuma atividade registrada.',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return Scrollbar(
          thumbVisibility: true,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: top10.length,
            itemBuilder: (context, i) {
              final d =
                  top10[i].data() as Map<String, dynamic>;
              final ts = d['dataHora'] as Timestamp?;
              final dataStr = ts != null
                  ? ts.toDate().toLocal().toString().substring(0, 16)
                  : '--/--';
              final acaoColor = d['acao'] == 'CRIAR'
                  ? Colors.green
                  : d['acao'] == 'EXCLUIR'
                      ? Colors.red
                      : Colors.blue;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ExpansionTile(
                  leading: Chip(
                    label: Text(d['acao'] ?? 'INFO',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    backgroundColor: acaoColor,
                    padding: EdgeInsets.zero,
                  ),
                  title: Text(d['detalhe'] ?? '',
                      style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                      'Por: ${d['userName']} • $dataStr',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tela: ${d['tela']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          const Divider(),
                          const Text('Antes:',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              _formatarRegistroAuditoria(d['registroAntigo'] as String?),
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          const Text('Depois:',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              _formatarRegistroAuditoria(d['registroNovo'] as String?),
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
