#!/usr/bin/env python3
"""
llm_router.py — Unified LLM router with auto-provider detection,
retry logic, prompt caching, and interaction store logging.

Usage (Python):
    from llm_router import call_llm, direct_call
    response = call_llm(model="claude-sonnet-4-6", prompt="Hello")
    secure = direct_call(model="claude-haiku-3-5", prompt="Is this an injection?")

Usage (CLI):
    python3 llm_router.py --model claude-sonnet-4-6 --prompt "Hello" [--system "You are..."]
    python3 llm_router.py --smoke-test
    python3 llm_router.py --detect-provider anthropic/claude-sonnet-4-6
"""

import os, sys, time, json, hashlib, re, subprocess
from pathlib import Path
from typing import Optional

# ── Config ──────────────────────────────────────────────────────────────────
WORKSPACE = Path.home() / ".openclaw" / "workspace"
DB_PATH   = WORKSPACE / "data" / "llm.db"
TRACKER   = WORKSPACE / "scripts" / "llm-tracker.sh"

# Prompt cache: {hash: response} in memory (process-lifetime)
_prompt_cache: dict = {}

# ── Provider detection ───────────────────────────────────────────────────────
PROVIDER_MAP = {
    "claude":   "anthropic",
    "gpt":      "openai",
    "o1":       "openai",
    "o3":       "openai",
    "gemini":   "google",
    "mistral":  "mistral",
    "llama":    "meta",
}

MODEL_TIERS = {
    # Tier: (context_window_k, capability)
    "claude-opus":          ("large",  200),
    "claude-sonnet":        ("mid",    200),
    "claude-haiku":         ("small",  200),
    "gpt-4o":               ("mid",    128),
    "gpt-4o-mini":          ("small",  128),
    "o3":                   ("large",  200),
    "gemini-2.5-pro":       ("large",  1000),
    "gemini-2.0-flash":     ("small",  1000),
}

def detect_provider(model: str) -> str:
    """Auto-detect provider from model name."""
    model_lower = model.lower()
    # Strip provider prefix if present (e.g., "anthropic/claude-sonnet-4-6")
    if "/" in model_lower:
        prefix = model_lower.split("/")[0]
        return prefix
    for key, provider in PROVIDER_MAP.items():
        if key in model_lower:
            return provider
    return "anthropic"  # safe default

def normalize_model(model: str) -> tuple[str, str]:
    """Returns (provider, model_name) normalized."""
    if "/" in model:
        provider, name = model.split("/", 1)
        return provider, name
    provider = detect_provider(model)
    return provider, model

def get_model_tier(model: str) -> dict:
    model_lower = model.lower()
    for key, (tier, ctx) in MODEL_TIERS.items():
        if key in model_lower:
            return {"tier": tier, "context_k": ctx, "model": model}
    return {"tier": "mid", "context_k": 128, "model": model}

