'use strict';

const fs   = require('fs');
const path = require('path');
const { normalizeAnthropicModel, estimateTokensFromChars } = require('./model-utils');
const { logLlmCall } = require('./interaction-store');

const SMOKE_TEST_DISABLED = process.env.SKIP_SMOKE_TEST === '1';
const DEFAULT_TIMEOUT_MS  = 60_000;
const SMOKE_TIMEOUT_MS    = 20_000;

// ── OAuth token resolution ────────────────────────────────────────────────────
function resolveOAuthToken() {
  // 1. Env var takes priority
  if (process.env.CLAUDE_CODE_OAUTH_TOKEN) {
    return process.env.CLAUDE_CODE_OAUTH_TOKEN;
  }

  // 2. Parse from .env file in workspace
  const envPaths = [
    path.join(process.env.HOME, '.openclaw', 'workspace', '.env'),
    path.join(process.cwd(), '.env'),
    path.join(process.env.HOME, '.env'),
  ];
  for (const envPath of envPaths) {
    if (!fs.existsSync(envPath)) continue;
    const contents = fs.readFileSync(envPath, 'utf8');
    for (const line of contents.split('\n')) {
      const m = line.match(/^CLAUDE_CODE_OAUTH_TOKEN\s*=\s*["']?([^"'\s]+)/);
      if (m) return m[1];
    }
  }

  // 3. Claude Code session token (written by `claude login`)
  const claudeAuth = path.join(
    process.env.HOME, '.claude', '.credentials.json'
  );
  if (fs.existsSync(claudeAuth)) {
    try {
      const creds = JSON.parse(fs.readFileSync(claudeAuth, 'utf8'));
      const token = creds?.claudeAiOauth?.accessToken || creds?.access_token;
      if (token) return token;
    } catch { /* ignore */ }
  }

  return null;
}

function assertNoConflict() {
  if (process.env.ANTHROPIC_API_KEY && resolveOAuthToken()) {
    throw new Error(
      'ANTHROPIC_API_KEY and CLAUDE_CODE_OAUTH_TOKEN are both set. ' +
      'In OAuth mode, remove ANTHROPIC_API_KEY from your environment.'
    );
  }
}

// ── Smoke test (once per process) ────────────────────────────────────────────
let _smokeTestPassed = false;
let _smokeTestPromise = null;

async function runSmokeTest(client) {
  if (_smokeTestPassed || SMOKE_TEST_DISABLED) return;
  if (_smokeTestPromise) return _smokeTestPromise;

  _smokeTestPromise = (async () => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), SMOKE_TEST_TIMEOUT_MS ?? SMOKE_TIMEOUT_MS);
    try {
      const text = await _callSdk(client, {
        model:  'claude-haiku-3-5',
        prompt: 'Reply with exactly AUTH_OK and nothing else.',
        signal: controller.signal,
        skipLog: true,
      });
      if (!text.includes('AUTH_OK')) {
        throw new Error(`Smoke test failed — unexpected response: ${text.slice(0, 80)}`);
      }
      _smokeTestPassed = true;
      console.error('[anthropic-sdk] Smoke test passed');
    } catch (err) {
      throw new Error(`Anthropic OAuth smoke test failed: ${err.message}`);
    } finally {
      clearTimeout(timer);
    }
  })();

  return _smokeTestPromise;
}

// ── Core SDK call ─────────────────────────────────────────────────────────────
async function _callSdk(client, { model, prompt, signal, skipLog = false, caller = '' }) {
  const { query } = require('@anthropic-ai/claude-agent-sdk');
  let text = '';

  for await (const message of query({
    client,
    prompt,
    model,
    tools: [],
    maxTurns: 1,
    abortSignal: signal,
  })) {
    if (message.type === 'assistant') {
      for (const block of message.content ?? []) {
        if (block.type === 'text') text += block.text;
      }
    }
  }

  return text;
}

// ── Public API ────────────────────────────────────────────────────────────────
async function runAnthropicAgentPrompt({
  model    = 'claude-sonnet-4-5',
  prompt   = '',
  timeoutMs = DEFAULT_TIMEOUT_MS,
  caller   = '',
  maxTurns = 1,
  skipLog  = false,
} = {}) {
  assertNoConflict();

  const token = resolveOAuthToken();
  if (!token) {
    throw new Error(
      'No OAuth token found. Run `claude login` or set CLAUDE_CODE_OAUTH_TOKEN.'
    );
  }

  const Anthropic = require('@anthropic-ai/sdk');
  const client = new Anthropic({ apiKey: token });   // SDK accepts OAuth token as key

  await runSmokeTest(client);

  const normalizedModel = normalizeAnthropicModel(model);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  const t0 = Date.now();
  let text = '';
  let ok = true;
  let errorMsg = null;

  try {
    text = await _callSdk(client, {
      model: normalizedModel,
      prompt,
      signal: controller.signal,
      skipLog,
      caller,
    });
  } catch (err) {
    ok = false;
    errorMsg = err.message;
    throw err;
  } finally {
    clearTimeout(timer);
    if (!skipLog) {
      logLlmCall({
        provider:    'anthropic',
        model:       normalizedModel,
        caller,
        prompt,
        response:    text,
        durationMs:  Date.now() - t0,
        ok,
        error:       errorMsg,
      });
    }
  }

  return { text, provider: 'anthropic' };
}

module.exports = { runAnthropicAgentPrompt, resolveOAuthToken };
