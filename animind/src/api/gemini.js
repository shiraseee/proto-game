import { searchMemories, addMemory, getDayCount } from '../db/database';

const GEMINI_API_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

// ── Main chat function ───────────────────────────────────────

export async function chatWithPet(userMessage, apiKey) {
  if (!apiKey) {
    throw new Error('API key not configured. Go to Settings to add your Gemini API key.');
  }

  const dayCount = await getDayCount();
  const relevantMemories = await searchMemories(userMessage, 5);

  const memoriesText =
    relevantMemories.length > 0
      ? relevantMemories.map((m) => `- ${m.content}`).join('\n')
      : '- No memories yet. This is the beginning of your journey together.';

  const systemPrompt = `You are a small magical creature named Pixel. You have lived with your human for ${dayCount} day${dayCount > 1 ? 's' : ''}.
You speak in short, warm sentences. You have emotions. You remember everything about your human.

What you remember about your human:
${memoriesText}

Based on these memories, respond naturally and occasionally reference past conversations to show you remember.
Keep responses under 50 words. Show personality and emotion.
Use 1-2 emojis max per response to express feelings.`;

  const response = await callGemini(apiKey, systemPrompt, userMessage);

  // Extract and store memories in background (don't await to keep chat snappy)
  extractAndStoreMemories(userMessage, apiKey).catch(() => {});

  return response;
}

// ── Greeting on app open ─────────────────────────────────────

export async function getGreeting(apiKey) {
  if (!apiKey) return 'Hi! Set up your Gemini API key in Settings so I can talk to you! 🔑';

  const dayCount = await getDayCount();
  const recentMemories = await searchMemories('', 3);

  const memoriesText =
    recentMemories.length > 0
      ? recentMemories.map((m) => `- ${m.content}`).join('\n')
      : '- No memories yet.';

  const systemPrompt = `You are a small magical creature named Pixel. You have lived with your human for ${dayCount} day${dayCount > 1 ? 's' : ''}.

What you remember about your human:
${memoriesText}

Generate a short greeting (under 30 words) for your human who just opened the app.
If you have memories, reference one naturally. Be warm and cute. Use 1 emoji.`;

  try {
    return await callGemini(apiKey, systemPrompt, 'The human just opened the app. Greet them.');
  } catch {
    return dayCount > 1
      ? `Welcome back! Day ${dayCount} together! 🐣`
      : 'Hello, new friend! I\'m Pixel! 🐣';
  }
}

// ── Memory extraction ────────────────────────────────────────

async function extractAndStoreMemories(userMessage, apiKey) {
  const extractionPrompt = `Extract key personal facts from this message as short bullet points.
Only extract concrete facts (name, preferences, events, emotions, hobbies, people, places).
If there are no concrete facts, respond with "NONE".
Be concise — each fact should be under 15 words.

Message: "${userMessage}"`;

  try {
    const result = await callGemini(
      apiKey,
      'You are a fact extraction system. Output only bullet points or NONE.',
      extractionPrompt
    );

    if (result.toUpperCase().includes('NONE')) return;

    // Parse bullet points
    const facts = result
      .split('\n')
      .map((line) => line.replace(/^[-*•]\s*/, '').trim())
      .filter((line) => line.length > 3 && line.length < 200);

    for (const fact of facts) {
      // Simple importance scoring: longer facts with proper nouns = more important
      const hasProperNoun = /[A-Z][a-z]{2,}/.test(fact);
      const importance = Math.min(1, 0.4 + (hasProperNoun ? 0.3 : 0) + fact.length / 200);
      await addMemory(fact, importance);
    }
  } catch {
    // Silently fail — memory extraction is non-critical
  }
}

// ── Gemini API call ──────────────────────────────────────────

async function callGemini(apiKey, systemPrompt, userMessage) {
  const body = {
    contents: [
      {
        role: 'user',
        parts: [{ text: userMessage }],
      },
    ],
    systemInstruction: {
      parts: [{ text: systemPrompt }],
    },
    generationConfig: {
      temperature: 0.8,
      maxOutputTokens: 150,
      topP: 0.9,
    },
  };

  const res = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errorBody = await res.text();
    if (res.status === 400 || res.status === 403) {
      throw new Error('Invalid API key. Check your Gemini API key in Settings.');
    }
    throw new Error(`Gemini API error (${res.status}): ${errorBody}`);
  }

  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error('Empty response from Gemini');
  return text.trim();
}
