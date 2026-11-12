#!/usr/bin/env bash
# omp-setup.sh — add the ofox + tokun providers to this machine's omp.
# Companion to devserver.sh; run ON the server (any host where omp is installed):
#   bash omp-setup.sh
# Writes ~/.omp/agent/models.yml and exports the two API keys in ~/.bashrc.
# Keys come from the environment when set, else are prompted for (hidden
# input). No key values are stored in this file. Idempotent; re-running
# refreshes rotated keys.
set -euo pipefail

SUPERPOWERS_REF="superpowers@superpowers-dev"
die() { echo "ERROR: $*" >&2; exit 1; }

command -v omp >/dev/null || die "omp not installed — run devserver.sh first"
[ "$(id -u)" -ne 0 ] || die "run as the normal user, not root"

if [ -z "${OFOX_API_KEY:-}" ]; then
  [ -t 0 ] || die "OFOX_API_KEY not set and no TTY to prompt — export it first"
  read -rsp "OFOX_API_KEY: " OFOX_API_KEY; echo >&2
fi
if [ -z "${TOKUN_TOKEN:-}" ]; then
  [ -t 0 ] || die "TOKUN_TOKEN not set and no TTY to prompt — export it first"
  read -rsp "TOKUN_TOKEN: " TOKUN_TOKEN; echo >&2
fi
[ -n "$OFOX_API_KEY" ] && [ -n "$TOKUN_TOKEN" ] || die "keys must not be empty"

# 1) provider definitions (baseUrl + env var names, mirroring the pc's omp)
mkdir -p ~/.omp/agent
cat > ~/.omp/agent/models.yml <<'YAML'
providers:
  ofox:
    baseUrl: https://api.ofox.ai/v1
    apiKey: OFOX_API_KEY
    api: openai-completions
    models:
      - id: moonshotai/kimi-k3
        name: kimi-k3
        api: openai-completions
      - id: moonshotai/kimi-k3.1-pro
        name: kimi-k3.1-pro
        api: openai-completions
        reasoning: true
        input: [text, image]
        contextWindow: 1048576
        maxTokens: 131072
        cost:
          input: 2
          output: 11
          cacheRead: 0.2
          cacheWrite: 0
      - id: google/gemini-4-argon
        name: gemini-4-argon
        api: openai-completions
        maxTokens: 65536
      - id: google/gemini-3.8-flash
        name: gemini-3.8-flash
        api: openai-completions
        cost:
          input: 0.75
          output: 3.75
          cacheRead: 0.075
          cacheWrite: 0.0415
      - id: deepseek/deepseek-v4.1-flash-1017
        name: deepseek-v4.1-flash-1017
        api: openai-completions
        reasoning: true
        input: [text, image]
        contextWindow: 1048576
        maxTokens: 393216
        cost:
          input: 0.3
          output: 1.2
          cacheRead: 0.006
          cacheWrite: 0
      - id: openai/gpt-6.1-sol
        name: gpt-6.1-sol
        api: openai-completions
      - id: openai/gpt-6.1-terra
        name: gpt-6.1-terra
        api: openai-completions
  ofox-anthropic:
    baseUrl: https://api.ofox.ai/anthropic
    apiKey: OFOX_API_KEY
    api: anthropic-messages
    disableStrictTools: true
    models:
      - id: anthropic/claude-fable-5
        name: fable-5
        reasoning: true
        input: [text, image]
        contextWindow: 1000000
        maxTokens: 128000
      - id: anthropic/claude-sonnet-5
        name: sonnet-5
        reasoning: true
        input: [text, image]
        contextWindow: 1000000
        maxTokens: 128000
      - id: anthropic/claude-sonnet-5.5
        name: sonnet-5.5
        reasoning: true
        input: [text, image]
        contextWindow: 1000000
        maxTokens: 128000
      - id: anthropic/claude-opus-5.5
        name: opus-5.5
        reasoning: true
        input: [text, image]
        contextWindow: 1000000
        maxTokens: 128000
      - id: anthropic/claude-haiku-5.5
        name: haiku-5.5
        reasoning: true
        input: [text, image]
        contextWindow: 1000000
        maxTokens: 128000
  tokun:
    baseUrl: https://api.tokun.sh
    apiKey: TOKUN_TOKEN
    api: anthropic-messages
    disableStrictTools: true
    models:
      - id: anthropic/claude-opus-5-5
        name: opus-5-5
        reasoning: true
        input: [text]
        contextWindow: 1000000
        maxTokens: 128000
YAML

# 2) keys into ~/.bashrc: drop stale lines, append fresh ones
touch ~/.bashrc
printf 'export OFOX_API_KEY=%q\nexport TOKUN_TOKEN=%q\n' "$OFOX_API_KEY" "$TOKUN_TOKEN" |
  { sed -i "/^export \(OFOX_API_KEY\|TOKUN_TOKEN\)=/d" ~/.bashrc && cat >> ~/.bashrc; }

# 3) verify: file in place, keys land in a fresh shell, endpoints accept them
grep -q '^providers:' ~/.omp/agent/models.yml || die "models.yml not written"
(
  . ~/.bashrc
  [ -n "${OFOX_API_KEY:-}" ] && [ -n "${TOKUN_TOKEN:-}" ] || die "keys not in shell env after .bashrc"
)
ofox=$(curl -sS -o /dev/null -w '%{http_code}' -m 15 \
  -H "Authorization: Bearer $OFOX_API_KEY" https://api.ofox.ai/v1/models)
tokun=$(curl -sS -o /dev/null -w '%{http_code}' -m 15 \
  -H "x-api-key: $TOKUN_TOKEN" -H 'anthropic-version: 2023-06-01' https://api.tokun.sh/v1/models)
echo "verify: models.yml ok, keys in env, ofox -> $ofox, tokun -> $tokun"
[ "$ofox" = 200 ] && [ "$tokun" = 200 ] || die "endpoint check failed"
echo "Done. Models are usable as ofox/<name> and tokun/<name>, e.g. --model ofox/kimi-k3.1-pro"
