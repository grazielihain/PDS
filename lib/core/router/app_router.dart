import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';

// Importações temporárias das telas para o roteador não dar erro de código.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login', // O aplicativo sempre começará na tela de login
    routes: [
      // 1. Rota da Tela de Login
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // 2. Rota do Painel do Administrador (Admin / Master)
      GoRoute(
        path: '/admin',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Painel Administrativo (Admin)')),
        ),
      ),

      // 3. Rota da Seleção do Quiz (Estudante - Acess3)
      GoRoute(
        path: '/quiz-selection',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Seleção de Simulados'))),
      ),

      // 4. Rota do Motor do Quiz (A Prova em execução)
      GoRoute(
        path: '/quiz-run',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Simulado em Andamento'))),
      ),

      // 5. Rota do Resultado Final e Histórico
      GoRoute(
        path: '/resultado',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Resultados e Certificado PDF')),
        ),
      ),
    ],
    // Tratamento de erro caso o usuário digite uma URL que não existe
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página não encontrada!'))),
  );
}
