const API_BASE = process.env.WAGTAIL_API_URL ?? "http://localhost:8000";

export interface WagtailPage {
  id: number;
  title: string;
  meta: {
    slug: string;
    type: string;
    first_published_at?: string;
  };
  intro?: string;
  body_html?: string;
  video_url?: string;
  date?: string;
}

interface PagesResponse {
  meta: { total_count: number };
  items: WagtailPage[];
}

/**
 * Query the Wagtail pages API. Returns [] when the backend is unreachable
 * (e.g. during a docker build) so the frontend degrades instead of crashing.
 */
export async function getPages(
  type: string,
  extra: Record<string, string> = {},
): Promise<WagtailPage[]> {
  const qs = new URLSearchParams({ type, fields: "*", ...extra });
  try {
    const res = await fetch(`${API_BASE}/api/v2/pages/?${qs}`, {
      next: { revalidate: 60 },
    });
    if (!res.ok) return [];
    const data: PagesResponse = await res.json();
    return data.items;
  } catch {
    return [];
  }
}

export async function getPageBySlug(
  type: string,
  slug: string,
): Promise<WagtailPage | null> {
  const items = await getPages(type, { slug });
  return items[0] ?? null;
}
