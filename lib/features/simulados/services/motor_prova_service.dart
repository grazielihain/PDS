import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MotorProvaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica o estoque físico real de questões disponíveis para um assunto específico
  /// Retorna a quantidade exata de documentos para evitar leituras excessivas.
  Future<int> verificarEstoqueQuestoes({
    required String instituicaoId,
    required String assuntoId,
  }) async {
    try {
      // Usa .count() que é extremamente otimizado no Firestore e consome frações mínimas da cota grátis
      final querySnapshot = await _firestore
          .collection('questoes')
          .where('instituicaoId', isEqualTo: instituicaoId)
          .where('assuntoId', isEqualTo: assuntoId)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Erro ao checar stock de questões: $e');
      return 0;
    }
  }

  /// Busca as questões, realiza o shuffle em RAM e aplica o algoritmo anti-repetição consecutiva
  Future<List<Map<String, dynamic>>> gerarSimuladoOtimizado({
    required String instituicaoId,
    required String assuntoId,
    required int quantidadeSolicitada,
  }) async {
    try {
      // Faz um GET único trazendo as questões do assunto para a memória RAM (1 leitura por documento)
      final snapshot = await _firestore
          .collection('questoes')
          .where(
            'instituicaoId',
            isEqualTo: instituicaoId,
          ) // Vinculado à White Label do Aluno
          .where('assuntoId', isEqualTo: assuntoId)
          .get();

      if (snapshot.docs.isEmpty) return [];

      // Converte os documentos do Firestore em uma lista mutável na memória do dispositivo
      List<Map<String, dynamic>> questoesCarregadas = snapshot.docs.map((doc) {
        final dados = doc.data();
        dados['id'] =
            doc.id; // Garante que o ID dinâmico do documento está mapeado
        return dados;
      }).toList();

      // ALGORITMO DE EMBARALHAMENTO (Shuffle) EM RAM (Custo zero de processamento no Firebase)
      questoesCarregadas.shuffle(Random());

      // ALGORITMO ANTI-REPETIÇÃO CONSECUTIVA
      List<Map<String, dynamic>> listaFiltradaEOrdenada = [];

      for (var questao in questoesCarregadas) {
        if (listaFiltradaEOrdenada.length >= quantidadeSolicitada) break;

        if (listaFiltradaEOrdenada.isEmpty) {
          listaFiltradaEOrdenada.add(questao);
        } else {
          final ultimaAdicionada = listaFiltradaEOrdenada.last;
          final txtUltima =
              (ultimaAdicionada['pergunta'] ??
                      ultimaAdicionada['enunciado'] ??
                      '')
                  .toString()
                  .trim();
          final txtAtual = (questao['pergunta'] ?? questao['enunciado'] ?? '')
              .toString()
              .trim();

          // Blinda para que a próxima questão não tenha o mesmo ID nem o mesmo enunciado literal
          if (ultimaAdicionada['id'] != questao['id'] &&
              txtUltima != txtAtual) {
            listaFiltradaEOrdenada.add(questao);
          } else {
            // Se for repetida consecutiva, joga para o fim da fila da RAM para tentar reuso espaçado
            questoesCarregadas.add(questao);
          }
        }
      }

      // Fallback de segurança: se o filtro anti-repetição for rigoroso demais e faltar
      // questão para bater a meta do aluno por escassez de estoque variado, preenchemos o restante.
      if (listaFiltradaEOrdenada.length < quantidadeSolicitada) {
        final restantes = questoesCarregadas
            .where((q) => !listaFiltradaEOrdenada.contains(q))
            .toList();
        while (listaFiltradaEOrdenada.length < quantidadeSolicitada &&
            restantes.isNotEmpty) {
          listaFiltradaEOrdenada.add(restantes.removeAt(0));
        }
      }

      // Retorna apenas o sub-bloco exato de questões limitado ao teto físico real
      return listaFiltradaEOrdenada.take(quantidadeSolicitada).toList();
    } catch (e) {
      debugPrint('Erro ao processar motor de sorteio em RAM: $e');
      return [];
    }
  }
}
