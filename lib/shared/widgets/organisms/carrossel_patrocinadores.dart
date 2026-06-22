import 'package:flutter/material.dart';

/// [ORGANISMO] CarrosselPatrocinadores
/// Rodapé White Label Dinâmico, Reativo e Defensivo contra URLs nulas ou corrompidas.
/// Garante estritamente o preenchimento de até 5 slots (Prompt 4).
class CarrosselPatrocinadores extends StatelessWidget {
  final List<String> logosUrls;
  final Color? corCustomizadaInstituicao; 

  const CarrosselPatrocinadores({
    super.key,
    this.logosUrls = const [],
    this.corCustomizadaInstituicao,
  });

  @override
  Widget build(BuildContext context) {
    final corFundo = corCustomizadaInstituicao ?? Colors.blue.shade700;

    final corTextoEIcone =
        ThemeData.estimateBrightnessForColor(corFundo) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    List<Widget> itensCarrossel = [];

    // Limpa registros nulos ou vazios vindos do Firestore
    final logosValidas = logosUrls.where((url) => url.isNotEmpty).take(5).toList();
    
    for (var url in logosValidas) {
      itensCarrossel.add(_buildLogoItem(url, corTextoEIcone));
    }

    // Algoritmo de Preenchimento Estrito de 5 Slots (Prompt 4):
    // Completa os slots vazios alternando entre 'Rumo Quiz' e 'Instituição' até atingir exatamente 5 itens.
    bool alternarFallback = true;
    while (itensCarrossel.length < 5) {
      if (alternarFallback) {
        itensCarrossel.add(
          _buildFallbackLogoItem(Icons.quiz, 'Rumo Quiz', corTextoEIcone),
        );
      } else {
        itensCarrossel.add(
          _buildFallbackLogoItem(Icons.school, 'Instituição', corTextoEIcone),
        );
      }
      alternarFallback = !alternarFallback;
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: corFundo,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 16,
                color: corTextoEIcone.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                'Parceiros:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: corTextoEIcone,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: itensCarrossel.length,
              itemBuilder: (context, index) => itensCarrossel[index],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoItem(String url, Color corTratamento) {
    return Padding(
      key: ValueKey(url),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          url, 
          height: 36, 
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.grey.shade200,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Logo', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallbackLogoItem(IconData icone, String texto, Color corTexto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: corTexto.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: corTexto.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 14, color: corTexto),
            const SizedBox(width: 4),
            Text(
              texto,
              style: TextStyle(
                fontSize: 11,
                color: corTexto,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