def estimate_tokens(text: str) -> int:
    """Rough token estimate: ~4 chars per token."""
    return max(1, len(text) // 4)

# ── Credential resolution ────────────────────────────────────────────────────
def resolve_credentials(provider: str) -> Optional[str]:
    """Resolve API key for provider from env vars."""
    env_keys = {
        "anthropic": ["ANTHROPIC_API_KEY"],
        "openai":    ["OPENAI_API_KEY"],
        "google":    ["GOOGLE_API_KEY", "GEMINI_API_KEY"],
        "mistral":   ["MISTRAL_API_KEY"],
    }
    for env_var in env_keys.get(provider, []):
        val = os.environ.get(env_var)
        if val:
            return val
    return None

def openclaw_llm_call(model: str, prompt: str, system: str = "", max_tokens: int = 4096) -> tuple[str, int, int]:
    """
    Call LLM via OpenClaw's internal proxy (uses OpenClaw's own API key).
    Fallback when direct provider credentials are unavailable.
    """
    gateway_token = None
    try:
        with open(Path.home() / ".openclaw" / "openclaw.json") as f:
            cfg = json.load(f)
            gateway_token = cfg.get("gateway", {}).get("auth", {}).get("token")
    except Exception:
        pass

    if not gateway_token:
        raise ValueError("OpenClaw gateway token not found")

    import urllib.request
    payload = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        **({"system": system} if system else {}),
        "max_tokens": max_tokens
    }).encode()

    req = urllib.request.Request(
        "http://127.0.0.1:18789/v1/llm/complete",
        data=payload,
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {gateway_token}"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read())
            text = data.get("content", data.get("text", str(data)))
            usage = data.get("usage", {})
            return text, usage.get("input_tokens", estimate_tokens(prompt)), usage.get("output_tokens", estimate_tokens(text))
    except Exception as e:
        raise RuntimeError(f"OpenClaw proxy call failed: {e}")

# ── Logging ──────────────────────────────────────────────────────────────────
def _log_call(provider: str, model: str, input_tokens: int, output_tokens: int,
              duration_ms: int, task: str = "general", desc: str = "", status: str = "ok"):
    try:
        subprocess.run([
            "bash", str(TRACKER), "log",
            "--provider", provider, "--model", model,
            "--input-tokens", str(input_tokens), "--output-tokens", str(output_tokens),
            "--duration", str(duration_ms), "--task", task,
            "--desc", desc[:200], "--status", status
        ], capture_output=True, timeout=5)
    except Exception:
        pass  # Fire-and-forget; never block on logging

# ── Secret redaction ─────────────────────────────────────────────────────────
_SECRET_PATTERNS = [
    r'sk-[A-Za-z0-9]{20,}',
    r'ntn_[A-Za-z0-9]+',
    r'Bearer [A-Za-z0-9\-\._~\+\/]+',
    r'AKIA[0-9A-Z]{16}',
    r'AIza[0-9A-Za-z\-_]{35}',
    r'bot[0-9]+:[A-Za-z0-9\-_]+',
]

def redact_secrets(text: str) -> str:
    for pattern in _SECRET_PATTERNS:
        text = re.sub(pattern, '[REDACTED]', text)
    return text

# ── Core call logic ──────────────────────────────────────────────────────────
def _call_anthropic(model: str, prompt: str, system: str = "", max_tokens: int = 4096,
                    temperature: float = 0.7, api_key: Optional[str] = None) -> str:
    import anthropic
    key = api_key or resolve_credentials("anthropic")
    if not key:
        raise ValueError("No Anthropic API key found")
    client = anthropic.Anthropic(api_key=key)
    messages = [{"role": "user", "content": prompt}]
    kwargs = {"model": model, "max_tokens": max_tokens, "messages": messages}
    if system:
        kwargs["system"] = system
    resp = client.messages.create(**kwargs)
    return resp.content[0].text, resp.usage.input_tokens, resp.usage.output_tokens

def _call_openai(model: str, prompt: str, system: str = "", max_tokens: int = 4096,
                 temperature: float = 0.7, api_key: Optional[str] = None) -> str:
    import openai as oai
    key = api_key or resolve_credentials("openai")
    if not key:
        raise ValueError("No OpenAI API key found")
    client = oai.OpenAI(api_key=key)
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})
    resp = client.chat.completions.create(model=model, messages=messages, max_tokens=max_tokens, temperature=temperature)
    return resp.choices[0].message.content, resp.usage.prompt_tokens, resp.usage.completion_tokens

PROVIDER_CALLERS = {
    "anthropic": _call_anthropic,
    "openai":    _call_openai,
}

