import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../../auth/presentation/pages/meu_perfil_page.dart';

class PainelMasterPage extends StatefulWidget {
  final int initialTab;
  const PainelMasterPage({super.key, this.initialTab = 0});

  @override
  State<PainelMasterPage> createState() => _PainelMasterPageState();
}

class _PainelMasterPageState extends State<PainelMasterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Estado do formulário de instituição
  bool _mostrarFormInstituicao = false;
  String? _editandoInstituicaoId;
  final _formKeyInstituicao = GlobalKey<FormState>();
  final _idBancoController = TextEditingController();
  final _nomeController = TextEditingController();
  String _corSelecionada = '#1565C0';
  Uint8List? _logoBytes;
  String _logoNomeArquivo = '';
  String _logoUrlExistente = '';
  bool _salvando = false;

  static const List<Map<String, dynamic>> _coresPredefinidas = [
    {'nome': 'Azul Royal', 'hex': '#1565C0'},
    {'nome': 'Índigo', 'hex': '#283593'},
    {'nome': 'Ciano Escuro', 'hex': '#006064'},
    {'nome': 'Verde', 'hex': '#2E7D32'},
    {'nome': 'Teal', 'hex': '#00695C'},
    {'nome': 'Roxo', 'hex': '#6A1B9A'},
    {'nome': 'Rosa Escuro', 'hex': '#880E4F'},
    {'nome': 'Vermelho', 'hex': '#B71C1C'},
    {'nome': 'Laranja Escuro', 'hex': '#E65100'},
    {'nome': 'Âmbar', 'hex': '#F57F17'},
    {'nome': 'Marrom', 'hex': '#4E342E'},
    {'nome': 'Cinza', 'hex': '#37474F'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void didUpdateWidget(PainelMasterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab &&
        widget.initialTab < _tabController.length) {
      _tabController.animateTo(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idBancoController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Color _hexParaCor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length != 6) return Colors.blue;
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Future<void> _registrarAuditoria({
    required String acao,
    required String tela,
    required String detalhe,
    required String antigo,
    required String novo,
    String instituicaoId = 'master',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _db.collection('auditoria').add({
        'instituicaoId': instituicaoId,
        'userId': user?.uid ?? 'master',
        'userName': user?.email ?? 'Master',
        'acao': acao,
        'tela': tela,
        'detalhe': detalhe,
        'registroAntigo': antigo,
        'registroNovo': novo,
        'dataHora': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Falha ao registrar auditoria: $e');
    }
  }

  void _iniciarNovaInstituicao() {
    setState(() {
      _mostrarFormInstituicao = true;
      _editandoInstituicaoId = null;
      _idBancoController.clear();
      _nomeController.clear();
      _corSelecionada = '#1565C0';
      _logoBytes = null;
      _logoNomeArquivo = '';
      _logoUrlExistente = '';
    });
  }

  void _iniciarEdicaoInstituicao(Map<String, dynamic> dados, String id) {
    final corBanco =
        (dados['corHexadecimal'] ?? dados['corHex'] ?? '').toString();
    setState(() {
      _mostrarFormInstituicao = true;
      _editandoInstituicaoId = id;
      _nomeController.text = dados['nome'] ?? '';
      _corSelecionada = _coresPredefinidas.any((c) => c['hex'] == corBanco)
          ? corBanco
          : '#1565C0';
      _logoUrlExistente = (dados['logoUrl'] ?? '').toString();
      _logoBytes = null;
      _logoNomeArquivo = '';
    });
  }

  void _cancelarFormInstituicao() {
    setState(() {
      _mostrarFormInstituicao = false;
      _editandoInstituicaoId = null;
    });
  }

  Future<void> _salvarInstituicao() async {
    if (!_formKeyInstituicao.currentState!.validate()) return;

    final bool isEdicao = _editandoInstituicaoId != null;
    final idBanco = isEdicao
        ? _editandoInstituicaoId!
        : _idBancoController.text.trim();

    setState(() => _salvando = true);
    try {
      final nome = _nomeController.text.trim();
      final cor = _corSelecionada;

      // Upload da logo se um novo arquivo foi selecionado
      String logoUrl = _logoUrlExistente;
      if (_logoBytes != null && _logoNomeArquivo.isNotEmpty) {
        final ext = _logoNomeArquivo.split('.').last.toLowerCase();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('instituicoes')
            .child(idBanco)
            .child('logo_$timestamp.$ext');
        final metadata = SettableMetadata(contentType: 'image/$ext');
        final upload = await storageRef.putData(_logoBytes!, metadata);
        logoUrl = await upload.ref.getDownloadURL();
      }

      if (!isEdicao) {
        await _db.collection('instituicoes').doc(idBanco).set({
          'nome': nome,
          'corHexadecimal': cor,
          'corHex': cor,
          'logoUrl': logoUrl,
          'dataCriacao': FieldValue.serverTimestamp(),
          'plano': 'gratuito',
          'patrocinadoresUrls': [],
          'patrocinios': [],
        });
        await _registrarAuditoria(
          acao: 'CRIAR',
          tela: 'Gestão de Instituições',
          detalhe: 'Cadastrou a instituição "$nome" com ID "$idBanco"',
          antigo: 'Nenhum (Novo Registro)',
          novo: 'Nome: $nome | ID: $idBanco | Cor: $cor | Logo: $logoUrl',
          instituicaoId: idBanco,
        );
      } else {
        final dadosAntigos = await _db
            .collection('instituicoes')
            .doc(idBanco)
            .get();
        await _db.collection('instituicoes').doc(idBanco).update({
          'nome': nome,
          'corHexadecimal': cor,
          'corHex': cor,
          'logoUrl': logoUrl,
        });
        await _registrarAuditoria(
          acao: 'ALTERAR',
          tela: 'Gestão de Instituições',
          detalhe: 'Alterou dados da instituição "$nome"',
          antigo: dadosAntigos.data()?.toString() ?? 'Desconhecido',
          novo: 'Nome: $nome | Cor: $cor | Logo: $logoUrl',
          instituicaoId: idBanco,
        );
      }

      setState(() {
        _mostrarFormInstituicao = false;
        _editandoInstituicaoId = null;
        _logoBytes = null;
        _logoNomeArquivo = '';
        _logoUrlExistente = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdicao
                  ? 'Instituição atualizada com sucesso!'
                  : 'Instituição cadastrada com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluirInstituicao(String id, String nome) async {
    final usuariosSnap =
        await _db
            .collection('usuarios')
            .where('instituicaoId', isEqualTo: id)
            .limit(1)
            .get();

    final temUsuarios = usuariosSnap.docs.isNotEmpty;

    if (!mounted) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deseja excluir a instituição "$nome"?'),
                if (temUsuarios) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      '⚠️ Esta instituição possui usuários cadastrados. Ao excluir, todos os vínculos serão removidos.',
                      style: TextStyle(color: Colors.deepOrange, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    try {
      await _db.collection('instituicoes').doc(id).delete();
      await _registrarAuditoria(
        acao: 'EXCLUIR',
        tela: 'Gestão de Instituições',
        detalhe: 'Excluiu a instituição "$nome"',
        antigo: 'Instituição: $nome (id: $id)',
        novo: 'Registro excluído',
        instituicaoId: id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instituição excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verUsuariosInstituicao(String instituicaoId, String nomeInstituicao) {
    showDialog(
      context: context,
      builder:
          (ctx) => _DialogVerUsuarios(
            db: _db,
            instituicaoId: instituicaoId,
            nomeInstituicao: nomeInstituicao,
            registrarAuditoria: _registrarAuditoria,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // O Scaffold externo é provido pelo MainLayoutShell (ShellRoute).
    // Usamos Column aqui para não criar Scaffold aninhado conflitante.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildHome(),
            _buildInstituicoes(),
            _buildAuditoria(),
            _buildMeuPerfil(),
          ],
        ),
      ),
    );
  }

  // ─── ABA HOME ───────────────────────────────────────────────────────────────

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Painel Master',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Visão geral de todas as instituições e usuários.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('usuarios').snapshots(),
            builder: (context, snapUsuarios) {
              return StreamBuilder<QuerySnapshot>(
                stream: _db.collection('instituicoes').snapshots(),
                builder: (context, snapInst) {
                  if (!snapUsuarios.hasData || !snapInst.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final usuarios = snapUsuarios.data!.docs;
                  final instituicoes = snapInst.data!.docs;

                  int totalAdmin = 0, totalAcess2 = 0, totalAcess3 = 0;
                  for (final u in usuarios) {
                    final role =
                        (u.data() as Map<String, dynamic>)['role'] ?? '';
                    if (role == 'Admin') totalAdmin++;
                    if (role == 'Acess2') totalAcess2++;
                    if (role == 'Acess3') totalAcess3++;
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final cardWidth = isMobile ? constraints.maxWidth : 200.0;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildMetricCard(
                            'Total de Usuários',
                            '${usuarios.length}',
                            Icons.group_outlined,
                            Colors.blue,
                            cardWidth,
                          ),
                          _buildMetricCard(
                            'Instituições Cadastradas',
                            '${instituicoes.length}',
                            Icons.business_outlined,
                            Colors.teal,
                            cardWidth,
                          ),
                          _buildMetricCard(
                            'Total de Admin',
                            '$totalAdmin',
                            Icons.admin_panel_settings_outlined,
                            Colors.indigo,
                            cardWidth,
                          ),
                          _buildMetricCard(
                            'Total Acess2',
                            '$totalAcess2',
                            Icons.manage_accounts_outlined,
                            Colors.purple,
                            cardWidth,
                          ),
                          _buildMetricCard(
                            'Total Acess3 (Alunos)',
                            '$totalAcess3',
                            Icons.school_outlined,
                            Colors.green,
                            cardWidth,
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ABA INSTITUIÇÕES ────────────────────────────────────────────────────────

  Widget _buildInstituicoes() {
    return Column(
      children: [
        // Barra de ação
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'Instituições Cadastradas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (!_mostrarFormInstituicao)
                FilledButton.icon(
                  onPressed: _iniciarNovaInstituicao,
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Nova Instituição'),
                ),
            ],
          ),
        ),

        // Formulário de criação/edição
        if (_mostrarFormInstituicao) _buildFormInstituicao(),

        // Lista de instituições
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Sem orderBy: documentos sem o campo 'dataCriacao' seriam
            // silenciosamente excluídos pelo Firestore. Ordenamos no cliente.
            stream: _db.collection('instituicoes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhuma instituição cadastrada ainda.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              // Ordena no cliente: mais recentes primeiro (null vai para o fim)
              final docs =
                  List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
              docs.sort((a, b) {
                final aTs = (a.data() as Map<String, dynamic>)['dataCriacao']
                    as Timestamp?;
                final bTs = (b.data() as Map<String, dynamic>)['dataCriacao']
                    as Timestamp?;
                if (aTs == null && bTs == null) return 0;
                if (aTs == null) return 1;
                if (bTs == null) return -1;
                return bTs.compareTo(aTs);
              });
              return _buildListaInstituicoes(docs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormInstituicao() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKeyInstituicao,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editandoInstituicaoId == null
                    ? 'Nova Instituição'
                    : 'Editar Instituição',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ── Campo Nome ID banco (somente na criação) ──────────────
              if (_editandoInstituicaoId == null) ...[
                TextFormField(
                  controller: _idBancoController,
                  decoration: const InputDecoration(
                    labelText: 'Nome ID banco *',
                    hintText: 'Ex: faculdade-impacto',
                    helperText:
                        'Identificador único no banco. Use letras minúsculas, números e hífens. Não pode ser alterado depois.',
                    helperMaxLines: 2,
                    prefixIcon: Icon(Icons.key_outlined),
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9\-]')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o ID do banco';
                    }
                    if (!RegExp(r'^[a-z0-9][a-z0-9\-]*[a-z0-9]$')
                        .hasMatch(v.trim())) {
                      return 'Use letras minúsculas, números e hífens (sem começar/terminar com hífen)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ] else ...[
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'ID no banco (não editável)',
                    prefixIcon: const Icon(Icons.key_outlined),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  child: Text(
                    _editandoInstituicaoId!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Nome da Instituição ───────────────────────────────────
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Instituição *',
                  hintText: 'Ex: Faculdade Impacto',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Informe o nome da instituição'
                        : null,
              ),
              const SizedBox(height: 16),

              // ── Seletor de cores predefinidas ─────────────────────────
              _buildSeletorCores(),
              const SizedBox(height: 16),

              // ── Upload da logo ────────────────────────────────────────
              _buildSeletorLogo(),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _cancelarFormInstituicao,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _salvando ? null : _salvarInstituicao,
                    child: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editandoInstituicaoId == null
                                ? 'Salvar Instituição'
                                : 'Salvar Alterações',
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

  Widget _buildSeletorCores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor Primária *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _coresPredefinidas.map((corMap) {
            final hex = corMap['hex'] as String;
            final nome = corMap['nome'] as String;
            final cor = _hexParaCor(hex);
            final isSelecionada = _corSelecionada == hex;
            return Tooltip(
              message: nome,
              child: GestureDetector(
                onTap: () => setState(() => _corSelecionada = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelecionada ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelecionada
                            ? cor.withAlpha(160)
                            : Colors.black.withAlpha(30),
                        blurRadius: isSelecionada ? 10 : 3,
                        spreadRadius: isSelecionada ? 2 : 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: isSelecionada
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 22,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _hexParaCor(_corSelecionada),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_coresPredefinidas.firstWhere((c) => c['hex'] == _corSelecionada, orElse: () => {'nome': 'Personalizada'})['nome']}  $_corSelecionada',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selecionarLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;
      if (file.bytes!.length > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo muito grande. O tamanho máximo é 2MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      setState(() {
        _logoBytes = file.bytes;
        _logoNomeArquivo = file.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSeletorLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo da Instituição',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _selecionarLogo,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Selecionar Imagem'),
            ),
            if (_logoNomeArquivo.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _logoNomeArquivo,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                tooltip: 'Remover seleção',
                onPressed: () => setState(() {
                  _logoBytes = null;
                  _logoNomeArquivo = '';
                }),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Aceita PNG, JPG e JPEG • Tamanho máximo: 2MB',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        if (_logoBytes != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(_logoBytes!, height: 80, fit: BoxFit.contain),
          ),
        ] else if (_logoUrlExistente.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _logoUrlExistente,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Logo atual (selecione uma nova para substituir)',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }

  Widget _buildListaInstituicoes(List<QueryDocumentSnapshot> docs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: isMobile
              ? Column(
                  children: docs
                      .map((doc) => _buildInstituicaoCard(doc))
                      .toList(),
                )
              : Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: docs
                      .map(
                        (doc) => SizedBox(
                          width: (constraints.maxWidth - 48) / 2,
                          child: _buildInstituicaoCard(doc),
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }

  Widget _buildInstituicaoCard(QueryDocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>;
    final nome = dados['nome'] ?? 'Sem nome';
    final corHex =
        (dados['corHexadecimal'] ?? dados['corHex'] ?? '#1E88E5').toString();
    final logoUrl = (dados['logoUrl'] ?? '').toString();
    final timestamp = dados['dataCriacao'] as Timestamp?;
    final dataCriacao = timestamp != null
        ? timestamp.toDate().toLocal().toString().substring(0, 10)
        : 'Data não registrada';
    final cor = _hexParaCor(corHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faixa de cor da instituição
          Container(height: 6, color: cor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Logo ou ícone genérico
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: cor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cor.withAlpha(60)),
                      ),
                      child: logoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (c, e, s) =>
                                        Icon(Icons.business, color: cor),
                              ),
                            )
                          : Icon(Icons.business, color: cor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: cor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                corHex.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Criada em: $dataCriacao',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Botões de ação
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _verUsuariosInstituicao(doc.id, nome),
                      icon: const Icon(Icons.group_outlined, size: 18),
                      label: const Text('Ver Usuários'),
                      style: TextButton.styleFrom(
                        foregroundColor: cor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          () => _iniciarEdicaoInstituicao(dados, doc.id),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _excluirInstituicao(doc.id, nome),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Excluir'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
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

  // ─── ABA AUDITORIA ───────────────────────────────────────────────────────────

  Widget _buildAuditoria() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Registros de Auditoria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              const Text(
                'Todas as instituições',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('auditoria')
                .orderBy('dataHora', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar auditoria: ${snapshot.error}'),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum registro de auditoria encontrado.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final dados = doc.data() as Map<String, dynamic>;
                    final timestamp = dados['dataHora'] as Timestamp?;
                    final dataFormatada = timestamp != null
                        ? timestamp
                            .toDate()
                            .toLocal()
                            .toString()
                            .substring(0, 16)
                        : '--/--';

                    Color acaoColor = Colors.blue;
                    if (dados['acao'] == 'CRIAR') acaoColor = Colors.green;
                    if (dados['acao'] == 'EXCLUIR') acaoColor = Colors.red;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ExpansionTile(
                        leading: Chip(
                          label: Text(
                            dados['acao'] ?? 'INFO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: acaoColor,
                          padding: EdgeInsets.zero,
                        ),
                        title: Text(
                          dados['detalhe'] ?? 'Ação registrada',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Por: ${dados['userName']} • $dataFormatada • Inst: ${dados['instituicaoId'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tela: ${dados['tela'] ?? '-'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const Divider(),
                                const Text(
                                  'Antes:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  dados['registroAntigo'] ?? 'Nenhum',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Depois:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  dados['registroNovo'] ?? 'Nenhum',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
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
          ),
        ),
      ],
    );
  }

  // ─── ABA MEU PERFIL ─────────────────────────────────────────────────────────

  Widget _buildMeuPerfil() => const MeuPerfilPage();
}

// ─── DIALOG: VER USUÁRIOS DA INSTITUIÇÃO ─────────────────────────────────────

class _DialogVerUsuarios extends StatefulWidget {
  final FirebaseFirestore db;
  final String instituicaoId;
  final String nomeInstituicao;
  final Future<void> Function({
    required String acao,
    required String tela,
    required String detalhe,
    required String antigo,
    required String novo,
    String instituicaoId,
  }) registrarAuditoria;

  const _DialogVerUsuarios({
    required this.db,
    required this.instituicaoId,
    required this.nomeInstituicao,
    required this.registrarAuditoria,
  });

  @override
  State<_DialogVerUsuarios> createState() => _DialogVerUsuariosState();
}

class _DialogVerUsuariosState extends State<_DialogVerUsuarios> {
  String _filtroRole = 'Todos';
  bool _mostrarFormNovoUsuario = false;

  final _formKeyNovoUsuario = GlobalKey<FormState>();
  final _nomeUsuarioController = TextEditingController();
  final _emailUsuarioController = TextEditingController();
  final _senhaUsuarioController = TextEditingController();
  String _roleSelecionada = 'Acess3';
  bool _ocultarSenha = true;
  bool _salvandoUsuario = false;

  @override
  void dispose() {
    _nomeUsuarioController.dispose();
    _emailUsuarioController.dispose();
    _senhaUsuarioController.dispose();
    super.dispose();
  }

  Future<void> _cadastrarUsuario() async {
    if (!_formKeyNovoUsuario.currentState!.validate()) return;
    setState(() => _salvandoUsuario = true);
    try {
      final idGerado = widget.db.collection('usuarios').doc().id;
      final novoUserMap = {
        'nome': _nomeUsuarioController.text.trim(),
        'email': _emailUsuarioController.text.trim(),
        'role': _roleSelecionada,
        'instituicaoId': widget.instituicaoId,
        'avatarEmoji': '🦁',
        'pontuacaoAcumulada': 0,
        'criadoPor': FirebaseAuth.instance.currentUser?.uid ?? 'Master',
      };
      await widget.db.collection('usuarios').doc(idGerado).set(novoUserMap);
      await widget.registrarAuditoria(
        acao: 'CRIAR',
        tela: 'Gestão de Usuários da Instituição',
        detalhe:
            'Master cadastrou usuário "${_nomeUsuarioController.text.trim()}" com perfil $_roleSelecionada na instituição "${widget.nomeInstituicao}"',
        antigo: 'Nenhum (Novo Registro)',
        novo: novoUserMap.toString(),
        instituicaoId: widget.instituicaoId,
      );
      _nomeUsuarioController.clear();
      _emailUsuarioController.clear();
      _senhaUsuarioController.clear();
      setState(() {
        _mostrarFormNovoUsuario = false;
        _roleSelecionada = 'Acess3';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar usuário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvandoUsuario = false);
    }
  }

  Future<void> _excluirUsuario(String userId, String nomeUsuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text(
              'Deseja excluir o usuário "$nomeUsuario"? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
    if (confirmar != true) return;
    try {
      await widget.db.collection('usuarios').doc(userId).delete();
      await widget.registrarAuditoria(
        acao: 'EXCLUIR',
        tela: 'Gestão de Usuários da Instituição',
        detalhe:
            'Master excluiu o usuário "$nomeUsuario" da instituição "${widget.nomeInstituicao}"',
        antigo: 'Usuário: $nomeUsuario (id: $userId)',
        novo: 'Registro excluído',
        instituicaoId: widget.instituicaoId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirDialogEditarUsuario(
    String userId,
    Map<String, dynamic> dadosUsuario,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => _DialogEditarUsuario(
            db: widget.db,
            userId: userId,
            dadosUsuario: dadosUsuario,
            nomeInstituicao: widget.nomeInstituicao,
            registrarAuditoria: widget.registrarAuditoria,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 680,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Cabeçalho do dialog
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group_outlined, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Usuários — ${widget.nomeInstituicao}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Contadores por nível
            StreamBuilder<QuerySnapshot>(
              stream: widget.db
                  .collection('usuarios')
                  .where('instituicaoId', isEqualTo: widget.instituicaoId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 8);
                final docs = snapshot.data!.docs;
                int admins = 0, acess2 = 0, acess3 = 0;
                for (final d in docs) {
                  final r = (d.data() as Map<String, dynamic>)['role'] ?? '';
                  if (r == 'Admin') admins++;
                  if (r == 'Acess2') acess2++;
                  if (r == 'Acess3') acess3++;
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildRoleChip('Total', '${docs.length}', Colors.grey),
                      _buildRoleChip('Admin', '$admins', Colors.indigo),
                      _buildRoleChip('Acess2', '$acess2', Colors.purple),
                      _buildRoleChip('Acess3 (Alunos)', '$acess3', Colors.teal),
                    ],
                  ),
                );
              },
            ),

            // Filtro e botão novo usuário
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _filtroRole,
                    onChanged: (v) => setState(() => _filtroRole = v ?? 'Todos'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todos os níveis'),
                      ),
                      DropdownMenuItem(
                        value: 'Admin',
                        child: Text('Admin'),
                      ),
                      DropdownMenuItem(
                        value: 'Acess2',
                        child: Text('Acess2'),
                      ),
                      DropdownMenuItem(
                        value: 'Acess3',
                        child: Text('Acess3'),
                      ),
                    ],
                    underline: Container(height: 1, color: Colors.grey.shade300),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(
                      () =>
                          _mostrarFormNovoUsuario = !_mostrarFormNovoUsuario,
                    ),
                    icon: Icon(
                      _mostrarFormNovoUsuario ? Icons.close : Icons.person_add_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _mostrarFormNovoUsuario ? 'Fechar' : 'Novo Usuário',
                    ),
                  ),
                ],
              ),
            ),

            // Formulário de novo usuário
            if (_mostrarFormNovoUsuario)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Form(
                  key: _formKeyNovoUsuario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cadastrar Novo Usuário',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nomeUsuarioController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo *',
                          hintText: 'Ex: João Silva',
                          isDense: true,
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Informe o nome'
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailUsuarioController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail *',
                          hintText: 'usuario@instituicao.com',
                          isDense: true,
                        ),
                        validator:
                            (v) =>
                                v == null || !v.contains('@')
                                    ? 'Insira um e-mail válido'
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _senhaUsuarioController,
                        obscureText: _ocultarSenha,
                        decoration: InputDecoration(
                          labelText: 'Senha Base *',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarSenha
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                            ),
                            onPressed:
                                () => setState(
                                  () => _ocultarSenha = !_ocultarSenha,
                                ),
                          ),
                        ),
                        validator:
                            (v) =>
                                v == null || v.length < 6
                                    ? 'Mínimo 6 caracteres'
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _roleSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Usuário *',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'Acess2',
                            child: Text('Acess2 (Gestor de Conteúdo)'),
                          ),
                          DropdownMenuItem(
                            value: 'Acess3',
                            child: Text('Acess3 (Aluno)'),
                          ),
                        ],
                        onChanged:
                            (v) => setState(
                              () => _roleSelecionada = v ?? 'Acess3',
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed:
                                () => setState(
                                  () => _mostrarFormNovoUsuario = false,
                                ),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _salvandoUsuario ? null : _cadastrarUsuario,
                            child: _salvandoUsuario
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Criar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 1),

            // Lista de usuários
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Filtramos só por instituicaoId no Firestore (evita índice
                // composto). O filtro por role é feito no cliente abaixo.
                stream: widget.db
                    .collection('usuarios')
                    .where('instituicaoId', isEqualTo: widget.instituicaoId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Filtra por role no cliente
                  final docs = snapshot.data!.docs.where((doc) {
                    if (_filtroRole == 'Todos') return true;
                    final role =
                        (doc.data() as Map<String, dynamic>)['role'] ?? '';
                    return role == _filtroRole;
                  }).toList();
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        _filtroRole == 'Todos'
                            ? 'Nenhum usuário nesta instituição.'
                            : 'Nenhum usuário com perfil "$_filtroRole".',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final u = doc.data() as Map<String, dynamic>;
                      final role = u['role'] ?? '-';

                      Color roleColor = Colors.grey;
                      if (role == 'Admin') roleColor = Colors.indigo;
                      if (role == 'Acess2') roleColor = Colors.purple;
                      if (role == 'Acess3') roleColor = Colors.teal;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withAlpha(25),
                            child: Text(
                              u['avatarEmoji'] ?? '👤',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          title: Text(
                            u['nome'] ?? 'Sem nome',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            u['email'] ?? '-',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  role,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                                backgroundColor: roleColor,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.blueGrey,
                                ),
                                tooltip: 'Editar',
                                onPressed:
                                    () => _abrirDialogEditarUsuario(doc.id, u),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                tooltip: 'Excluir',
                                onPressed:
                                    () => _excluirUsuario(
                                      doc.id,
                                      u['nome'] ?? '-',
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, String count, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 10,
        child: Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withAlpha(20),
      side: BorderSide(color: color.withAlpha(60)),
      padding: EdgeInsets.zero,
    );
  }
}

// ─── DIALOG: EDITAR USUÁRIO ───────────────────────────────────────────────────

class _DialogEditarUsuario extends StatefulWidget {
  final FirebaseFirestore db;
  final String userId;
  final Map<String, dynamic> dadosUsuario;
  final String nomeInstituicao;
  final Future<void> Function({
    required String acao,
    required String tela,
    required String detalhe,
    required String antigo,
    required String novo,
    String instituicaoId,
  }) registrarAuditoria;

  const _DialogEditarUsuario({
    required this.db,
    required this.userId,
    required this.dadosUsuario,
    required this.nomeInstituicao,
    required this.registrarAuditoria,
  });

  @override
  State<_DialogEditarUsuario> createState() => _DialogEditarUsuarioState();
}

class _DialogEditarUsuarioState extends State<_DialogEditarUsuario> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late String _roleSelecionada;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.dadosUsuario['nome'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.dadosUsuario['email'] ?? '',
    );
    _roleSelecionada = widget.dadosUsuario['role'] ?? 'Acess3';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final novosDados = {
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _roleSelecionada,
      };
      await widget.db.collection('usuarios').doc(widget.userId).update(novosDados);
      await widget.registrarAuditoria(
        acao: 'ALTERAR',
        tela: 'Gestão de Usuários da Instituição',
        detalhe:
            'Master alterou dados do usuário "${_nomeController.text.trim()}" na instituição "${widget.nomeInstituicao}"',
        antigo: widget.dadosUsuario.toString(),
        novo: novosDados.toString(),
        instituicaoId: widget.dadosUsuario['instituicaoId'] ?? 'master',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Usuário'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome Completo *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator:
                  (v) =>
                      v == null || v.trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator:
                  (v) =>
                      v == null || !v.contains('@')
                          ? 'Insira um e-mail válido'
                          : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _roleSelecionada,
              decoration: const InputDecoration(
                labelText: 'Tipo de Usuário *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                DropdownMenuItem(
                  value: 'Acess2',
                  child: Text('Acess2 (Gestor)'),
                ),
                DropdownMenuItem(
                  value: 'Acess3',
                  child: Text('Acess3 (Aluno)'),
                ),
              ],
              onChanged: (v) => setState(() => _roleSelecionada = v ?? 'Acess3'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
