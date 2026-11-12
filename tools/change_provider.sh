#!/bin/bash
# Change provider / model / API key without launching OpenCode.
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT_DIR/start.sh" --setup "$@"
