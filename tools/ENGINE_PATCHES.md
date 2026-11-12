# Engine Patches

The binaries in `engine/` were built from the sibling `opencode-main` source
tree (Go, upstream `opencode-ai/opencode` v0.0.55) with the following small
changes, required by the portable launcher.

## 1. Custom model IDs

`internal/config/config.go`

- `config.Provider` now accepts `"models": ["..."]`.
- After loading the config, each declared model is registered in
  `models.SupportedModels` as `<provider>.<api-model>`.
- `internal/llm/models/models.go` gained `RegisterDynamicModel`.

This lets the launcher write entries such as:

```json
"providers": {
  "anthropic": {
    "apiKey": "sk-...",
    "models": ["claude-sonnet-4-5"]
  }
},
"agents": {
  "coder": { "model": "anthropic.claude-sonnet-4-5" }
}
```

## 2. Base URL override

`internal/config/config.go`, `internal/llm/provider/provider.go`,
`internal/llm/agent/agent.go`

- `config.Provider` now accepts `"baseURL"`.
- It is forwarded to the OpenAI-compatible client through the new
  `provider.WithProviderBaseURL` option.

## 3. Local / custom endpoint improvements

`internal/llm/models/local.go`

- Model discovery uses an HTTP client with a 3-second timeout, so a stopped
  LM Studio/Ollama server cannot hang startup.
- `LOCAL_MODEL` is added to the registry even when it is missing from the
  `/v1/models` response, and it becomes the default agent model.
- `CanReason` for local models is now opt-in via `LOCAL_CAN_REASON=1`. By
  default the engine sends `max_tokens` (not `max_completion_tokens` and not
  `reasoning_effort`), which is compatible with NVIDIA NIM and most
  OpenAI-compatible servers.
- `LOCAL_CONTEXT_WINDOW` and `LOCAL_MAX_TOKENS` override the context window and
  default output limit of local/custom models (NVIDIA uses 131072/8192).

## Rebuilding

```bash
./tools/build_engine.sh
```

`opencode-main` is kept untouched otherwise; the diff is limited to the files
listed above.
