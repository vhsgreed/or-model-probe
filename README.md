# or-model-probe

Health-probe the free OpenRouter models with a 1-token ping, sorted by latency.

```
./or-model-probe.sh            # print healthy models, one per line (fastest first)
./or-model-probe.sh --json     # JSON: {model: {ok, ms, status}}
```

## Why

Free OpenRouter models go down or get rate-limited unpredictably. Before
spawning a batch of LLM subagents, probe which models are alive and fast —
then hand only healthy models to your rotation/selection logic.

## Key location

Reads your OpenRouter API key from:

1. `OR_KEY_FILE` env var, or
2. `~/.config/openrouter/key` (default)

The key file should contain your `sk-or-v1-...` key on one line.

## Output

- Default mode: one model ID per line, healthy only, fastest first.
- `--json`: full health map `{model: {ok, ms, status}}` for scripting.

## Links

Part of the [vhsgreed](https://vhsgreed.win) toolset: data, code, and methods in the open.
