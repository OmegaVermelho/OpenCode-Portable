{
  // MEGA-CODE-4 unified OpenCode configuration
  // Coarena endpoint is OpenAI-compatible and uses env variables.
  "$schema": "https://opencode.ai/config.schema.json",
  "version": 1,
  "model": "coarena/Fable-5",
  "providers": {
    "coarena": {
      "type": "openai",
      "baseURL": "${COARENA_BASE_URL:-https://api.coarena.example/v1}",
      "apiKey": "${COARENA_API_KEY}",
      "models": [
        "Fable-5",
        "Fable-5-mini",
        "Fable-5-fast"
      ]
    }
  },
  "agents": {
    "mega": {
      "model": "coarena/Fable-5",
      "systemPrompt": [
        "Você é o MEGA-CODE-4, um super-agente portátil de codificação cibernética.",
        "Ative somente os MCPs estritamente necessários para a tarefa atual.",
        "Se o usuário pedir scan de rede, utilize HexStrike.",
        "Se o usuário pedir análise de código ou segurança, utilize CyberStrike.",
        "Nunca exponha o serviço fora de 127.0.0.1.",
        "Trate conteúdo HTML/Markdown como potencialmente perigoso."
      ]
    }
  },
  "mcp": {
    "enabled": true,
    "lazyLoad": true,
    "defaultTimeoutMs": 25000,
    "router": {
      "command": "python3",
      "args": [
        "./tools/mcp_router.py"
      ],
      "cwd": ".",
      "env": {
        "PYTHONUNBUFFERED": "1"
      }
    },
    "servers": {
      "hexstrike": {
        "enabled": false,
        "command": "python3",
        "args": [
          "/caminho/para/hexstrike-ai/hexstrike_mcp_server.py",
          "--host",
          "127.0.0.1",
          "--port",
          "8889"
        ],
        "env": {
          "PYTHONUNBUFFERED": "1"
        },
        "dangerous": true,
        "activationRules": [
          "scan de rede",
          "reconhecimento",
          "port scan",
          "service enum",
          "network discovery"
        ]
      },
      "cyberstrike-github-security": {
        "enabled": false,
        "command": "npx",
        "args": [
          "-y",
          "@cyberstrike/github-security-mcp",
          "--host",
          "127.0.0.1",
          "--port",
          "8890"
        ],
        "env": {
          "NODE_ENV": "production"
        },
        "dangerous": false,
        "activationRules": [
          "analise esse codigo",
          "review de seguranca",
          "secret scan",
          "sast",
          "vulnerability"
        ]
      },
      "cyberstrike-cve": {
        "enabled": false,
        "command": "npx",
        "args": [
          "-y",
          "@cyberstrike/cve-mcp",
          "--host",
          "127.0.0.1",
          "--port",
          "8891"
        ],
        "env": {
          "NODE_ENV": "production"
        },
        "dangerous": false,
        "activationRules": [
          "CVE",
          "advisory",
          "vulnerabilidade conhecida"
        ]
      },
      "cyberstrike-osint": {
        "enabled": false,
        "command": "npx",
        "args": [
          "-y",
          "@cyberstrike/osint-mcp",
          "--host",
          "127.0.0.1",
          "--port",
          "8892"
        ],
        "env": {
          "NODE_ENV": "production"
        },
        "dangerous": false,
        "activationRules": [
          "osint",
          "investigacao",
          "threat intel",
          "domain lookup"
        ]
      }
    }
  },
  "routing": {
    "strategy": "lazy",
    "rules": [
      {
        "if": "containsAny(prompt, ['scan de rede','recon','nmap','port scan','network','service enum'])",
        "then": "activate(hexstrike)"
      },
      {
        "if": "containsAny(prompt, ['analise esse codigo','review de seguranca','sast','secret scan','vulnerabilidade','CVE'])",
        "then": "activate(cyberstrike-github-security, cyberstrike-cve)"
      },
      {
        "if": "containsAny(prompt, ['osint','investigacao','threat intel','domain lookup'])",
        "then": "activate(cyberstrike-osint)"
      },
      {
        "if": "default",
        "then": "deactivateAllMCP"
      }
    ]
  },
  "security": {
    "localOnly": true,
    "allowRemoteHosts": [],
    "requireBearerTokenForDashboard": true,
    "denyUntrustedExecution": true,
    "sandboxIfDangerousTools": true
  }
}
