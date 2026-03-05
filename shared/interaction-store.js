'use strict';

const path = require('path');
const { estimateTokensFromChars, estimateCost } = require('./model-utils');

const DB_PATH = process.env.LLM_DB ||
  path.join(process.env.HOME, '.openclaw', 'workspace', 'data', 'llm.db');

const SECRET_PATTERNS = [
  /sk-[A-Za-z0-9]{20,}/g,
  /ntn_[A-Za-z0-9]+/g,
  /Bearer [A-Za-z0-9\-._~+/]+=*/g,
  /AKIA[0-9A-Z]{16}/g,
  /AIza[0-9A-Za-z\-_]{35}/g,
  /bot\d{9,}:[A-Za-z0-9\-_]+/g,
];

function redact(text) {
  if (!text) return text;
  let out = String(text);
  for (const pattern of SECRET_PATTERNS) {
    out = out.replace(pattern, '[REDACTED]');
  }
  return out;
}

function truncate(text, maxChars = 10_000) {
  if (!text || text.length <= maxChars) return text;
  return text.slice(0, maxChars) + `…[truncated ${text.length - maxChars} chars]`;
}

// ── Lazy DB init (WAL mode) ──────────────────────────────────────────────────
let _db = null;

function getDb() {
  if (_db) return _db;
  try {
    const Database = require('better-sqlite3');
    _db = new Database(DB_PATH, { verbose: null });
    _db.pragma('journal_mode = WAL');
    _db.exec(`
      CREATE TABLE IF NOT EXISTS llm_calls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider TEXT,
        model TEXT NOT NULL,
        task_type TEXT,
        description TEXT,
        caller TEXT,
        prompt TEXT,
        response TEXT,
        input_tokens INTEGER DEFAULT 0,
        output_tokens INTEGER DEFAULT 0,
        total_tokens INTEGER GENERATED ALWAYS AS (input_tokens + output_tokens) STORED,
        duration_ms INTEGER,
        estimated_cost REAL,
        status TEXT DEFAULT 'ok',
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
        error TEXT
      );
      CREATE INDEX IF NOT EXISTS idx_llm_model ON llm_calls(model);
      CREATE INDEX IF NOT EXISTS idx_llm_caller ON llm_calls(caller);
      CREATE INDEX IF NOT EXISTS idx_llm_status ON llm_calls(status);
    `);
  } catch (err) {
    console.error('[interaction-store] DB init failed:', err.message);
    _db = null;
  }
  return _db;
}

/**
 * Fire-and-forget log insert.
 * Never throws — logging must not break the calling code.
 */
function logLlmCall({
  provider = '',
  model = '',
  caller = '',
  prompt = '',
  response = '',
  inputTokens = null,
  outputTokens = null,
  durationMs = null,
  ok = true,
  error = null,
} = {}) {
  setImmediate(() => {
    try {
      const db = getDb();
      if (!db) return;

      const cleanPrompt   = truncate(redact(prompt));
      const cleanResponse = truncate(redact(response));
      const inTok  = inputTokens  ?? estimateTokensFromChars(prompt);
      const outTok = outputTokens ?? estimateTokensFromChars(response);
      const cost   = estimateCost(model, inTok, outTok);

      db.prepare(`
        INSERT INTO llm_calls
          (provider, model, caller, prompt, response, input_tokens, output_tokens,
           estimated_cost, duration_ms, status, created_at, error)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, strftime('%s','now'), ?)
      `).run(
        provider, model, caller,
        cleanPrompt, cleanResponse,
        inTok, outTok, cost,
        durationMs, ok ? 'ok' : 'failed',
        error ? String(error).slice(0, 500) : null
      );
    } catch (err) {
      console.error('[interaction-store] log failed:', err.message);
    }
  });
}

module.exports = { logLlmCall, redact, truncate, getDb };
