import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/widgets/organisms/menu_lateral_organism.dart';

class CadastroUsuarioPage extends ConsumerStatefulWidget {
  const CadastroUsuarioPage({super.key});

  @override
  ConsumerState<CadastroUsuarioPage> createState() => _CadastroUsuarioPageState();
}

class _CadastroUsuarioPageState extends ConsumerState<CadastroUsuarioPage> {
  final _formKeyCadastro = GlobalKey<FormState>();
  
  // Controladores dos inputs
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _instituicaoController = TextEditingController();
  
  String _roleSelecionada = 'Acess3'; // Padrão (Estudante/Aluno)
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _instituicaoController.dispose();
    super.dispose();
  }

  /// Registra o usuário diretamente no Firestore (Subtarefa 2.2)
  Future<void> _cadastrarUsuario(String roleCriador) async {
    if (!_formKeyCadastro.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      // Força a regra de negócio mesmo se o front falhar: Acess2 só gera Acess3
      final roleFinal = (roleCriador == 'Acess2') ? 'Acess3' : _roleSelecionada;

      await FirebaseFirestore.instance.collection('usuarios').add({
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'instituicao': _instituicaoController.text.trim(),
        'role': roleFinal,
        'avatarEmoji': '👨‍🎓', // Padrão inicial
        'criadoEm': FieldValue.serverTimestamp(),
        'criadoPorRole': roleCriador,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Novo usuário registrado com sucesso!'), backgroundColor: Colors.green),
        );
        
        // Limpa os campos após salvamento bem-sucedido
        _nomeController.clear();
        _emailController.clear();
        _instituicaoController.clear();
        setState(() {
          _roleSelecionada = 'Acess3';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🧠 REATIVIDADE SEGURA: Captura a role de quem está operando o sistema
    final usuarioAsync = ref.watch(usuarioStreamProvider);
    final dadosUsuario = usuarioAsync.value as Map<String, dynamic>?;
    final String roleCriador = (dadosUsuario?['role'] ?? 'Acesso').toString().trim();

    final bool ehAdmin = roleCriador == 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo Unificado de Cadastro'),
        backgroundColor: ehAdmin ? Colors.blue.shade800 : Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Torna o painel amigável e responsivo para Web (lado a lado) ou Mobile (vertical)
          final bool usarLadoALado = constraints.maxWidth > 900;

          Widget formularioWidget = Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKeyCadastro,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👤 Registrar Novo Usuário',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Insira o nome' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail de Acesso', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                      validator: (value) => value == null || !value.contains('@') ? 'Insira um e-mail válido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instituicaoController,
                      decoration: const InputDecoration(labelText: 'Instituição / Empresa', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Insira a instituição' : null,
                    ),
                    const SizedBox(height: 16),

                    // 🛡️ SUBTAREFA 2.2: Validação de Visibilidade baseada no Criador
                    if (ehAdmin) ...[
                      DropdownButtonFormField<String>(
                        value: _roleSelecionada,
                        decoration: const InputDecoration(labelText: 'Nível de Acesso (Role)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.gavel)),
                        items: const [
                          DropdownMenuItem(value: 'Acess2', child: Text('Acess2 (Gestor / Criador de Provas)')),
                          DropdownMenuItem(value: 'Acess3', child: Text('Acess3 (Estudante / Aluno)')),
                        ],
                        onChanged: (val) => setState(() => _roleSelecionada = val ?? 'Acess3'),
                      ),
                    ] else ...[
                      // Se for Acess2, oculta o seletor e exibe apenas um informativo travado
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              'Nível de Acesso: Travado em Acess3 (Aluno)',
                              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _salvando ? null : () => _cadastrarUsuario(roleCriador),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ehAdmin ? Colors.blue.shade800 : Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: _salvando 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.person_add_alt_1),
                        label: Text(_salvando ? 'Salvando registro...' : 'Concluir Cadastro', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          // Componente da Lista dos Últimos Usuários Criados (Otimizado para Plano Grátis)
          Widget listaUltimosUsuarios = Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Últimos Registros Criados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  StreamBuilder<QuerySnapshot>(
                    // 🛡️ TRAVA PLANO GRÁTIS: limit(10) garante baixo consumo de leituras no Spark Plan
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .orderBy('criadoEm', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Nenhum usuário cadastrado recentemente.', style: TextStyle(color: Colors.grey)),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final userMap = docs[index].data() as Map<String, dynamic>;
                          final nome = userMap['nome'] ?? 'Sem Nome';
                          final email = userMap['email'] ?? 'Sem Email';
                          final role = userMap['role'] ?? 'Acess3';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: role == 'Acess2' ? Colors.amber.shade100 : Colors.blue.shade50,
                              child: Icon(role == 'Acess2' ? Icons.assignment_ind : Icons.school, size: 20, color: role == 'Acess2' ? Colors.amber.shade900 : Colors.blue.shade900),
                            ),
                            title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: role == 'Acess2' ? Colors.amber.shade100 : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  color: role == 'Acess2' ? Colors.amber.shade900 : Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: usarLadoALado
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: formularioWidget),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: listaUltimosUsuarios),
                    ],
                  )
                : Column(
                    children: [
                      formularioWidget,
                      const SizedBox(height: 16),
                      listaUltimosUsuarios,
                    ],
                  ),
          );
        },
      ),
    );
  }
}
