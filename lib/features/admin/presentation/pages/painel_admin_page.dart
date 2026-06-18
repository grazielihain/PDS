import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PainelAdminPage extends StatefulWidget {
  final String substituicaoInstituicaoId;

  const PainelAdminPage({super.key, required this.substituicaoInstituicaoId});

  @override
  State<PainelAdminPage> createState() => _PainelAdminPageState();
}

class _PainelAdminPageState extends State<PainelAdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estados para aba Identidade/White Label
  final _formKeyWhiteLabel = GlobalKey<FormState>();
  final _nomeEscolaController = TextEditingController();
  final _corHexController = TextEditingController();
  List<String> _patrocinadoresUrls = [];
  bool _salvandoWhiteLabel = false;

  // Estados para aba Novos Usuários
  final _formKeyUsuario = GlobalKey<FormState>();
  final _nomeUsuarioController = TextEditingController();
  final _emailUsuarioController = TextEditingController();
  final _senhaUsuarioController = TextEditingController();
  String _roleSelecionada = 'Acess3';
  bool _ocultarSenha = true;
  bool _salvandoUsuario = false;

  // Estados para Controle Master (Subtarefa 1.3)
  final _nomeNovaInstituicaoController = TextEditingController();
  final _corNovaInstituicaoController = TextEditingController();

  String _currentRole = 'Acess2';
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _determinarRoleEInicializarTabs();
    _carregarDadosIdentidadeVisual();
  }

  Future<void> _determinarRoleEInicializarTabs() async {
    try {
      final doc = await _firestore
          .collection('usuarios')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _currentRole = (doc.data()?['role'] ?? 'Acess2').toString().trim();
          // Se for Master, ganha 3 abas extras de gerenciamento macro (Total 7)
          int abasCount = _currentRole == 'Master' ? 7 : 4;
          _tabController = TabController(length: abasCount, vsync: this);
          _loadingRole = false;
        });
      } else {
        _inicializarAbasPadrao();
      }
    } catch (e) {
      _inicializarAbasPadrao();
    }
  }

  void _inicializarAbasPadrao() {
    if (mounted) {
      setState(() {
        _tabController = TabController(length: 4, vsync: this);
        _loadingRole = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeEscolaController.dispose();
    _corHexController.dispose();
    _nomeUsuarioController.dispose();
    _emailUsuarioController.dispose();
    _senhaUsuarioController.dispose();
    _nomeNovaInstituicaoController.dispose();
    _corNovaInstituicaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIdentidadeVisual() async {
    try {
      final doc = await _firestore
          .collection('instituicoes')
          .doc(widget.substituicaoInstituicaoId)
          .get();
      if (doc.exists && mounted) {
        final dados = doc.data();
        setState(() {
          _nomeEscolaController.text = dados?['nome'] ?? '';
          _corHexController.text = dados?['corHex'] ?? '#1E88E5';
          _patrocinadoresUrls = List<String>.from(dados?['patrocinios'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar White Label: $e');
    }
  }

  Future<void> _salvarIdentidadeVisual() async {
    if (!_formKeyWhiteLabel.currentState!.validate()) return;

    setState(() => _salvandoWhiteLabel = true);
    try {
      final dadosAntigos = await _firestore
          .collection('instituicoes')
          .doc(widget.substituicaoInstituicaoId)
          .get();

      final novosDados = {
        'nome': _nomeEscolaController.text.trim(),
        'corHex': _corHexController.text.trim(),
        'patrocinios': _patrocinadoresUrls,
      };

      await _firestore
          .collection('instituicoes')
          .doc(widget.substituicaoInstituicaoId)
          .set(novosDados, SetOptions(merge: true));

      await _registrarAuditoria(
        acao: 'ALTERAR',
        tela: 'Painel Administrativo / White Label',
        detalhe:
            'Alterou a identidade visual e nome da instituição para "${_nomeEscolaController.text}"',
        antigo: dadosAntigos.data()?.toString() ?? 'Nenhum',
        novo: novosDados.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identidade da instituição salva com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar configurações: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvandoWhiteLabel = false);
    }
  }

  Future<void> _cadastrarNovoUsuario(String roleCriador) async {
    if (!_formKeyUsuario.currentState!.validate()) return;

    setState(() => _salvandoUsuario = true);
    try {
      final idGerado = _firestore.collection('usuarios').doc().id;

      final novoUserMap = {
        'nome': _nomeUsuarioController.text.trim(),
        'email': _emailUsuarioController.text.trim(),
        'role': roleCriador == 'Acess2' ? 'Acess3' : _roleSelecionada,
        'instituicaoId': widget.substituicaoInstituicaoId,
        'avatarEmoji': '🦁',
        'pontuacaoAcumulada': 0,
        'criadoPor': FirebaseAuth.instance.currentUser?.uid ?? 'Admin',
      };

      await _firestore.collection('usuarios').doc(idGerado).set(novoUserMap);

      await _registrarAuditoria(
        acao: 'CRIAR',
        tela: 'Cadastro de novos Usuários',
        detalhe:
            'Cadastrou o usuário ${_nomeUsuarioController.text} com perfil ${novoUserMap['role']}',
        antigo: 'Nenhum (Novo Registro)',
        novo: novoUserMap.toString(),
      );

      _nomeUsuarioController.clear();
      _emailUsuarioController.clear();
      _senhaUsuarioController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Novo usuário registrado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar usuário: $e')));
      }
    } finally {
      if (mounted) setState(() => _salvandoUsuario = false);
    }
  }

  Future<void> _registrarAuditoria({
    required String acao,
    required String tela,
    required String detalhe,
    required String antigo,
    required String novo,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _firestore.collection('auditoria').add({
        'instituicaoId': widget.substituicaoInstituicaoId,
        'userId': user?.uid ?? 'desconhecido',
        'userName': user?.email ?? 'Administrador',
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

  // --- MÉTODOS COMPLEMENTARES MASTER (SUBTAREFAS 1.1, 1.2, 1.3) ---

  Widget _buildHomeMaster() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('instituicoes').snapshots(),
      builder: (context, snapInst) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('usuarios').snapshots(),
          builder: (context, snapUser) {
            int totalInst = snapInst.hasData ? snapInst.data!.docs.length : 0;
            int totalAcess2 = 0;
            int totalAcess3 = 0;

            if (snapUser.hasData) {
              for (var doc in snapUser.data!.docs) {
                String r = (doc.data() as Map<String, dynamic>)['role'] ?? '';
                if (r == 'Acess2') totalAcess2++;
                if (r == 'Acess3') totalAcess3++;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visão Macro do Ecossistema',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Métricas gerais consolidadas em tempo real.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildMetricCard(
                            title: 'Instituições Ativas',
                            value: totalInst.toString(),
                            icon: Icons.business_outlined,
                            color: Colors.blue,
                            width: isMobile ? constraints.maxWidth : 220,
                          ),
                          _buildMetricCard(
                            title: 'Gestores (Acess2)',
                            value: totalAcess2.toString(),
                            icon: Icons.manage_accounts_outlined,
                            color: Colors.orange,
                            width: isMobile ? constraints.maxWidth : 220,
                          ),
                          _buildMetricCard(
                            title: 'Alunos (Acess3)',
                            value: totalAcess3.toString(),
                            icon: Icons.school_outlined,
                            color: Colors.green,
                            width: isMobile ? constraints.maxWidth : 220,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControladoriaMaster() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('auditoria')
          .orderBy('dataHora', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        Map<String, int> consumoPorUser = {};
        for (var doc in snapshot.data!.docs) {
          var d = doc.data() as Map<String, dynamic>;
          String u = d['userName'] ?? 'Desconhecido';
          consumoPorUser[u] = (consumoPorUser[u] ?? 0) + 1;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Consumo de Requisições de Escrita/Leitura (Auditoria)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Ações monitoradas nas coleções ativas para proteção da cota grátis.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...consumoPorUser.entries.map(
              (e) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.analytics_outlined),
                  ),
                  title: Text(e.key),
                  subtitle: Text(
                    'Operações persistidas na sessão corrente: ${e.value} requisições',
                  ),
                  trailing: Text(
                    '${(e.value * 100 / snapshot.data!.docs.length).toStringAsFixed(1)}% do uso',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGerenciamentoInstituicoes() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Árvore de Instituições Vinculadas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _abrirModalCriarInstituicao,
                icon: const Icon(Icons.add),
                label: const Text('Nova Escola'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('instituicoes').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, idx) {
                  final inst = docs[idx].data() as Map<String, dynamic>;
                  final id = docs[idx].id;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(
                          int.parse(
                            (inst['corHex'] ?? '#1E88E5').replaceAll(
                              '#',
                              '0xFF',
                            ),
                          ),
                        ),
                        child: const Icon(Icons.business, color: Colors.white),
                      ),
                      title: Text(inst['nome'] ?? 'Sem nome'),
                      subtitle: Text('ID: $id'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Alterar Cadastro'),
                                onPressed: () =>
                                    _abrirModalEditarInstituicao(id, inst),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Excluir',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () => _verificarEExcluirInstituicao(
                                  id,
                                  inst['nome'] ?? '',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _abrirModalCriarInstituicao() {
    _nomeNovaInstituicaoController.clear();
    _corNovaInstituicaoController.text = '#1E88E5';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar Instituição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeNovaInstituicaoController,
              decoration: const InputDecoration(labelText: 'Nome da Escola'),
            ),
            TextField(
              controller: _corNovaInstituicaoController,
              decoration: const InputDecoration(labelText: 'Cor Hexadecimal'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nomeNovaInstituicaoController.text.trim().isEmpty) return;
              await _firestore.collection('instituicoes').add({
                'nome': _nomeNovaInstituicaoController.text.trim(),
                'corHex': _corNovaInstituicaoController.text.trim(),
                'patrocinios': [],
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _abrirModalEditarInstituicao(String id, Map<String, dynamic> dados) {
    _nomeNovaInstituicaoController.text = dados['nome'] ?? '';
    _corNovaInstituicaoController.text = dados['corHex'] ?? '#1E88E5';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar Cadastro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeNovaInstituicaoController,
              decoration: const InputDecoration(labelText: 'Nome da Escola'),
            ),
            TextField(
              controller: _corNovaInstituicaoController,
              decoration: const InputDecoration(labelText: 'Cor Hexadecimal'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('instituicoes').doc(id).update({
                'nome': _nomeNovaInstituicaoController.text.trim(),
                'corHex': _corNovaInstituicaoController.text.trim(),
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _verificarEExcluirInstituicao(String id, String nome) async {
    final dependencias = await _firestore
        .collection('usuarios')
        .where('instituicaoId', isEqualTo: id)
        .limit(1)
        .get();

    if (dependencias.docs.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 40,
          ),
          title: const Text('Operação Bloqueada'),
          content: Text(
            'A instituição "$nome" possui usuários filhos vinculados e não pode ser removida para evitar órfãos estruturais no ecossistema NoSQL.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Compreendido'),
            ),
          ],
        ),
      );
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Deseja realmente remover permanentemente a instituição "$nome"? Esta ação não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _firestore.collection('instituicoes').doc(id).delete();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'Excluir de Vez',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  // --- BUILD PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isMaster = _currentRole == 'Master';

    return Scaffold(
      appBar: AppBar(
        title: Text(isMaster ? 'Painel Master Global' : 'Painel de Controle'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            if (isMaster) ...const [
              Tab(
                icon: Icon(Icons.admin_panel_settings_outlined),
                text: 'Home Master',
              ),
              Tab(
                icon: Icon(Icons.account_balance_outlined),
                text: 'Controladoria',
              ),
              Tab(icon: Icon(Icons.lan_outlined), text: 'Instituições'),
            ],
            const Tab(
              icon: Icon(Icons.analytics_outlined),
              text: 'Home / Relatórios',
            ),
            const Tab(
              icon: Icon(Icons.palette_outlined),
              text: 'Painel Administrativo',
            ),
            const Tab(
              icon: Icon(Icons.gavel_outlined),
              text: 'Auditoria Interna',
            ),
            const Tab(
              icon: Icon(Icons.person_add_alt_1_outlined),
              text: 'Novos Usuários',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (isMaster) ...[
            _buildHomeMaster(),
            _buildControladoriaMaster(),
            _buildGerenciamentoInstituicoes(),
          ],
          _buildHomeRelatorios(_currentRole),
          _buildPainelAdministrativo(_currentRole),
          _buildAuditoriaInterna(),
          _buildCadastroUsuarios(_currentRole),
        ],
      ),
    );
  }

  Widget _buildHomeRelatorios(String roleCriador) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            roleCriador == 'Acess2'
                ? 'Painel Acess2'
                : 'Painel do Administrador',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Gerencie conteúdo e acompanhe resultados retrospectivos.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final useVertical = constraints.maxWidth < 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard(
                    title: roleCriador == 'Acess2'
                        ? 'Questões que Cadastrou'
                        : 'Total de Questões',
                    value: '142',
                    icon: Icons.description_outlined,
                    color: Colors.blue,
                    width: useVertical ? constraints.maxWidth : 240,
                  ),
                  _buildMetricCard(
                    title: 'Provas Respondidas',
                    value: '1.240',
                    icon: Icons.assignment_turned_in_outlined,
                    color: Colors.green,
                    width: useVertical ? constraints.maxWidth : 240,
                  ),
                  _buildMetricCard(
                    title: 'Média de Acertos Alunos',
                    value: '74.2%',
                    icon: Icons.trending_up_outlined,
                    color: Colors.purple,
                    width: useVertical ? constraints.maxWidth : 240,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Gráficos Comparativos (Últimos 7 dias)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                '[Gráfico fl_chart responsivo injetado assincronamente]',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
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

  Widget _buildPainelAdministrativo(String roleCriador) {
    if (roleCriador == 'Acess2') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Acesso Negado.\nApenas o Administrador Master ou Admin da instituição possui autoridade para configurar a identidade visual e regras globais do White Label.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyWhiteLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identidade Visual do White Label',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _nomeEscolaController,
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa / Escola *',
                hintText: 'Ex: Faculdade Impacto',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Insira o nome da Instituição para ajuste responsivo'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _corHexController,
              decoration: const InputDecoration(
                labelText: 'Cor da Aplicação (Hexadecimal) *',
                hintText: 'Ex: #FF5733',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Informe a cor primária';
                if (!v.startsWith('#') || v.length != 7)
                  return 'Formato inválido. Use # seguido de 6 caracteres hexadecimais';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patrocinadores no Rodapé (${_patrocinadoresUrls.length}/5)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _patrocinadoresUrls.length >= 5
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Limite máximo de 5 patrocinadores atingido.',
                            ),
                          ),
                        )
                      : () => setState(
                          () => _patrocinadoresUrls.add(
                            'https://picsum.photos/200/50?random=${_patrocinadoresUrls.length}',
                          ),
                        ),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Anexar Logo (Até 2MB)'),
                ),
              ],
            ),
            if (_patrocinadoresUrls.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Nenhum anúncio. O sistema preencherá automaticamente com as marcas padrão.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patrocinadoresUrls.length,
              itemBuilder: (context, idx) => Card(
                child: ListTile(
                  leading: const Icon(Icons.image),
                  title: Text(
                    'Patrocinador #${idx + 1}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    _patrocinadoresUrls[idx],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        setState(() => _patrocinadoresUrls.removeAt(idx)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvandoWhiteLabel ? null : _salvarIdentidadeVisual,
                child: _salvandoWhiteLabel
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar Identidade Visual'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditoriaInterna() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('auditoria')
          .where('instituicaoId', isEqualTo: widget.substituicaoInstituicaoId)
          .orderBy('dataHora', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text(
              'Erro ao carregar trilha de auditoria: ${snapshot.error}',
            ),
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma atividade registrada nesta instituição.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Scrollbar(
          thumbVisibility: true,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final dados = doc.data() as Map<String, dynamic>;
              final timestamp = dados['dataHora'] as Timestamp?;
              final dataFormatada = timestamp != null
                  ? timestamp.toDate().toLocal().toString().substring(0, 16)
                  : '--/--';

              Color acaoColor = Colors.blue;
              if (dados['acao'] == 'CRIAR') acaoColor = Colors.green;
              if (dados['acao'] == 'EXCLUIR') acaoColor = Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
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
                    dados['detalhe'] ?? 'Ação realizada no sistema',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Por: ${dados['userName']} • $dataFormatada',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tela de Origem: ${dados['tela']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Divider(),
                          const Text(
                            'Dados Antes da Modificação:',
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
                            'Dados Após Modificação:',
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
    );
  }

  Widget _buildCadastroUsuarios(String roleCriador) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        Widget formulario = Form(
          key: _formKeyUsuario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inclusão de Novos Usuários',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomeUsuarioController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo *',
                  hintText: 'Ex: João Silva',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailUsuarioController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail de Acesso *',
                  hintText: 'usuario@instituicao.com',
                ),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Insira um e-mail corporativo válido'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senhaUsuarioController,
                obscureText: _ocultarSenha,
                decoration: InputDecoration(
                  labelText: 'Senha Base *',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarSenha = !_ocultarSenha),
                  ),
                ),
                validator: (v) => v == null || v.length < 6
                    ? 'A senha deve conter no mínimo 6 caracteres'
                    : null,
              ),
              const SizedBox(height: 12),
              if (roleCriador != 'Acess2') ...[
                DropdownButtonFormField<String>(
                  value: _roleSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Nível de Acesso *',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Acess2',
                      child: Text('Acess2 (Gestor de Conteúdo)'),
                    ),
                    DropdownMenuItem(
                      value: 'Acess3',
                      child: Text('Acess3 (Aluno / Estudante)'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _roleSelecionada = v ?? 'Acess3'),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Nivel de acesso configurado automaticamente como: ACESS3 (Aluno)',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvandoUsuario
                      ? null
                      : () => _cadastrarNovoUsuario(roleCriador),
                  child: _salvandoUsuario
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrar Usuário'),
                ),
              ),
            ],
          ),
        );

        Widget listaRetrospectiva = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Últimos Usuários Criados pela Instituição',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('usuarios')
                    .where(
                      'instituicaoId',
                      isEqualTo: widget.substituicaoInstituicaoId,
                    )
                    .limit(15)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text(
                      'Nenhum usuário cadastrado até o momento.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final u = docs[idx].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.person_outline),
                          title: Text(u['nome'] ?? 'Sem nome'),
                          subtitle: Text('${u['email']} • Nível: ${u['role']}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );

        if (isMobile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                formulario,
                const Divider(height: 40),
                SizedBox(height: 300, child: listaRetrospectiva),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SingleChildScrollView(child: formulario)),
              const VerticalDivider(width: 32),
              Expanded(child: listaRetrospectiva),
            ],
          ),
        );
      },
    );
  }
}
