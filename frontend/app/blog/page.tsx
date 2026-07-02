import Link from "next/link";
import { getPages } from "@/lib/wagtail";

export const metadata = { title: "Blog — Nora" };

export default async function BlogIndex() {
  const posts = await getPages("cms.BlogPage", { order: "-date" });

  return (
    <>
      <h1>Blog</h1>
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
