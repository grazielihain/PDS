import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/motor_prova_service.dart';

class ConfigurarSimuladoPage extends StatefulWidget {
  final String alunoInstituicaoId;

  const ConfigurarSimuladoPage({super.key, required this.alunoInstituicaoId});

  @override
  State<ConfigurarSimuladoPage> createState() => _ConfigurarSimuladoPageState();
}

class _ConfigurarSimuladoPageState extends State<ConfigurarSimuladoPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController(text: '10');
  final _motorService = MotorProvaService();

  String _assuntoSelecionado = 'A01';
  bool _isVerificandoEstoque = false;
  int _estoqueDisponivel = 0;

  // 🎨 Paleta de Cores Oficial Rumo Quiz
  final Color _azulMarinho = const Color(0xFF1E3A8A);
  final Color _verdeEsmeralda = const Color(0xFF10B981);
  final Color _laranjaClaro = const Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _atualizarEstoqueDisponivel();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  /// US 13: Consulta o banco e ajusta o teto físico na interface em tempo real
  Future<void> _atualizarEstoqueDisponivel() async {
    setState(() => _isVerificandoEstoque = true);

    final estoque = await _motorService.verificarEstoqueQuestoes(
      instituicaoId: widget.alunoInstituicaoId,
      assuntoId: _assuntoSelecionado,
    );

    setState(() {
      _estoqueDisponivel = estoque;
      _isVerificandoEstoque = false;

      final qtdAtual = int.tryParse(_quantidadeController.text) ?? 0;
      if (qtdAtual > _estoqueDisponivel && _estoqueDisponivel > 0) {
        _quantidadeController.text = _estoqueDisponivel.toString();
      }
    });
  }

  void _iniciarProva() async {
    if (!_formKey.currentState!.validate()) return;

    final qtd = int.parse(_quantidadeController.text);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final questoesFinais = await _motorService.gerarSimuladoOtimizado(
      instituicaoId: widget.alunoInstituicaoId,
      assuntoId: _assuntoSelecionado,
      quantidadeSolicitada: qtd,
    );

    if (!mounted) return;
    Navigator.pop(context); // Fecha o loading do Dialog

    if (questoesFinais.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Nenhuma questão localizada para os parâmetros informados. ⚠️',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: _laranjaClaro,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Prova gerada com sucesso! ${questoesFinais.length} questões ordenadas em memória. 🚀',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _verdeEsmeralda,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Configurar Simulado',
          style: TextStyle(color: _azulMarinho, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: _azulMarinho),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'Prepare o seu Exame',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _azulMarinho,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione o assunto desejado. O nosso motor inteligente montará um caderno personalizado para o seu treino.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 1. SELEÇÃO DE ASSUNTO
                  DropdownButtonFormField<String>(
                    initialValue: _assuntoSelecionado,
                    decoration: InputDecoration(
                      labelText: 'Assunto do Simulado',
                      labelStyle: TextStyle(color: _azulMarinho),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _azulMarinho, width: 2),
                      ),
                    ),
                    // ✅ CORRIGIDO: O <String> vai antes dos parênteses, e mantemos o "value:" normal lá dentro
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'A01',
                        child: Text('Matemática Financeira'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'A02',
                        child: Text('Estruturas de Dados'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'A03',
                        child: Text('Engenharia de Software'),
                      ),
                    ],
                    onChanged: (String? novoAssunto) {
                      if (novoAssunto != null) {
                        setState(() => _assuntoSelecionado = novoAssunto);
                        _atualizarEstoqueDisponivel();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. INDICADOR DE ESTOQUE (US 13)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _azulMarinho.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _azulMarinho.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: _azulMarinho,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isVerificandoEstoque
                              ? const SizedBox(
                                  height: 4,
                                  child: LinearProgressIndicator(),
                                )
                              : Text(
                                  'Disponível nesta instituição: $_estoqueDisponivel questões.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _azulMarinho,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. CAMPO DE QUANTIDADE COM INDICAÇÃO DO MÁXIMO
                  TextFormField(
                    controller: _quantidadeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Quantidade de Questões',
                      helperText:
                          'Teto máximo físico baseado no estoque: $_estoqueDisponivel',
                      helperStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _azulMarinho, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a quantidade';
                      }
                      final qtd = int.tryParse(value) ?? 0;
                      if (qtd <= 0) {
                        return 'O simulado precisa de no mínimo 1 questão';
                      }
                      if (qtd > _estoqueDisponivel) {
                        return 'Quantidade excede o estoque físico disponível ($_estoqueDisponivel)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // 4. BOTÃO DE SUBMIT INSTITUCIONAL
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isVerificandoEstoque ? null : _iniciarProva,
                      icon: const Icon(Icons.play_circle_filled, size: 20),
                      label: const Text(
                        'Gerar e Iniciar Simulado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _azulMarinho,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
