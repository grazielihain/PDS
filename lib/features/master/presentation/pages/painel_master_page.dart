import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PainelMasterPage extends StatefulWidget {
  const PainelMasterPage({super.key});

  @override
  State<PainelMasterPage> createState() => _PainelMasterPageState();
}

class _PainelMasterPageState extends State<PainelMasterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nomeInstituicaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🛡️ CORRIGIDO: Modificado de 2 para 3 abas para incluir "Instituições"
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeInstituicaoController.dispose();
    super.dispose();
  }

  /// Verifica filhos órfãos e deleta se seguro (Subtarefa 1.3)
  Future<void> _tentarExcluirInstituicao(String id, String nome) async {
    try {
      // 🕵️ Varrer se existem usuários vinculados a esta instituição
      final usuariosVinculados = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('instituicaoId', isEqualTo: id)
          .limit(1) // Só precisamos saber se existe pelo menos 1
          .get();

      if (!mounted) return;

      // 🛑 TRAVA DE SEGURANÇA: Se houver filhos, impede e abre o Prompt/Modal
      if (usuariosVinculados.docs.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text('Ação Bloqueada!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'A instituição "$nome" possui usuários (filhos) ativamente vinculados a ela.\n\n'
              'Para evitar registros órfãos e corrupção do banco de dados, você deve primeiro remover ou realocar todos os usuários desta instituição antes de poder excluí-la.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Compreendi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }

      // Se passou da trava, pode deletar com segurança
      await FirebaseFirestore.instance.collection('instituicoes').doc(id).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🏛️ Instituição "$nome" removida com sucesso.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Master & Controladoria'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Home Master'),
            Tab(icon: Icon(Icons.analytics), text: 'Controladoria'),
            Tab(icon: Icon(Icons.account_balance), text: 'Instituições'), // 👈 Nova Aba!
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeMasterTab(),
          _buildControladoriaTab(),
          _buildInstituicoesTab(), // 👈 Novo método de visualização
        ],
      ),
    );
  }

  Widget _buildHomeMasterTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;
        int countAdmin = users.where((d) => d['role'] == 'Admin').length;
        int countAcess2 = users.where((d) => d['role'] == 'Acess2').length;
        int countAcess3 = users.where((d) => d['role'] == 'Acess3').length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWeb = constraints.maxWidth > 600;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visão Geral do Sistema', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWeb ? 4 : 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isWeb ? 1.5 : 1.2,
                    children: [
                      _buildMacroCard('Instituições', 'Ativas', Colors.blue, Icons.business),
                      _buildMacroCard('Admins', countAdmin.toString(), Colors.amber.shade800, Icons.gavel),
                      _buildMacroCard('Acess2 (Gestores)', countAcess2.toString(), Colors.green, Icons.assignment_ind),
                      _buildMacroCard('Acess3 (Alunos)', countAcess3.toString(), Colors.purple, Icons.school),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMacroCard(String titulo, String valor, Color cor, IconData icone) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: cor, width: 6)), borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 28),
            const Spacer(),
            Text(titulo, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildControladoriaTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('estatisticas_uso').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final instId = docs[index].id;
            final escritas = data['totalEscritas'] ?? 0;
            final leituras = data['totalLeituras'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.analytics_outlined, color: Colors.red),
                title: Text('ID Instituição: $instId', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Leituras Estimadas: $leituras | Escritas/Logs Efetuados: $escritas'),
                trailing: CircularProgressIndicator(
                  value: (escritas / 20000),
                  backgroundColor: Colors.grey.shade200,
                  color: escritas > 15000 ? Colors.red : Colors.green,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // SUBTAREFA 1.3: Árvore de Instituições e Validação de Exclusão Perigosa
  // ===========================================================================
  Widget _buildInstituicoesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('instituicoes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏛️ Cadastro de Corporações / Escolas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
              const SizedBox(height: 12),
              // Formulário de inserção rápida de Instituição
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nomeInstituicaoController,
                      decoration: const InputDecoration(labelText: 'Nome da Nova Instituição', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_nomeInstituicaoController.text.trim().isEmpty) return;
                      await FirebaseFirestore.instance.collection('instituicoes').add({
                        'nome': _nomeInstituicaoController.text.trim(),
                        'criadoEm': FieldValue.serverTimestamp(),
                      });
                      _nomeInstituicaoController.clear();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, minimumSize: const Size(0, 54),),
                    child: const Text('Cadastrar'),
                  )
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final inst = docs[index];
                    final nome = inst['nome'] ?? 'Sem nome';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.corporate_fare, color: Colors.blue),
                        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${inst.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                _nomeInstituicaoController.text = nome;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Alterar Nome'),
                                    content: TextField(controller: _nomeInstituicaoController, decoration: const InputDecoration(border: OutlineInputBorder())),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                      TextButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('instituicoes').doc(inst.id).update({'nome': _nomeInstituicaoController.text.trim()});
                                          _nomeInstituicaoController.clear();
                                          if (ctx.mounted) Navigator.pop(ctx);
                                        },
                                        child: const Text('Salvar'),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _tentarExcluirInstituicao(inst.id, nome),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}