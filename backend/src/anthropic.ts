import type { Env, ChatTurn, Risk } from './types';

const API_URL = 'https://api.anthropic.com/v1/messages';
const ANTHROPIC_VERSION = '2023-06-01';

// Cost-optimized routing: a tiny Haiku classifier gates crisis handling; Sonnet writes
// the actual reply. Exact IDs from the current model table — no date suffixes.
const CLASSIFIER_MODEL = 'claude-haiku-4-5';
const RESPONDER_MODEL = 'claude-sonnet-4-6';

function headers(env: Env): Record<string, string> {
  // Accept the legacy misspelling (ANTROPHIC_API_KEY) so a mis-named secret still works.
  const apiKey = env.ANTHROPIC_API_KEY || env.ANTROPHIC_API_KEY || '';
  return {
    'x-api-key': apiKey,
    'anthropic-version': ANTHROPIC_VERSION,
    'content-type': 'application/json',
  };
}

const CLASSIFIER_SYSTEM = `You are a safety classifier for a gambling-recovery chat. Read ONLY the user's latest message and classify risk:
- "crisis": any sign of suicidal thoughts, self-harm, hopelessness ("no way out", "better off gone"), or acute danger to self or others.
- "elevated": an active strong craving / urge to gamble right now, or clear acute distress.
- "none": everything else (casual talk, questions, reflection, good news).
Output only the JSON.`;

const RISK_SCHEMA = {
  type: 'object',
  properties: { risk: { type: 'string', enum: ['none', 'elevated', 'crisis'] } },
  required: ['risk'],
  additionalProperties: false,
};

/** Cheap Haiku classification of the latest user message. Fails open to "none". */
export async function classifyRisk(env: Env, message: string): Promise<Risk> {
  try {
    const res = await fetch(API_URL, {
      method: 'POST',
      headers: headers(env),
      body: JSON.stringify({
        model: CLASSIFIER_MODEL,
        // Headroom so the tiny risk JSON can always complete — a truncated (max_tokens)
        // response would fail JSON.parse and fall through to "none", silently dropping the
        // crisis/helpline routing for a genuinely at-risk message.
        max_tokens: 256,
        system: CLASSIFIER_SYSTEM,
        messages: [{ role: 'user', content: message.slice(0, 4000) }],
        output_config: { format: { type: 'json_schema', schema: RISK_SCHEMA } },
      }),
    });
    if (!res.ok) return 'none';
    const body = (await res.json()) as { content?: Array<{ type: string; text?: string }> };
    const text = body.content?.find((b) => b.type === 'text')?.text ?? '{}';
    const parsed = JSON.parse(text) as { risk?: Risk };
    return parsed.risk === 'crisis' || parsed.risk === 'elevated' ? parsed.risk : 'none';
  } catch {
    return 'none';
  }
}

/**
 * Starts the Sonnet streaming reply. Returns the raw upstream SSE Response so the caller
 * can parse it and re-emit clean events to the app. `systemPrefix` is prompt-cached;
 * `contextBlock` (per-user, per-turn) stays uncached after it.
 */
export async function streamReply(
  env: Env,
  systemPrefix: string,
  contextBlock: string,
  history: ChatTurn[],
  message: string,
): Promise<Response> {
  return fetch(API_URL, {
    method: 'POST',
    headers: headers(env),
    body: JSON.stringify({
      model: RESPONDER_MODEL,
      max_tokens: 1024,
      stream: true,
      system: [
        { type: 'text', text: systemPrefix, cache_control: { type: 'ephemeral' } },
        { type: 'text', text: contextBlock },
      ],
      messages: [...history, { role: 'user', content: message }],
    }),
  });
}

/**
 * Parses Anthropic's SSE body and yields plain text deltas. Isolates all wire-format
 * details here so the app only ever sees {delta, done} events.
 */
export async function* parseTextDeltas(res: Response): AsyncGenerator<string> {
  const reader = res.body?.getReader();
  if (!reader) return;
  const decoder = new TextDecoder();
  let buffer = '';
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    // SSE events are separated by a blank line.
    let sep: number;
    while ((sep = buffer.indexOf('\n\n')) !== -1) {
      const rawEvent = buffer.slice(0, sep);
      buffer = buffer.slice(sep + 2);
      for (const line of rawEvent.split('\n')) {
        if (!line.startsWith('data:')) continue;
        const data = line.slice(5).trim();
        if (!data || data === '[DONE]') continue;
        try {
          const evt = JSON.parse(data) as {
            type?: string;
            delta?: { type?: string; text?: string };
          };
          if (evt.type === 'content_block_delta' && evt.delta?.type === 'text_delta') {
            yield evt.delta.text ?? '';
          }
        } catch {
          // ignore keep-alives / partials
        }
      }
    }
  }
}
