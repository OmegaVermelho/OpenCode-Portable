# MEGA-CODE-4

> Portable cyber coding agent with local-only runtime, encrypted settings and Coarena-ready AI integration.

This project evolves the original portable OpenCode wrapper into a hardened MEGA-CODE-4 runtime: local-first execution, encrypted credentials, local-only dashboard, and MCP lazy-loading for security workflows.

Nothing is written to the host machine: `HOME`, `USERPROFILE`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and `XDG_CACHE_HOME` are all redirected inside `data/`.

---

## Quick Start

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

On first launch the agent asks for the Coarena API endpoint and model, then stores the credential set encrypted using a master password inside `data/ai_settings.env`.

---

## Project Structure

```text
OpenCode-Portable/
├── START.bat                  Windows entry point
├── start.sh                   Linux/macOS entry point
├── opencode.jsonc             Unified OpenCode + MCP configuration
├── Dockerfile                 Sandbox base image
├── data/                      Portable runtime data (host-isolated)
│   ├── ai_settings.env        Encrypted credentials
│   ├── home/
│   ├── config/
│   ├── app_data/
│   ├── local_app_data/
│   ├── cache/
│   ├── logs/
│   └── opencode/
├── engine/
│   ├── opencode-linux-x64/
│   ├── opencode-linux-arm64/
│   ├── opencode-windows-x64/
│   ├── opencode-darwin-x64/
│   └── opencode-darwin-arm64/
├── tools/
│   ├── secure_env.py
│   ├── mcp_router.py
│   ├── start_dashboard.js
│   ├── web/
│   └── ...
├── docs/
│   ├── SECURITY.md
│   └── MCP_ROUTING.md
├── README.md
├── LICENSE
└── .gitignore
```

---

## Security Model

- Runtime data is redirected to `data/`
- Secrets are encrypted at rest using AES-256 + PBKDF2
- Dashboard and MCP endpoints bind to `127.0.0.1` only
- MCP tools use lazy loading and activate only when contextually required
- Launchers keep the host clean and do not write outside the portable folder

---

## MEGA-CODE-4 Identity

MEGA-CODE-4 is the operating identity of the portable project. It combines:

- local-only runtime portability
- code generation and analysis workflows
- secure context routing for MCP tools
- dashboard status visibility
- encrypted credential management

---

## License

The portable wrapper is released under the MIT license; see [LICENSE](LICENSE).
