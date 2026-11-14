# MEGA-CODE-4

> Assistente portátil de codificação com integração de IA e foco em segurança.

**MEGA-CODE-4** é o nome do projeto e da experiência de uso. O repositório GitHub ainda se chama `OpenCode-Portable`; portanto, os comandos de clone abaixo usam esse endereço até que o repositório seja renomeado nas configurações do GitHub.

## Início rápido

### Linux / macOS

```bash
git clone https://github.com/OmegaVermelho/OpenCode-Portable.git
cd OpenCode-Portable
chmod +x start.sh
./start.sh
```

### Windows

```bat
git clone https://github.com/OmegaVermelho/OpenCode-Portable.git
cd OpenCode-Portable
START.bat
```

Na primeira execução, o launcher solicita configurações do provedor Coarena e uma senha mestre para proteger as configurações salvas. O endpoint e o identificador do modelo dependem dos valores fornecidos pela Coarena; os valores de exemplo nos arquivos não substituem os dados oficiais da sua conta.

## Uso dos launchers

```text
./start.sh --help              Exibe as opções disponíveis (Linux/macOS)
./start.sh --setup             Abre a configuração do provedor
./start.sh --dir /caminho/projeto
./start.sh --quick             Inicia sem o menu de seleção
```

No Windows, use `START.bat --help`, `START.bat --setup` ou `START.bat --dir C:\caminho\projeto`.

## Estrutura principal

```text
OpenCode-Portable/             Nome atual do repositório GitHub
├── START.bat                  Launcher para Windows
├── start.sh                   Launcher para Linux/macOS
├── opencode.jsonc             Configuração declarativa de exemplo
├── Dockerfile                 Imagem inicial de sandbox
├── data/                      Dados e configurações locais do runtime
├── engine/                    Binários OpenCode incluídos
├── tools/                     Utilitários e dashboard
└── docs/                      Documentação de segurança e MCP
```

## Configuração e credenciais

- A configuração de execução e as credenciais ficam associadas à pasta `data/`.
- `tools/secure_env.py` usa AES-GCM com uma chave derivada por PBKDF2; requer o pacote Python `cryptography`.
- Use uma senha mestre forte e não a compartilhe nem a inclua em comandos, scripts ou commits.
- Não envie credenciais, arquivos de runtime ou a pasta `data/` para o GitHub.
- O arquivo `opencode.jsonc` é uma configuração de referência; confirme a compatibilidade das opções com a versão do engine antes de ativar integrações.

## Portabilidade: limites importantes

Os launchers redirecionam diretórios de configuração e dados conhecidos para a pasta local. Isso **não garante ausência absoluta de rastros no computador**: sistema operacional, antivírus, swap, logs, backups e ferramentas de sincronização podem registrar ou copiar informações. Para reduzir a exposição, use um dispositivo confiável, encerre o processo antes de remover a unidade e não use dados sensíveis em computadores compartilhados.

## MCP e serviços locais

As integrações MCP descritas na configuração exigem instalação e configuração próprias. Os nomes de pacotes, argumentos e endpoints de exemplo devem ser validados com a documentação oficial de cada servidor antes do uso. Mantenha serviços locais vinculados a `127.0.0.1`, desativados quando não necessários e limitados a sistemas e repositórios para os quais você tem autorização.

O roteador em `tools/mcp_router.py` é um utilitário de classificação de texto: ele imprime uma sugestão de servidores a ativar e, sozinho, **não inicia nem controla servidores MCP**. Não interprete a configuração declarativa como garantia de integração automática ou lazy loading funcional.

## Dashboard

O servidor de exemplo está em `tools/start_dashboard.js`. Ele escuta em localhost e protege as rotas com um Bearer Token. A rota `/api/token` expõe o token para o próprio cliente local; não exponha a porta em interfaces de rede nem encaminhe-a por proxy. O dashboard é uma base inicial, não uma implantação endurecida para produção.

## Sandbox

O `Dockerfile` é um ponto de partida, não uma garantia de isolamento completa. Antes de executar ferramentas de segurança, revise a imagem e a configuração do container. Prefira usuário não-root, remova capabilities, use filesystem somente leitura quando possível, limite a rede e não monte diretórios do host desnecessários. Uma VM dedicada pode oferecer isolamento adicional.

## Documentação

- [Notas de segurança](docs/SECURITY.md)
- [Roteamento MCP](docs/MCP_ROUTING.md)

## Licença

O wrapper portátil é distribuído sob a licença MIT. Consulte [LICENSE](LICENSE).
