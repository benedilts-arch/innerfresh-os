# SUBAGENT-POLICY.md

When to delegate work to subagents vs. handle directly.

## Core Directive

Anything other than a simple conversational message should spawn a subagent.

## When to Use a Subagent

- Searches (web, social, email)
- API calls (Gmail, Calendar, Notion, Shopify, ad platforms)
- Multi-step tasks
- Data processing
- File operations beyond simple reads
- Calendar/email operations
- Any task expected to take more than a few seconds
- Anything that could fail or block the main session

## When to Work Directly

- Simple conversational replies
- Quick clarifying questions
- Acknowledgments
- Quick file reads for context
- Single-step lookups where spawning a subagent would take longer than just doing it

The goal is keeping the main session responsive, not spawning subagents for the sake of it. If a direct approach is faster and simpler, use it.

## Coding, Debugging, and Investigation

All coding, debugging, and investigation tasks go through subagents. The main session should never block on this work.

The subagent evaluates complexity:
- **Simple:** Handle directly. Config changes, small single-file fixes, appending to existing patterns, checking one log or config value.
- **Medium / Major:** Delegate to coding agent CLI (Claude Code). Multi-file features, complex logic, large additions, multi-step investigations tracing across files or systems.

## Delegation Announcements

When delegating to a subagent, tell the user which model and provider you're using.

Format: `[model] via [provider/tool]`

Examples:
- "Spawning a subagent with claude-sonnet-4-6 to search Twitter."
- "Delegating to Claude Code via coding-agent."

Include the model in both the start announcement and the completion message if the model used differs from what was initially stated.

## Failure Handling

When a subagent fails:
1. Report to the user via Telegram with error details
2. Retry once if the failure seems transient (network timeout, rate limit)
3. If the retry also fails, report both attempts and stop

## Why

Main session stability is critical. Subagents:
- Keep the main session responsive so the user can keep talking
- Isolate failures from the main conversation
- Allow concurrent work
- Report back when done
