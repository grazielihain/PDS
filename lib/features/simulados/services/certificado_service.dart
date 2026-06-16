import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class CertificadoService {
  static Future<void> gerarEImprimirCertificado({
    required String tituloProva,
    required int acertos,
    required int totalQuestoes,
    required double notaObtida,
    required double notaMaxima,
    required String nomeAluno,
    required String nomeInstiticao,
    String? logoUrl,
    required bool
    isPorAssunto, // 🔥 Nova flag necessária para cumprir a regra de negócio do TCC
  }) async {
    final pdf = pw.Document();
    final aproveitamento = totalQuestoes > 0
        ? (acertos / totalQuestoes) * 100
        : 0.0;

    Uint8List? imagemBytes;

    // Tenta baixar a logo se a URL existir
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(logoUrl))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          imagemBytes = response.bodyBytes;
        }
      } catch (e) {
        debugPrint('Erro ao baixar a logo da instituição para o PDF: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue900, width: 4),
            ),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.amber700, width: 1.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // 🟢 CABEÇALHO ATUALIZADO: RUMO QUIZ + INSTITUIÇÃO DO ALUNO
                  pw.Column(
                    children: [
                      // Marca principal do Sistema
                      pw.Text(
                        'SISTEMA DE ENSINO RUMO QUIZ',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 10),

                      // Se houver logo cadastrada para a instituição do aluno, exibe ela aqui
                      if (imagemBytes != null) ...[
                        pw.Container(
                          height: 45,
                          constraints: const pw.BoxConstraints(maxWidth: 140),
                          child: pw.Image(pw.MemoryImage(imagemBytes)),
                        ),
                        pw.SizedBox(height: 6),
                      ],

                      // Nome da Instituição do Aluno (Subtítulo)
                      pw.Text(
                        nomeInstiticao.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        height: 1.5,
                        width: 300,
                        color: PdfColors.amber700,
                      ),
                    ],
                  ),

                  pw.Text(
                    'CERTIFICADO DE CONCLUSÃO',
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                      letterSpacing: 2,
                    ),
                  ),

                  // Corpo do Texto
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                    child: pw.RichText(
                      textAlign: pw.TextAlign.center,
                      text: pw.TextSpan(
                        style: const pw.TextStyle(
                          fontSize: 15,
                          color: PdfColors.grey800,
                          lineSpacing: 1.5,
                        ),
                        children: [
                          const pw.TextSpan(
                            text: 'Certificamos que o(a) estudante ',
                          ),
                          pw.TextSpan(
                            text: nomeAluno.toUpperCase(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                              fontSize: 17,
                            ),
                          ),
                          const pw.TextSpan(
                            text: ' concluiu com exito o simulado ',
                          ),
                          pw.TextSpan(
                            text: tituloProva,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          const pw.TextSpan(
                            text:
                                ', demonstrando aproveitamento acadêmico avaliado por meio da plataforma digital de apuração automatizada de desempenho.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Seção de Métricas (Ajustada com a Regra do TCC)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 24,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricaPdf(
                          'Acertos',
                          '$acertos / $totalQuestoes',
                        ),
                        // 🔥 Regra estrita: Se for por assunto, Oculta a nota numérica
                        if (!isPorAssunto)
                          _buildMetricaPdf(
                            'Nota Obtida',
                            '${notaObtida.toStringAsFixed(1)} / ${notaMaxima.toStringAsFixed(1)}',
                          ),
                        _buildMetricaPdf(
                          'Aproveitamento',
                          '${aproveitamento.toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),

                  // Rodapé de Assinatura
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 280,
                        height: 1,
                        color: PdfColors.grey600,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Direção / Coordenação Pedagógica da Instituição',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Documento emitido via sistema informatizado e gerado em conformidade com as diretrizes do TCC.',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Certificado_${tituloProva.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildMetricaPdf(String label, String valor) {
    return pw.Column(
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey900,
          ),
        ),
      ],
    );
  }
}
