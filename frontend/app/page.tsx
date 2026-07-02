import Link from "next/link";
import { getPages } from "@/lib/wagtail";

export default async function HomePage() {
  const [home] = await getPages("cms.HomePage");
  const posts = await getPages("cms.BlogPage", {
    order: "-date",
    limit: "5",
  });

  return (
    <>
      <h1>{home?.title ?? "Nora"}</h1>
      {home?.intro ? (
        <div
          className="rich-text"
          dangerouslySetInnerHTML={{ __html: home.intro }}
        />
      ) : (
        <p className="notice">
          No content yet — log into the Wagtail admin and edit the home page.
        </p>
      )}

      <h2>Latest posts</h2>
      {posts.length === 0 ? (
        <p className="notice">No posts published yet.</p>
      ) : (
        <ul className="post-list">
          {posts.map((post) => (
            <li key={post.id}>
              <Link href={`/blog/${post.meta.slug}`}>{post.title}</Link>
              {post.date && <div className="date">{post.date}</div>}
              {post.intro && <p>{post.intro}</p>}
            </li>
          ))}
        </ul>
      )}
    </>
  );
}
