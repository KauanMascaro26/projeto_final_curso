# Segurança da API — checklist de produção

Este documento reúne as configurações necessárias antes de disponibilizar o Descarte Inteligente na Play Store.

## Proteções implementadas no código

- Headers: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` e `X-Permitted-Cross-Domain-Policies`.
- HSTS quando a requisição chega à aplicação como HTTPS.
- Rate limiting por IP, com limites configuráveis para API geral e chat.
- Validação de limites dos campos do chat e rejeição de campos JSON inesperados.
- Documentação Swagger, ReDoc e OpenAPI desativadas quando `APP_ENV=production`.
- Validação de Host em produção por meio de `ALLOWED_HOSTS`.
- CORS opcional e restrito às origens explicitamente configuradas.
- Respostas do endpoint de chat marcadas como `no-store`.

## Configuração obrigatória no ambiente de produção

Defina as variáveis no painel do provedor de hospedagem (não em arquivos versionados):

- `APP_ENV=production`
- `ALLOWED_HOSTS=seu-dominio-da-api` — somente hostname, sem protocolo, caminho ou porta.
- `CORS_ALLOWED_ORIGINS=https://seu-dominio-web` — somente se Flutter Web consumir a API. Para o app Flutter nativo, CORS não é necessário.
- `DATABASE_URL` — conexão com usuário próprio da aplicação, sem privilégios administrativos.
- `OPENAI_API_KEY` — manter exclusivamente no backend.

Não copie literalmente os domínios de exemplo. Configure os domínios reais do ambiente publicado. A aplicação falhará ao iniciar em produção se `ALLOWED_HOSTS` estiver vazio ou contiver curinga.

## Banco de dados

1. Crie um usuário dedicado para a API, diferente do usuário administrador.
2. Execute `scripts/restrict_app_role.sql` conectado como administrador, revisando antes o nome do banco e o usuário.
3. Configure `DATABASE_URL` para usar o usuário restrito.
4. Confirme que a API consegue executar SELECT e que INSERT, UPDATE, DELETE, CREATE e operações administrativas são negadas.
5. Garanta que backups e acesso administrativo sejam controlados separadamente.

O script existente concede leitura às tabelas do schema public. Se objetos forem criados por outro proprietário que não seja `postgres`, revise os comandos de default privileges para esse proprietário também.

## Itens de infraestrutura ainda necessários

- Publicar a API somente atrás de HTTPS com certificado válido.
- Configurar o proxy/gateway para limitar tamanho de requisições e conexões.
- O rate limiter atual é local ao processo. Em produção com múltiplas instâncias ou workers, substitua-o por rate limiting compartilhado (gateway, Redis ou serviço equivalente).
- Se houver proxy reverso, configure encaminhamento de IP e esquema HTTPS somente para proxies confiáveis. Não confie indiscriminadamente em cabeçalhos `X-Forwarded-For` enviados pelo cliente.
- Configurar firewall para expor somente as portas necessárias; o PostgreSQL não deve ficar publicamente acessível.
- Restringir a chave do Google Maps às APIs e plataformas necessárias e nunca incluir a chave OpenAI no aplicativo.
- Configurar monitoramento, alertas de erros, rotação de segredos e backups testados.
- Não registrar tokens, senhas, chaves ou conteúdo pessoal em logs.

## App Flutter e publicação

- Substituir a URL local em `lib/core/constants/api_constants.dart` pela URL HTTPS real da API antes de gerar o release.
- Confirmar que nenhum segredo de servidor foi incluído no bundle do aplicativo. Qualquer valor embutido no app pode ser extraído.
- Remover permissões Android que não sejam necessárias e revisar a política de privacidade e as declarações de segurança de dados do Google Play.
- Testar os endpoints a partir de uma rede externa e em um dispositivo real.

## Limites desta revisão

Os endpoints atuais de consulta retornam dados públicos de resíduos e pontos de coleta; o chat usa uma chave de IA mantida no servidor. Não foi identificada, nesta revisão dos arquivos, uma área de contas ou dados privados de usuários na API. Se autenticação, perfis ou dados pessoais forem adicionados, será necessário implementar autenticação, autorização por recurso e testes de isolamento antes de armazenar esses dados.

A alteração do código não substitui a configuração e validação do ambiente de hospedagem. Não considere a API pronta para produção até concluir os itens obrigatórios acima.
