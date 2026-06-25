import 'package:flutter/material.dart';

/// Rodapé White Label com carrossel de patrocinadores.
/// Sempre exibe 5 slots: primeiros são os patrocinadores cadastrados,
/// os restantes são preenchidos com a logo da instituição e a logo da Rumo Quiz.
class CarrosselPatrocinadores extends StatelessWidget {
  final List<String> logosUrls;
  final String logoInstituicaoUrl;
  final Color? corCustomizadaInstituicao;

  const CarrosselPatrocinadores({
    super.key,
    this.logosUrls = const [],
    this.logoInstituicaoUrl = '',
    this.corCustomizadaInstituicao,
  });

  @override
  Widget build(BuildContext context) {
    final corFundo = corCustomizadaInstituicao ?? Colors.blue.shade700;

    final bool fundoEscuro =
        ThemeData.estimateBrightnessForColor(corFundo) == Brightness.dark;
    final Color corTextoEIcone = fundoEscuro ? Colors.white : Colors.black87;

    // Monta a lista com patrocinadores válidos (máx 5)
    final logosValidas = logosUrls
        .where((url) => url.trim().isNotEmpty)
        .take(5)
        .toList();

    final List<Widget> itens = logosValidas
        .map((url) => _buildLogoItem(url))
        .toList();

    // Preenche os slots restantes até 5 com: logo da instituição → Rumo Quiz
    int i = itens.length;
    while (i < 5) {
      if (logoInstituicaoUrl.trim().isNotEmpty) {
        itens.add(_buildLogoItem(logoInstituicaoUrl));
      } else {
        itens.add(
          _buildFallbackItem(Icons.school, 'Instituição', corTextoEIcone),
        );
      }
      i++;
      if (i < 5) {
        itens.add(
          _buildFallbackItem(Icons.quiz, 'Rumo Quiz', corTextoEIcone),
        );
        i++;
      }
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: corFundo,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                color: corTextoEIcone.withValues(alpha: 0.8),
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
              itemCount: itens.length,
              itemBuilder: (context, index) => itens[index],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoItem(String url) {
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
          errorBuilder: (context, error, stackTrace) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Logo',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackItem(IconData icone, String texto, Color corTexto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: corTexto.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: corTexto.withValues(alpha: 0.25)),
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
