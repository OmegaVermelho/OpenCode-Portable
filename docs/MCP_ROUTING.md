# MEGA-CODE-4 MCP Routing

## Strategy
The MEGA-CODE-4 agent uses lazy loading. It does not activate all MCP tools at once.

## Activation logic
- `hexstrike`: activated for network reconnaissance, scanning, port enumeration, and host discovery.
- `cyberstrike-github-security`: activated for repository audits, secret scanning, SAST, and vulnerability review.
- `cyberstrike-cve`: activated for vulnerability advisories and CVE lookups.
- `cyberstrike-osint`: activated for domain and threat intelligence tasks.

## Safety rules
- All MCP servers bind to `127.0.0.1` only.
- If the user request is generic or benign, the router should deactivate all MCP servers.
- Dangerous tasks require explicit authorization.

## Router behavior
`tools/mcp_router.py` inspects the user prompt and returns a list of servers to activate. This is lightweight and avoids loading the entire toolset for every task.
