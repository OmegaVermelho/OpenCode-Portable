# MEGA-CODE-4 — Roteamento MCP

## Estratégia pretendida

A configuração do projeto descreve uma estratégia de carregamento seletivo para reduzir ferramentas carregadas em tarefas que não precisam de MCP. A implementação atual de `tools/mcp_router.py` classifica texto e imprime uma lista JSON de servidores sugeridos; ela **não inicia, desativa nem conecta servidores MCP** por conta própria.

## Classificadores de exemplo

- `hexstrike`: termos relacionados a reconhecimento e descoberta de rede.
- `cyberstrike-github-security`: análise de repositórios, segredos e SAST.
- `cyberstrike-cve`: consultas sobre CVEs e avisos de segurança.
- `cyberstrike-osint`: consultas de inteligência de domínio e ameaças.

Essas correspondências são heurísticas simples, podem produzir falsos positivos e não substituem autorização, revisão humana ou validação de escopo.

## Requisitos antes de ativar servidores

1. Instale o servidor MCP a partir de uma fonte oficial e confiável.
2. Confira nome de pacote, comando, argumentos e variáveis de ambiente na documentação upstream.
3. Verifique que o serviço escuta somente em `127.0.0.1`.
4. Mantenha ferramentas de rede desativadas até ter autorização e escopo explícitos.
5. Teste o comportamento em ambiente descartável e isolado.

Não presuma que a configuração de exemplo implementa lazy loading automaticamente ou que os serviços MCP estão instalados e disponíveis.
