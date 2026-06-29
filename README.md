# Rumo Quiz

Plataforma white-label de simulados e quizzes desenvolvida em Flutter + Firebase como Projeto de Desenvolvimento de Software (PDS) para conclusão do Curso de Análise e Desenvolvimento de Sistemas — ULBRA/Torres.

> Versão 1.0.0 · Flutter 3.x · Dart SDK ^3.10.8

---

## Sobre o Projeto

O **Rumo Quiz** permite que instituições de ensino disponibilizem simulados personalizados para seus alunos, com identidade visual própria (logo, cores, patrocinadores), controle de acesso por níveis de permissão e histórico imutável de resultados com gamificação.

A plataforma roda em **Web e Mobile (Android)** a partir de um único código-fonte Flutter.

---

## Funcionalidades

### Para Alunos (Acess3)
- Realizar simulados por categoria e assunto
- Escolher quantidade de questões e modo de simulado
- Visualizar resultado com taxa de acerto e mensagem personalizada
- Revisar questões respondidas com justificativas
- Acompanhar histórico de simulados e pontuação acumulada
- Gerar certificado em PDF
- Editar perfil e avatar emoji

### Para Gestores de Conteúdo (Acess2)
- Criar e editar questões (próprias)
- Cadastrar alunos (Acess3) e gerenciar os que cadastrou
- Visualizar mensagens de resultado (somente leitura)

### Para Administradores (Admin)
- Painel administrativo completo da instituição
- Configurar identidade visual (logo, mascote, cor, patrocinadores)
- Gerenciar categorias, assuntos e tipos de simulado
- Criar e editar questões e mensagens de resultado
- Configurar regras de gamificação
- Gerenciar todos os usuários da instituição
- Visualizar log de auditoria

### Para Master
- Acesso global a todas as instituições
- Criar e gerenciar instituições
- Gerenciar todos os usuários

---

## Arquitetura

O projeto segue **Clean Architecture** com organização **Feature First** e componentes de UI no padrão **Atomic Design**.

```
lib/
├── core/
│   ├── router/          # GoRouter + proteção de rotas por role
│   ├── theme/           # Geração dinâmica de ThemeData (White Label)
│   └── presentation/    # MainLayoutShell (shell de navegação)
│
├── features/
│   ├── auth/
│   │   ├── domain/      # UserEntity, AuthRepository (abstract), LoginUseCase
│   │   ├── data/        # UserModel, AuthRemoteDataSource, AuthRepositoryImpl
│   │   └── presentation/# AuthNotifier, WhiteLabelNotifier, páginas de login
│   │
│   ├── simulados/
│   │   ├── domain/      # QuestaoEntity, SimuladoRepository (abstract)
│   │   ├── data/        # QuestaoModel, HistoricoModel, SimuladoRemoteDataSource
│   │   ├── presentation/# QuizSessionNotifier, SimuladoController, páginas
│   │   └── services/    # MotorProvaService, CertificadoService
│   │
│   └── admin/
│       ├── data/        # AdminRemoteDataSource (CRUD completo)
│       └── presentation/# PainelAdminPage, tabs (categorias, questões, etc.)
│
└── shared/
    └── widgets/
        ├── atoms/
        ├── molecules/
        └── organisms/   # MenuLateralOrganism, CarrosselPatrocinadores
```

---

## Stack (Tecnologias Utilizadas)

### Frontend
 ________________________________________________________________________
|    Tecnologia    |     Versão    |               Uso                   |
|------------------|---------------|-------------------------------------|
|     Flutter      |      3.x      | Framework principal (Web + Android) |
|      Dart        |    ^3.10.8    | Linguagem                           |
| flutter_riverpod |     ^2.5.1    | Gerenciamento de estado             |
|    go_router     |    ^14.0.0    | Navegação e rotas protegidas        |
|  pdf + printing  | ^3.10 / ^5.11 | Geração de certificados             |
|    file_picker   |     ^8.1.1    | Upload de imagens                   |
|      intl        |     ^0.20.2   | Formatação de datas                 |
|__________________|_______________|_____________________________________|

### Backend as a Service (Firebase — Plano Spark)
 _____________________________________________________________________
|           Serviço            |                 Uso                  |
|------------------------------|--------------------------------------|
| Firebase Authentication      | Login e-mail/senha, gestão de sessão |
| Cloud Firestore              | Banco de dados NoSQL                 |
| Firebase Storage             | Logos, mascotes, imagens de questões |
| Cloud Functions (Node.js 22) | Lógica server-side e sincronização   |
|______________________________|______________________________________|


---

## Estrutura do Banco de Dados (Firestore)

