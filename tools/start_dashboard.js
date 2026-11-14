#!/usr/bin/env python3
import json
import re
import sys

PROMPTS = {
    "hexstrike": [
        "scan de rede", "reconhecimento", "port scan", "service enum", "network discovery",
        "nmap", "enumeração", "host discovery", "scan network", "recon"
    ],
    "cyberstrike-github-security": [
        "analisar esse codigo", "review de seguranca", "secret scan", "sast", "vulnerabilidade",
        "code review", "seguranca do codigo", "dependency audit", "GitHub security"
    ],
    "cyberstrike-cve": [
        "CVE", "advisory", "vulnerabilidade conhecida", "security advisory", "patch impact"
    ],
    "cyberstrike-osint": [
        "osint", "investigacao", "threat intel", "domain lookup", "host lookup", "intel"
    ]
}


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower().strip())


def main():
    prompt = " ".join(sys.argv[1:])
    if not prompt:
        print(json.dumps({"activate": [], "status": "idle"}))
        return 0

    normalized = normalize(prompt)
    active = []

    for server, terms in PROMPTS.items():
        if any(term in normalized for term in terms):
            active.append(server)

    result = {
        "activate": active,
        "status": "ok" if active else "idle",
        "prompt": prompt[:500],
    }
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
