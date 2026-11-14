# MEGA-CODE-4 Security Notes

## Scope
This portable project intentionally runs only on localhost and stores runtime data under `data/` so that no file is written outside the current project directory.

## Local-only policy
- Web dashboard binds to `127.0.0.1` only.
- MCP servers must never bind to `0.0.0.0`.
- Network discovery, pentest tooling, and public intelligence connectors remain disabled by default and require explicit user action.

## Authentication
- Dashboard access requires a Bearer token generated at runtime.
- Tokens should be treated like credentials and not persisted in plain text.

## Secrets
- `data/ai_settings.env` is encrypted at rest using AES-256 via `tools/secure_env.py`.
- File permissions are restricted to `600`.
- Master password must be supplied at runtime and never hardcoded.

## Sandbox recommendation
For any dangerous tools (e.g., HexStrike or security probes), run the workload inside a separate container or a dedicated VM with no host file mounts. The included `Dockerfile` is a minimal starting point and should be hardened further for production usage.

## XSS and sanitization
- The dashboard uses a strict Content-Security-Policy.
- Dynamic content should be rendered via `textContent` or sanitized values.
- HTML and Markdown must be treated as untrusted input.

## Fast fail rules
- If the user request is ambiguous, prefer conservative behavior.
- If a tool is dangerous and not explicitly authorized, keep it disabled.
- If the environment is not trusted, refuse to run aggressive security tools.
