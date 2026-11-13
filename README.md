# Descarte Inteligente

Aplicativo mobile para apoiar a identificação de resíduos, apresentar orientações de descarte e localizar pontos de coleta em São Carlos - SP. Projeto acadêmico desenvolvido como Trabalho de Conclusão de Curso.

## Estado atual

O núcleo de consulta do aplicativo está implementado e validado localmente:

- Aplicativo Flutter com navegação entre início, pesquisa de resíduos, pontos de coleta, favoritos e chat.
- Pesquisa textual de resíduos cadastrados, com descrição, categoria, orientação e preparo.
- Consulta de pontos compatíveis com cada resíduo e abertura de rota no Google Maps.
- Mapa de pontos de coleta, localização opcional e alternativa de consulta sem permissão de GPS.
- Backend FastAPI conectado ao PostgreSQL.
- Favoritos armazenados localmente no dispositivo.

**Funcionalidades ainda em evolução:** identificação por imagem com IA e revisão final do comportamento conversacional do assistente. O trabalho de IA foi separado da etapa de estabilização do núcleo do aplicativo.

## Arquitetura

```text
Flutter (Android)
      |
      | HTTP / JSON
      v
FastAPI (Python)
      |
      | psycopg
      v
PostgreSQL

Flutter -> Google Maps / Geolocator
Backend -> módulo de IA (em evolução)
```

### Tecnologias

| Camada | Tecnologia |
|---|---|
| Aplicativo | Flutter / Dart |
| API | Python / FastAPI / Uvicorn |
| Banco de dados | PostgreSQL |
| Acesso ao banco | psycopg |
| Mapas e localização | Google Maps / Geolocator |
| Preferências locais | shared_preferences |

## Estrutura do repositório

- `backend/app/`: aplicação FastAPI, acesso ao banco e serviços.
- `backend/ai/`: arquivos e documentação do módulo experimental de IA.
- `backend/scripts/`: scripts administrativos e de carga de dados.
- `mobile/descarte_inteligente/`: aplicativo Flutter.
- `database/`: espaço reservado para artefatos do banco.
- `docs/`: espaço reservado para documentação complementar.

## Executar localmente

### Pré-requisitos

- Python instalado.
- PostgreSQL instalado e em execução.
- Flutter SDK e Android SDK configurados.
- Um dispositivo Android ou emulador.
- Chave do Google Maps configurada localmente para os recursos de mapa.

### 1. Backend

No terminal, entre na pasta do backend:

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Crie o arquivo `.env` dentro de `backend/`, usando `backend/.env.example` como referência. Configure a URL do banco local. Não versione esse arquivo e não compartilhe credenciais.

Exemplo de formato (substitua os valores localmente):

```env
DATABASE_URL=postgresql://USUARIO:SENHA@localhost:5432/descarte_inteligente
OPENAI_API_KEY=
OPENAI_MODEL=gpt-5-mini
```

O banco `descarte_inteligente` e suas tabelas precisam estar preparados e populados antes de iniciar a API.

Inicie o servidor:

```powershell
python -m uvicorn app.main:app --reload --host 0.0.0.0
```

Endpoints úteis durante o desenvolvimento:

- `GET /` — status básico da API.
- `GET /health` — health check.
- `GET /api/test` — teste simples.
- `GET /api/collection-points` — pontos de coleta.
- `GET /api/collection-points/nearby?latitude=...&longitude=...` — pontos ordenados por distância.
- `GET /api/waste-types` — resíduos cadastrados.
- `GET /api/waste-types/search?q=...` — pesquisa textual.
- `GET /api/waste-types/{id}` — detalhes de um resíduo.
- `GET /api/waste-types/{id}/collection-points` — pontos associados ao resíduo.
- `POST /api/chat` — assistente conversacional (depende da configuração da chave de IA).

A documentação interativa fica em `/docs` durante o desenvolvimento local.

### 2. Aplicativo Flutter

Em outro terminal:

```powershell
cd mobile/descarte_inteligente
flutter pub get
flutter analyze
flutter test
flutter run
```

O endereço da API usado pelo aplicativo está em:

`mobile/descarte_inteligente/lib/core/constants/api_constants.dart`

Para testar em um celular físico, configure o endereço IP local do computador na mesma rede Wi-Fi. O servidor deve estar acessível pela rede privada.

### 3. Configuração do Google Maps

A chave do Google Maps deve ficar em configuração local do Gradle, usando o mecanismo de secrets configurado em `android/app/build.gradle.kts`. Os arquivos locais `secrets.properties` e `local.defaults.properties` são ignorados pelo Git. Nunca coloque uma chave privada em arquivos versionados.

## Segurança implementada no ambiente local

- Variáveis de ambiente e arquivos locais de segredos ignorados pelo Git.
- Conexão PostgreSQL com validação de configuração.
- Usuário `descarte_app` separado do administrador, com permissões de leitura nas tabelas da aplicação.
- Script de referência para restringir permissões: `backend/scripts/restrict_app_role.sql`.
- Consultas SQL parametrizadas para valores de entrada.
- Tratamento genérico de erros inesperados na API, com detalhes registrados no log do servidor.
- Validação dos limites geográficos e tamanho de consultas.
- Limite local de requisições: 120 requisições por minuto para a API geral e 10 por minuto para `/api/chat`, por IP e processo.
- Cabeçalhos HTTP básicos de proteção.
- Regra local do Firewall do Windows para a porta 8000 restrita ao perfil de rede privada.

**Limitação importante:** o rate limiting atual mantém contadores em memória e serve como proteção inicial para uma única instância local. Antes de operar em produção/múltiplas instâncias, deve ser substituído por controle compartilhado (por exemplo, Redis ou gateway). A API ainda não possui autenticação de usuários; os endpoints de consulta disponibilizam dados públicos cadastrados.

## Testes realizados

Validação local registrada:

- Endpoints de health, teste, consulta de pontos e resíduos: HTTP 200.
- Pesquisa de resíduos: HTTP 200.
- Consulta de pontos próximos com coordenadas válidas: HTTP 200.
- Coordenadas fora dos limites: HTTP 422.
- Teste de 121 requisições: 114 respostas HTTP 200 e 7 respostas HTTP 429.
- `flutter analyze`: sem problemas.
- `flutter test`: todos os testes passaram.
- Aplicativo testado em dispositivo Android na rede local.

Esses testes validam os fluxos locais descritos; não representam auditoria independente, pentest ou certificação de segurança.

## Próximas etapas

A preparação para produção e publicação permanece pendente:

- [ ] Hospedar a API e o PostgreSQL.
- [ ] Configurar domínio, HTTPS/TLS e firewall do servidor.
- [ ] Manter o banco inacessível diretamente pela internet.
- [ ] Configurar segredos no ambiente de hospedagem.
- [ ] Migrar o rate limiting para solução compartilhada e configurar monitoramento.
- [ ] Desabilitar ou restringir a documentação pública da API em produção.
- [ ] Configurar backups automáticos e testar restauração.
- [ ] Definir identificador Android definitivo e assinatura Release própria.
- [ ] Restringir a chave do Google Maps ao aplicativo e certificado corretos.
- [ ] Preparar política de privacidade e informações exigidas pela Play Console.
- [ ] Fazer testes de ponta a ponta com a versão Release e publicar inicialmente em faixa de testes.

A identificação de resíduos por imagem e os ajustes finais do módulo conversacional de IA também continuam pendentes e serão retomados em uma etapa separada.

## Issues

Acompanhe as tarefas e pendências na aba [Issues](https://github.com/KauanMascaro26/projeto_final_curso/issues) do repositório.
