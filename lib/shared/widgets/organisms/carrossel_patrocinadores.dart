import 'dart:async';
import 'package:flutter/material.dart';

class CarrosselPatrocinadores extends StatefulWidget {
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
  State<CarrosselPatrocinadores> createState() =>
      _CarrosselPatrocinadoresState();
}

class _CarrosselPatrocinadoresState extends State<CarrosselPatrocinadores> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool _retornando = false;
  static const Duration _intervalo = Duration(seconds: 3);
  static const double _passo = 120.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_intervalo, (_) => _scrollar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollar() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;

    if (_retornando) {
      _scrollController.jumpTo(0.0);
      _retornando = false;
      return;
    }

    final atual = _scrollController.offset;
    final proximo = atual + _passo;

    if (proximo >= max) {
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      _retornando = true;
    } else {
      _scrollController.animateTo(
        proximo,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final corFundo =
        widget.corCustomizadaInstituicao ?? Colors.blue.shade700;

    final bool fundoEscuro =
        ThemeData.estimateBrightnessForColor(corFundo) == Brightness.dark;
    final Color corTextoEIcone = fundoEscuro ? Colors.white : Colors.black87;

    final logosValidas = widget.logosUrls
        .where((url) => url.trim().isNotEmpty)
        .take(5)
        .toList();

    final List<Widget> itens =
        logosValidas.map((url) => _buildLogoItem(url)).toList();

    int i = itens.length;
    while (i < 5) {
      if (widget.logoInstituicaoUrl.trim().isNotEmpty) {
        itens.add(_buildLogoItem(widget.logoInstituicaoUrl));
      } else {
        itens.add(
          _buildFallbackItem(Icons.school, 'Instituição', corTextoEIcone),
        );
      }
      i++;
      if (i < 5) {
        itens.add(_buildLogoRumoQuizItem());
        i++;
      }
    }

    return Container(
      width: double.infinity,
      height: 72,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const SizedBox(width: 12),
                  ...itens,
                ],
              ),
            ),
          );
        },
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
          height: 44,
          fit: BoxFit.contain,
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : const SizedBox(width: 44, height: 44),
          errorBuilder: (context, error, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Logo',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoRumoQuizItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.asset(
          'assets/images/logo_rumo_quiz_sem_slogan.png',
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.quiz, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text('Rumo Quiz',
                  style: TextStyle(fontSize: 11, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackItem(
      IconData icone, String texto, Color corTexto) {
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
