import Link from "next/link";
import { getPages } from "@/lib/wagtail";

export const metadata = { title: "Design Plans — Nora" };

export default async function DesignPlanIndex() {
  const plans = await getPages("cms.DesignPlanPage");

  return (
    <>
      <h1>Design Plans</h1>
      {plans.length === 0 ? (
        <p className="notice">No design plans published yet.</p>
      ) : (
        <ul className="post-list">
          {plans.map((plan) => (
            <li key={plan.id}>
              <Link href={`/design-plans/${plan.meta.slug}`}>{plan.title}</Link>
              {plan.intro && <p>{plan.intro}</p>}
            </li>
          ))}
        </ul>
      )}
    </>
  );
}
