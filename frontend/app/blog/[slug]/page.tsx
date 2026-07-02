import { notFound } from "next/navigation";
import VideoEmbed from "@/components/VideoEmbed";
import { getPageBySlug } from "@/lib/wagtail";

export default async function BlogPost({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const post = await getPageBySlug("cms.BlogPage", slug);
  if (!post) notFound();

  return (
    <article>
      <h1>{post.title}</h1>
      {post.date && <p className="date">{post.date}</p>}
      {post.intro && (
        <p>
          <strong>{post.intro}</strong>
        </p>
      )}
      <VideoEmbed url={post.video_url} />
      {post.body_html && (
        <div
          className="rich-text"
          dangerouslySetInnerHTML={{ __html: post.body_html }}
        />
      )}
    </article>
  );
}
