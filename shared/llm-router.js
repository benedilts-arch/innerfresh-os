'use strict';

const { isAnthropicModel, detectModelProvider, normalizeAnthropicModel } = require('./model-utils');
const { runAnthropicAgentPrompt } = require('./anthropic-agent-sdk');
const { logLlmCall } = require('./interaction-store');

const DEFAULT_MODEL   = process.env.DEFAULT_LLM_MODEL || 'claude-sonnet-4-5';
const DEFAULT_TIMEOUT = 60_000;

// ── OpenAI handler (fallback for non-Anthropic models) ───────────────────────
async function runOpenAI({ model, prompt, timeoutMs = DEFAULT_TIMEOUT, caller = '' }) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) throw new Error('OPENAI_API_KEY not set');

  const { default: OpenAI } = await import('openai').catch(() => {
    throw new Error('openai package not installed. Run: npm install openai');
  });

  const client = new OpenAI({ apiKey });
  const t0 = Date.now();
  let text = '';
  let ok = true;
  let errorMsg = null;

  try {
    const response = await client.chat.completions.create({
      model,
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 4096,
    });
    text = response.choices?.[0]?.message?.content ?? '';
  } catch (err) {
    ok = false;
    errorMsg = err.message;
    throw err;
  } finally {
    logLlmCall({
      provider: 'openai', model, caller, prompt, response: text,
      durationMs: Date.now() - t0, ok, error: errorMsg,
    });
  }

  return { text, provider: 'openai' };
}

// ── Unified router ────────────────────────────────────────────────────────────
/**
 * Route an LLM call to the appropriate provider.
 *
 * @param {string} prompt
 * @param {object} options
 * @param {string}  [options.model]      Model name or alias (default: claude-sonnet-4-5)
 * @param {number}  [options.timeoutMs]  Timeout in ms (default: 60000)
 * @param {string}  [options.caller]     Caller identifier for logging
 * @param {boolean} [options.skipLog]    Skip interaction store logging
 * @returns {Promise<{ text: string, durationMs: number, provider: string }>}
 */
async function runLlm(prompt, {
  model      = DEFAULT_MODEL,
  timeoutMs  = DEFAULT_TIMEOUT,
  caller     = '',
  skipLog    = false,
} = {}) {
  const t0 = Date.now();
  const provider = detectModelProvider(model) ?? 'anthropic';
  let result;

  if (isAnthropicModel(model)) {
    result = await runAnthropicAgentPrompt({ model, prompt, timeoutMs, caller, skipLog });
  } else if (provider === 'openai') {
    result = await runOpenAI({ model, prompt, timeoutMs, caller });
  } else {
    // Fallback: try Anthropic with the model string as-is
    console.warn(`[llm-router] Unknown provider for "${model}", routing to Anthropic`);
    result = await runAnthropicAgentPrompt({ model, prompt, timeoutMs, caller, skipLog });
  }

  return { ...result, durationMs: Date.now() - t0 };
}

module.exports = { runLlm };
