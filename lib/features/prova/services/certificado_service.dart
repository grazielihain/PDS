import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificadoService {
  static Future<void> gerarEImprimirCertificado({
    required String tituloProva,
    required int acertos,
    required int totalQuestoes,
    required double notaObtida,
    required double notaMaxima,
    required String nomeAluno,
    required String nomeInstiticao, // 🟢 ADICIONADO: Nome da instituição do aluno
  }) async {
    final pdf = pw.Document();
    final aproveitamento = totalQuestoes > 0 ? (acertos / totalQuestoes) * 100 : 0.0;

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
                  // Cabeçalho com o Nome da Instituição de Ensino
                  pw.Column(
                    children: [
                      // 🔍 PLACEHOLDER DO LOGO: Espaço reservado para o logo da faculdade/escola
                      // pw.Container(
                      //   height: 50,
                      //   child: pw.Image(pw.MemoryImage(imagemLogoBytes)),
                      // ),
                      // pw.SizedBox(height: 8),
                      pw.Text(
                        nomeInstiticao.toUpperCase(), // 🟢 Exibe o nome da Instituição real
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(height: 2, width: 240, color: PdfColors.amber700),
                    ],
                  ),

                  pw.Text(
                    'CERTIFICADO DE CONCLUSÃO',
                    style: pw.TextStyle(
                      fontSize: 32,
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
                        style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey800, lineSpacing: 1.5),
                        children: [
                          const pw.TextSpan(text: 'Certificamos que o(a) estudante '),
                          pw.TextSpan(
                            text: nomeAluno.toUpperCase(),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey900, fontSize: 18),
                          ),
                          const pw.TextSpan(text: ' concluiu com êxito o simulado '),
                          pw.TextSpan(
                            text: tituloProva,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                          const pw.TextSpan(text: ', demonstrando aproveitamento acadêmico avaliado por meio da plataforma digital de apuração automatizada de desempenho.'),
                        ],
                      ),
                    ),
                  ),

                  // Seção de Métricas
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricaPdf('Acertos', '$acertos / $totalQuestoes'),
                        _buildMetricaPdf('Nota Obtida', '${notaObtida.toStringAsFixed(1)} / ${notaMaxima.toStringAsFixed(1)}'),
                        _buildMetricaPdf('Aproveitamento', '${aproveitamento.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),

                  // Rodapé de Assinatura da Instituição de Ensino
                  pw.Column(
                    children: [
                      pw.Container(width: 280, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Direção / Coordenação Pedagógica da Instituição', // 🟢 Corrigido para a Instituição
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Documento emitido via sistema informatizado e gerado em conformidade com as diretrizes do TCC.',
                        style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey500),
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
        pw.Text(label.toUpperCase(), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(valor, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
      ],
    );
  }
}