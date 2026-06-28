import 'package:flutter/material.dart';

/// Cabeçalho padronizado exibido no topo de cada aba do painel.
/// Mostra o nome da aba (igual à entrada do menu lateral) e uma breve
/// descrição do conteúdo ou função da aba.
Widget tabPageHeader(String title, String description) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
      const Divider(height: 1, thickness: 1),
    ],
  );
}
