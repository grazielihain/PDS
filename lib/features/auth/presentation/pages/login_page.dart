import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/atoms/custom_button.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Chave global para controlar e validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar o texto digitado pelo usuário
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🟢 ESTADO DO OLHO MÁGICO (Inicia ocultando a senha)
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Boa prática: limpa os controladores da memória quando a tela é fechada
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // Só avança se todas as validações locais passarem (poupando requisições no Firebase)
    if (_formKey.currentState!.validate()) {
      // Chama a função de login do Provider do Riverpod
      ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuta e reage às mudanças de estado da Autenticação
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthSuccess) {
        // Se o login deu certo, verifica o perfil e redireciona usando o GoRouter
        if (next.user.isAdminOrMaster) {
          context.go('/admin'); // Vai para a área do Admin
        } else {
          context.go(
            '/quiz-selection',
          ); // Estudante vai para a seleção de simulados
        }
      } else if (next is AuthError) {
        // Se deu erro (senha errada, etc), exibe um alerta visual na tela
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    // Obtém o estado atual para saber se deve mostrar o carregando no botão
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 400,
            ), // Limita a largura para telas Web
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Título do App
                  const Icon(Icons.school, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Rumo Quiz',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Faça login para acessar seus simulados',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Campo de E-mail
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email),
                    ),
                    // Injeta a validação centralizada da Core
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Campo de Senha (🟢 CORRIGIDO COM OLHO MÁGICO)
                  TextFormField(
                    controller: _passwordController,
                    obscureText:
                        _obscurePassword, // Vinculado ao estado dinâmico
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock),
                      // 🟢 ÍCONE INTERATIVO ADICIONADO
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    // Injeta a validação centralizada da Core
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 24),

                  // Átomo Reutilizável (CustomButton) trabalhando junto com o Riverpod
                  CustomButton(
                    text: 'Entrar',
                    isLoading: isLoading,
                    onPressed: _submit,
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
