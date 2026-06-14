import 'package:flutter/material.dart';

/// [ORGANISMO] CarrosselPatrocinadores
/// Rodapé White Label Dinâmico e Reativo de acordo com as regras do projeto.
class CarrosselPatrocinadores extends StatelessWidget {
  final List<String> logosUrls;
  final Color?
  corCustomizadaInstituicao; // Cor escolhida pelo Admin no Firestore

  const CarrosselPatrocinadores({
    super.key,
    this.logosUrls = const [],
    this.corCustomizadaInstituicao,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Definição da Cor de Fundo: Usa a cor do Admin ou um azul padrão caso seja nula
    final corFundo = corCustomizadaInstituicao ?? Colors.blue.shade700;

    // 🌓 Lógica de contraste para o texto (se o fundo for claro, texto escuro; se escuro, texto branco)
    final corTextoEIcone =
        ThemeData.estimateBrightnessForColor(corFundo) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    // 🛡️ REGRA DE NEGÓCIO: Montar a lista final de logos baseada nas regras de preenchimento
    List<Widget> itensCarrossel = [];

    // 1. Adiciona as logos customizadas enviadas pelo Admin (limitado a no máximo 5)
    final logosAdministradas = logosUrls.take(5).toList();
    for (var url in logosAdministradas) {
      itensCarrossel.add(_buildLogoItem(url));
    }

    // 2. Se a lista ficou menor que 5, adicionamos obrigatoriamente os fallbacks do projeto:
    if (itensCarrossel.length < 5) {
      // Logo da Instituição (Fallback 1)
      itensCarrossel.add(
        _buildFallbackLogoItem(Icons.school, 'Instituição', corTextoEIcone),
      );
    }
    if (itensCarrossel.length < 5) {
      // Logo padrão do Rumo Quiz (Fallback 2)
      itensCarrossel.add(
        _buildFallbackLogoItem(Icons.quiz, 'Rumo Quiz', corTextoEIcone),
      );
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: corFundo, // Cor dinâmica baseada no Admin
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
          // Rótulo identificador adaptável ao contraste
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

  /// Construtor de Logo vinda da URL (Storage)
  Widget _buildLogoItem(String url) {
    return Padding(
      key: ValueKey(url),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white, // Fundo branco para destacar a logo da marca
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(url, height: 36, fit: BoxFit.contain),
      ),
    );
  }

  /// Construtor dos Fallbacks Obrigatórios (Rumo Quiz e Instituição)
  Widget _buildFallbackLogoItem(IconData icone, String texto, Color corTexto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: corTexto.withOpacity(
            0.15,
          ), // Cria um tom sobre tom elegante com o fundo
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
