# shared/ — Unified LLM Router (Node.js)

OAuth-based LLM routing with multi-provider support, call logging, and cost tracking.

## Setup

```bash
cd shared/
npm install
claude login          # stores OAuth token in ~/.claude/.credentials.json
# OR: add CLAUDE_CODE_OAUTH_TOKEN=<token> to workspace/.env
# Remove ANTHROPIC_API_KEY if set (conflicts with OAuth mode)
```

## Usage

```js
const { runLlm } = require('./llm-router');

const result = await runLlm("Summarize this for me", {
  model: "claude-sonnet-4",   // or "sonnet-4", "haiku", "opus-4", "gpt-4o"
  caller: "my-script",
  timeoutMs: 30_000,
});
console.log(result.text, result.durationMs + 'ms');
```

## Modules

| File | Role |
|------|------|
| `model-utils.js` | Alias resolution, provider detection, cost estimation |
| `interaction-store.js` | Fire-and-forget SQLite logging (WAL mode) |
| `anthropic-agent-sdk.js` | OAuth wrapper, smoke test, streaming |
| `llm-router.js` | Unified entry point — route by model name |

## Model aliases

| Alias | Resolves to |
|-------|-------------|
| `sonnet-4` | claude-sonnet-4-5 |
| `haiku` | claude-haiku-3-5 |
| `opus-4` | claude-opus-4 |
| `gpt4o` | gpt-4o |

## Smoke test

Runs once per process on first call. Sends `AUTH_OK` canary and validates response.
Disable with `SKIP_SMOKE_TEST=1`.
