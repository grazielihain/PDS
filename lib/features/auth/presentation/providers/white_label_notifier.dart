import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rumo_quiz/features/auth/data/models/institution_model.dart';

// Classe que guarda os dados visuais na memória RAM do celular
class WhiteLabelState {
  final InstitutionModel? instituicao;
  final String logoUrl;
  final bool isLoading;

  WhiteLabelState({this.instituicao, this.logoUrl = '', this.isLoading = false});
}

class WhiteLabelNotifier extends StateNotifier<WhiteLabelState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WhiteLabelNotifier() : super(WhiteLabelState());

  // 🟢 FUNÇÃO ECONÔMICA: Só bate no banco se realmente precisar carregar os dados comerciais
  Future<void> inicializarIdentidade(String instituicaoId, String logoUrl) async {
    // Se a instituição já estiver na memória, não gasta leitura no Firebase!
    if (state.instituicao?.id == instituicaoId) return;

    state = WhiteLabelState(logoUrl: logoUrl, isLoading: true);

    try {
      // Faz uma única leitura do documento da instituição (Ex: /instituicoes/ulbra-01)
      final doc = await _firestore.collection('instituicoes').doc(instituicaoId).get();
      
      if (doc.exists) {
        state = WhiteLabelState(
          instituicao: InstitutionModel.fromFirestore(doc),
          logoUrl: logoUrl,
          isLoading: false,
        );
      } else {
        state = WhiteLabelState(logoUrl: logoUrl, isLoading: false);
      }
    } catch (e) {
      state = WhiteLabelState(logoUrl: logoUrl, isLoading: false);
    }
  }
}

// Provedor global para o aplicativo inteiro escutar as propriedades visuais da escola
final whiteLabelProvider = StateNotifierProvider<WhiteLabelNotifier, WhiteLabelState>((ref) {
  return WhiteLabelNotifier();
});