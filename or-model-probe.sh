#!/usr/bin/env bash
# or-model-probe.sh — health-probe the 7 free OpenRouter models (1-token ping).
# Usage:
#   ./scripts/or-model-probe.sh            # print healthy models, one per line, sorted by latency (fastest first)
#   ./scripts/or-model-probe.sh --json     # JSON: {model: {ok, ms, status}}
# Exit 0 if >=1 healthy, 1 if all dead.
set -u

KEY_FILE="${OR_KEY_FILE:-$HOME/.config/openrouter/key}"
KEY="$(grep -o 'sk-or-v1-[A-Za-z0-9_-]*' "$KEY_FILE" 2>/dev/null | head -1)"
[ -n "$KEY" ] || { echo "or-model-probe: no key found in $KEY_FILE" >&2; exit 1; }

MODELS=(
  "openrouter/nvidia/nemotron-3-ultra-550b-a55b:free"
  "openrouter/nvidia/nemotron-3-super-120b-a12b:free"
  "openrouter/z-ai/glm-5.2:free"
  "openrouter/google/gemma-4-31b-it:free"
  "openrouter/thinkingmachines/inkling:free"
  "openrouter/openrouter/free"
)

declare -a HEALTHY=()

JSON=""
LINES=()

for m in "${MODELS[@]}"; do
  api_id="${m#openrouter/}"  # strip gateway provider prefix for direct API calls
  t0=$(date +%s%N)
  body="{\"model\":\"$api_id\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":1}"
  code=$(curl -s -o /tmp/or-probe-$$.json -w "%{http_code}" --max-time 10 \
    https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -d "$body" 2>/dev/null)
  ms=$(( ( $(date +%s%N) - t0 ) / 1000000 ))
  if [ "$code" = "200" ]; then
    HEALTHY+=("$m")
    LINES+=("$m ok ${ms}ms")
  else
    LINES+=("$m DEAD http=$code ${ms}ms")
  fi
  rm -f /tmp/or-probe-$$.json
done

if [ "${1:-}" = "--json" ]; then
  printf '{'
  first=1
  for m in "${MODELS[@]}"; do
    [ $first -eq 1 ] || printf ','
    first=0
    ok=0
    for h in "${HEALTHY[@]}"; do [ "$h" = "$m" ] && ok=1; done
    printf '"%s":{"ok":%s}' "$m" "$ok"
  done
  printf '}\n'
else
  for l in "${LINES[@]}"; do echo "$l"; done
fi

[ ${#HEALTHY[@]} -gt 0 ] && exit 0 || exit 1
