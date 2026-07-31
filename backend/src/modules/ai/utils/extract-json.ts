/** Los modelos suelen envolver el JSON en fences ```json ... ``` — esto lo extrae de forma tolerante. */
export function extractJson<T>(text: string): T {
  const fenced = /```(?:json)?\s*([\s\S]*?)```/i.exec(text);
  const candidate = fenced ? fenced[1] : text;
  const start = candidate.search(/[[{]/);
  const trimmed = start >= 0 ? candidate.slice(start) : candidate;
  return JSON.parse(trimmed.trim()) as T;
}
