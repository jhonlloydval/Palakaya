// Palakaya Advisor: answers a fisher's question using their own records and current fair prices.
// Runs on Supabase Edge Functions (free tier) and Google Gemini (free tier), so no AI key ships in the app.
//
// Secrets (Supabase → Edge Functions → Secrets):
//   GEMINI_API_KEY  required, free from https://aistudio.google.com/apikey
//   GEMINI_MODEL    optional, defaults to "gemini-flash-latest"

const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-flash-latest";

const SYSTEM = `You are the Palakaya Advisor, helping small-scale municipal fishers in the Philippines.
Answer in the language the fisher writes in (Filipino, English, or Taglish). Keep answers short: 2–5 sentences,
plain words, no jargon, no markdown headings or tables.

Ground every number in the DATA block you are given (their catch records and the fair-price ranges).
Fair prices marked "estimate" are rough regional averages, not guarantees; say so when you quote one.
Prices marked with a sale count come from real recorded sales in the app.
If the data does not answer the question, say what you don't know and suggest what to log or check.
Never invent prices, buyers, weather or regulations. For safety at sea, storms or legal matters,
tell them to follow PAGASA, the Coast Guard, or their Municipal Agriculture / Fisheries Office.
Palakaya does not handle payments; never ask for money, passwords or ID numbers.`;

type Turn = { role: "user" | "assistant"; text: string };
type Message = { role: "user" | "assistant"; content: string };

const SORRY = "Pasensya na, wala akong sagot ngayon. Subukan ulit.";

class AdvisorError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

async function askGemini(messages: Message[]): Promise<string> {
  if (!GEMINI_KEY) throw new AdvisorError(500, "Advisor is not set up (missing GEMINI_API_KEY)");
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": GEMINI_KEY },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: SYSTEM }] },
        contents: messages.map((m) => ({
          role: m.role === "assistant" ? "model" : "user",
          parts: [{ text: m.content }],
        })),
        generationConfig: { maxOutputTokens: 1024 },
      }),
    },
  );
  if (res.status === 429) throw new AdvisorError(429, "Free AI limit reached, try again in a minute");
  if (!res.ok) throw new AdvisorError(502, `Advisor error ${res.status}`);
  const data = await res.json();
  const parts = data?.candidates?.[0]?.content?.parts ?? [];
  return parts.map((p: { text?: string }) => p.text ?? "").join("").trim();
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  let question: string, context: unknown, history: Turn[];
  try {
    const body = await req.json();
    question = String(body.question ?? "").trim().slice(0, 1000);
    context = body.context ?? {};
    history = Array.isArray(body.history) ? body.history.slice(-6) : [];
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }
  if (!question) return json({ error: "Missing question" }, 400);

  const messages: Message[] = [
    ...history
      .filter((t) => (t.role === "user" || t.role === "assistant") && typeof t.text === "string" && t.text)
      .map((t) => ({ role: t.role, content: t.text.slice(0, 2000) })),
    {
      role: "user",
      content: `DATA (from the Palakaya app, JSON):\n${JSON.stringify(context).slice(0, 12000)}\n\nQUESTION:\n${question}`,
    },
  ];
  // The API needs alternating turns that start with the user.
  while (messages.length > 1 && messages[0].role !== "user") messages.shift();

  try {
    const reply = await askGemini(messages);
    return json({ reply: reply || SORRY });
  } catch (error) {
    if (error instanceof AdvisorError) return json({ error: error.message }, error.status);
    return json({ error: "Advisor unavailable" }, 500);
  }
});
