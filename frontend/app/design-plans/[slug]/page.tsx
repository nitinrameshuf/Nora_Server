import { notFound } from "next/navigation";
import VideoEmbed from "@/components/VideoEmbed";
import { getPageBySlug } from "@/lib/wagtail";

export default async function DesignPlan({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const plan = await getPageBySlug("cms.DesignPlanPage", slug);
  if (!plan) notFound();

  return (
    <article>
      <h1>{plan.title}</h1>
      {plan.intro && (
        <p>
          <strong>{plan.intro}</strong>
        </p>
      )}
      <VideoEmbed url={plan.video_url} />
      {plan.body_html && (
        <div
          className="rich-text"
          dangerouslySetInnerHTML={{ __html: plan.body_html }}
        />
      )}
    </article>
  );
}