```
instituicoes/{instId}
  nome, corHexadecimal, logoUrl, mascoteUrl, patrocinadoresUrls[]

usuarios/{userId}
  uid, nome, email, role, instituicaoId, avatarEmoji,
  pontuacaoAcumulada, criadoPor, primeiroAcesso
  │
  └── historico_simulados/{histId}          ← imutável (sem update/delete)
        userId, instituicaoId, categoria, tipoProva, acertos,
        totalQuestoes, pontosGamificacao, tempoUtilizadoSegundos,
        dataHora, revisaoQuestoes[]

categorias/{catId}
  nome, instituicaoId, dataCriacao

assuntos/{assId}
  nome, categoriaId, instituicaoId, dataCriacao

tipos_simulado/{tipoId}
  categoriaId, instituicaoId, modo, quantidadeMaxima

questoes/{questId}
  pergunta, opcoes[], respostaCorretaIndex, justificativa,
  categoriaId, assuntoId, instituicaoId, criadoPor, dataCriacao

mensagens_resultado/{msgId}
  texto, de, ate, imagemUrl, instituicaoId, dataCriacao

gamificacao/{regId}
  instituicaoId, dataCriacao, [regras configuráveis]

auditoria/{logId}                           ← somente criação
  userId, userName, acao, tela, detalhe,
  registroAntigo, registroNovo, dataHora

logs_acesso/{logId}                         ← somente criação
  userId, data
```

---

## Níveis de Acesso
 ____________________________________________________________________________________________
|   Role   |           Descrição          |         Permissões principais                    |
|----------|------------------------------|--------------------------------------------------|
| `Master` | Administrador da plataforma  | Acesso global a todas as instituições            |
| `Admin`  | Administrador da instituição | CRUD completo dentro da sua instituição          |
| `Acess2` | Gestor de Conteúdo           | Cria questões e alunos; edita apenas o que criou |
| `Acess3` | Aluno / Estudante            | Realiza simulados e visualiza histórico próprio  |
|__________|______________________________|__________________________________________________|

Os roles são armazenados como **Custom Claims** no token JWT do Firebase Authentication, eliminando leituras extras no Firestore a cada validação de permissão.

---

## Cloud Functions
 ____________________________________________________________________________________________
|            Função             |          Trigger        |           Descrição              |
|-------------------------------|-------------------------|----------------------------------|
| `sincronizarCustomClaims`     | `onDocumentWritten`     | Grava `role` e `instituicaoId`   |
|                               |  em `usuarios/{userId}` | como Custom Claims no token JWT  |
|-------------------------------|-------------------------|----------------------------------|
| `sincronizarEmailAuth`        | `onDocumentUpdated`     | Sincroniza e-mail no Firebase    |
|                               |  em `usuarios/{userId}` | Auth quando alterado no Firestore|
|-------------------------------|-------------------------|----------------------------------|
|                               |                         | Remove o registro no Firebase    |
| `excluirAuthAoRemoverUsuario` | `onDocumentDeleted`     |   Auth ao excluir usuário do     |
|                               |  em `usuarios/{userId}` |            Firestore             |
|_______________________________|_________________________|__________________________________|
---

## Configuração do Ambiente

### Pré-requisitos

- Flutter SDK ^3.10.8
- Node.js 22 (para Cloud Functions)
- Firebase CLI (`npm install -g firebase-tools`)
- Conta Firebase com projeto configurado

### Arquivos necessários (não versionados)

Estes arquivos contêm credenciais e **não estão no repositório**. Gere-os no Console do Firebase:
 ______________________________________________________________________________________________
|                Arquivo               |                    Como obter                         |
|--------------------------------------|-------------------------------------------------------|
| `android/app/google-services.json`   | Firebase Console → Configurações do projeto → Android |
| `lib/firebase_options.dart`          | `flutterfire configure` no terminal                   |
| `ios/Runner/GoogleService-Info.plist`| Firebase Console → Configurações do projeto → iOS     |
|______________________________________|_______________________________________________________|

### Instalação

```bash
# 1. Clonar o repositório
git clone <url-do-repositorio>
cd rumo_quiz

# 2. Instalar dependências Flutter
flutter pub get

# 3. Instalar dependências das Cloud Functions
cd functions
npm install
cd ..

# 4. Adicionar os arquivos de credenciais (ver seção acima)

# 5. Executar
flutter run -d chrome          # Web
flutter run -d <device-id>     # Android
```

### Deploy Firebase

```bash
# Deploy de todas as funções
firebase deploy --only functions

# Deploy das regras de segurança
firebase deploy --only firestore:rules,storage

# Deploy completo
firebase deploy
```

---

## Segurança

- **Firestore Rules:** permissões baseadas em Custom Claims JWT — sem custo de leituras extras
- **Storage Rules:** upload restrito por role; delete apenas para Admin/Master
- **Histórico de simulados:** imutável por design — resultados e pontos não mudam mesmo com edições posteriores de questões ou regras de gamificação
- **Isolamento White Label:** todos os documentos possuem `instituicaoId` — usuários só acessam dados da própria instituição
- **Auditoria:** todas as ações de criação, edição e exclusão são registradas na coleção `auditoria`

---

## Contato

- **E-mail:** rumoquiz@gmail.com

---

*Projeto acadêmico — Curso de Análise e Desenvolvimento de Sistemas · ULBRA/Torres*
