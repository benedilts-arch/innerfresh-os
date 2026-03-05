'use strict';

// ── Alias → official model name ──────────────────────────────────────────────
const MODEL_ALIASES = {
  // Anthropic
  'opus-4':       'claude-opus-4',
  'sonnet-4':     'claude-sonnet-4-5',
  'sonnet-4-5':   'claude-sonnet-4-5',
  'haiku-3-5':    'claude-haiku-3-5',
  'haiku':        'claude-haiku-3-5',
  'sonnet':       'claude-sonnet-4-5',
  'opus':         'claude-opus-4',
  // OpenAI
  'gpt4o':        'gpt-4o',
  'gpt4o-mini':   'gpt-4o-mini',
  'o3':           'o3',
};

// Per-model pricing (USD per 1M tokens)
const MODEL_PRICING = {
  'claude-opus-4':        { input: 15.00, output: 75.00 },
  'claude-sonnet-4-5':    { input:  3.00, output: 15.00 },
  'claude-sonnet-4-6':    { input:  3.00, output: 15.00 },
  'claude-haiku-3-5':     { input:  0.80, output:  4.00 },
  'gpt-4o':               { input:  2.50, output: 10.00 },
  'gpt-4o-mini':          { input:  0.15, output:  0.60 },
  'o3':                   { input: 10.00, output: 40.00 },
  'gemini-2.0-flash':     { input:  0.10, output:  0.40 },
  'gemini-2.5-pro':       { input:  1.25, output: 10.00 },
};

/**
 * Resolve alias and strip provider prefix.
 * "anthropic/claude-sonnet-4-6" → "claude-sonnet-4-6"
 * "sonnet-4" → "claude-sonnet-4-5"
 */
function normalizeAnthropicModel(model) {
  if (!model) return 'claude-sonnet-4-5';
  // Strip provider prefix
  const stripped = model.includes('/') ? model.split('/').slice(1).join('/') : model;
  return MODEL_ALIASES[stripped] || MODEL_ALIASES[model] || stripped;
}

/**
 * Returns true if the model is an Anthropic model.
 */
function isAnthropicModel(model) {
  if (!model) return false;
  const normalized = normalizeAnthropicModel(model).toLowerCase();
  return ['claude', 'opus', 'sonnet', 'haiku'].some(kw => normalized.includes(kw));
}

/**
 * Returns "anthropic", "openai", "google", or null.
 */
function detectModelProvider(model) {
  if (!model) return null;
  const m = model.toLowerCase();
  if (m.startsWith('anthropic/') || isAnthropicModel(m)) return 'anthropic';
  if (m.startsWith('openai/') || m.startsWith('gpt') || m.startsWith('o1') || m.startsWith('o3')) return 'openai';
  if (m.startsWith('google/') || m.startsWith('gemini')) return 'google';
  return null;
}

/**
 * Estimate tokens from character count (~4 chars per token).
 */
function estimateTokensFromChars(text) {
  if (!text) return 0;
  return Math.max(1, Math.floor(text.length / 4));
}

/**
 * Estimate cost in USD.
 */
function estimateCost(model, inputTokens, outputTokens) {
  const normalized = normalizeAnthropicModel(model);
  const pricing = MODEL_PRICING[normalized] || MODEL_PRICING['claude-sonnet-4-5'];
  return (inputTokens * pricing.input + outputTokens * pricing.output) / 1_000_000;
}

module.exports = {
  MODEL_ALIASES,
  MODEL_PRICING,
  normalizeAnthropicModel,
  isAnthropicModel,
  detectModelProvider,
  estimateTokensFromChars,
  estimateCost,
};
