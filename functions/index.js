const { onDocumentDeleted, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Exclui automaticamente o registro no Firebase Authentication
 * quando um documento em 'usuarios/{userId}' é deletado no Firestore.
 */
exports.excluirAuthAoRemoverUsuario = onDocumentDeleted(
  "usuarios/{userId}",
  async (event) => {
    const userId = event.params.userId;
    try {
      await admin.auth().deleteUser(userId);
    } catch (error) {
      // Usuário pode já ter sido excluído manualmente no Console — ignorar.
    }
  }
);

/**
 * Sincroniza o e-mail no Firebase Authentication quando o campo 'email'
 * é alterado no documento Firestore do usuário.
 */
exports.sincronizarEmailAuth = onDocumentUpdated(
  "usuarios/{userId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!after.email || before.email === after.email) return;

    const userId = event.params.userId;
    try {
      await admin.auth().updateUser(userId, { email: after.email });
    } catch (error) {
      // E-mail duplicado ou usuário não encontrado — não propagar.
    }
  }
);
