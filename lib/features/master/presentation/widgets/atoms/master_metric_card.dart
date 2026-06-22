import 'package:flutter/material.dart';

/// Átomo básico e altamente reutilizável para exibição de métricas visuais 
/// no ecossistema do Painel Master.
class MasterMetricCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color cor;
  final IconData icone;

  const MasterMetricCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.cor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: cor, width: 6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 28),
            const Spacer(),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              valor,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
