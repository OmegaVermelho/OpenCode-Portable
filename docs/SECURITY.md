# MEGA-CODE-4 — Notas de segurança

## Escopo e limites

O projeto procura manter dados de runtime em `data/` e limitar os serviços locais a localhost. Isso reduz a escrita em diretórios comuns do usuário, mas **não garante operação sem rastros no host**: swap, logs do sistema, antivírus, backups, telemetria e sincronização podem observar ou copiar dados.

## Política local

- O servidor de dashboard de exemplo vincula-se a `127.0.0.1`.
- Configure servidores MCP locais para escutar somente em `127.0.0.1`; não use `0.0.0.0`.
- Mantenha integrações não necessárias desativadas.
- Use ferramentas de segurança apenas em sistemas e repositórios com autorização explícita.

## Autenticação do dashboard

O servidor gera um Bearer Token aleatório na inicialização, salvo se `MEGA_DASHBOARD_TOKEN` estiver definido. Trate-o como uma credencial. A implementação atual tem uma rota local `/api/token`; portanto, não exponha o serviço a redes externas nem o coloque atrás de um proxy público.

## Segredos

- O utilitário `tools/secure_env.py` cifra dados com AES-GCM e deriva a chave com PBKDF2-HMAC-SHA256.
- O utilitário requer o pacote Python `cryptography`.
- A senha mestre não deve ser codificada, registrada em logs ou transmitida em argumentos de linha de comando em ambientes compartilhados.
- Revise permissões e remova arquivos temporários de forma segura conforme as necessidades do seu sistema.
- A cifragem em repouso não protege segredos depois que são descriptografados e carregados em memória.

## MCP e sandbox

A configuração MCP e o Dockerfile são exemplos iniciais e devem ser validados antes do uso. A existência de uma configuração não significa que um servidor foi instalado, iniciado, autenticado ou isolado. Para ferramentas de maior risco, use uma VM ou container dedicado, sem mounts de arquivos do host, com usuário não-root, capabilities removidas, limites de recursos e política de rede restritiva.

## XSS e conteúdo não confiável

- Trate HTML e Markdown de fontes externas como conteúdo não confiável.
- Prefira `textContent` para inserir conteúdo dinâmico no DOM; evite `innerHTML` com dados externos.
- Revise a política CSP e os recursos carregados antes de usar o dashboard com conteúdo sensível.

## Princípios de operação

- Em caso de dúvida, mantenha integrações desativadas.
- Não execute ações de varredura ou teste sem autorização e escopo definidos.
- Não considere “portátil” sinônimo de “sem rastros” ou “sandbox seguro por padrão”.