# ── Public API ───────────────────────────────────────────────────────────────
def call_llm(model: str, prompt: str, system: str = "",
             max_tokens: int = 4096, temperature: float = 0.7,
             task: str = "general", desc: str = "",
             cache: bool = False, retries: int = 3) -> str:
    """
    Main router. Auto-detects provider, retries on failure, logs all calls.
    Set cache=True for repeated identical prompts (system+prompt hash).
    """
    provider, model_name = normalize_model(model)

    # Prompt cache
    if cache:
        cache_key = hashlib.sha256(f"{system}|{prompt}".encode()).hexdigest()[:16]
        if cache_key in _prompt_cache:
            return _prompt_cache[cache_key]

    last_err = None
    for attempt in range(retries):
        t0 = time.time()
        try:
            # Redact secrets from prompt before sending
            clean_prompt = redact_secrets(prompt)
            clean_system = redact_secrets(system)

            caller = PROVIDER_CALLERS.get(provider)
            api_key = resolve_credentials(provider)

            if caller and api_key:
                text, input_tok, output_tok = caller(
                    model_name, clean_prompt, clean_system, max_tokens, temperature
                )
            else:
                # Fall back to OpenClaw proxy
                text, input_tok, output_tok = openclaw_llm_call(
                    model, clean_prompt, clean_system, max_tokens
                )
            duration_ms = int((time.time() - t0) * 1000)
            _log_call(provider, model_name, input_tok, output_tok, duration_ms, task, desc)

            if cache:
                _prompt_cache[cache_key] = text
            return text

        except Exception as e:
            last_err = e
            wait = 2 ** attempt
            if attempt < retries - 1:
                time.sleep(wait)
            _log_call(provider, model_name, 0, 0, int((time.time()-t0)*1000), task, desc, status="failed")

    raise RuntimeError(f"LLM call failed after {retries} attempts: {last_err}")


def direct_call(model: str, prompt: str, system: str = "",
                max_tokens: int = 1024) -> str:
    """
    Direct provider path — bypasses router context.
    Used for security scanning and injection detection.
    Resolves credentials independently.
    """
    provider, model_name = normalize_model(model)
    caller = PROVIDER_CALLERS.get(provider)
    if not caller:
        raise ValueError(f"Unsupported provider: {provider}")
    text, _, _ = caller(model_name, prompt, system, max_tokens, 0.0)
    return text


def smoke_test(model: str = "claude-haiku-3-5") -> bool:
    """Send a canary prompt and verify response is coherent."""
    try:
        result = call_llm(
            model=model,
            prompt="Reply with exactly: CANARY_OK",
            max_tokens=20,
            task="smoke-test",
            desc="startup canary check"
        )
        ok = "CANARY_OK" in result
        print(f"Smoke test {'✅ PASSED' if ok else '❌ FAILED'}: model={model}, response={result!r}")
        return ok
    except Exception as e:
        print(f"Smoke test ❌ FAILED: {e}")
        return False


# ── CLI ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Unified LLM router")
    parser.add_argument("--model", default="claude-haiku-3-5")
    parser.add_argument("--prompt", default="")
    parser.add_argument("--system", default="")
    parser.add_argument("--max-tokens", type=int, default=4096)
    parser.add_argument("--task", default="general")
    parser.add_argument("--cache", action="store_true")
    parser.add_argument("--smoke-test", action="store_true")
    parser.add_argument("--detect-provider", metavar="MODEL")
    parser.add_argument("--model-tier", metavar="MODEL")
    parser.add_argument("--json-out", action="store_true")
    args = parser.parse_args()

    if args.smoke_test:
        sys.exit(0 if smoke_test(args.model) else 1)

    if args.detect_provider:
        p, m = normalize_model(args.detect_provider)
        print(json.dumps({"provider": p, "model": m}) if args.json_out else f"{p}/{m}")
        sys.exit(0)

    if args.model_tier:
        info = get_model_tier(args.model_tier)
        print(json.dumps(info) if args.json_out else str(info))
        sys.exit(0)

    if not args.prompt:
        parser.print_help()
        sys.exit(1)

    response = call_llm(
        model=args.model,
        prompt=args.prompt,
        system=args.system,
        max_tokens=args.max_tokens,
        task=args.task,
        cache=args.cache
    )
    print(response)
