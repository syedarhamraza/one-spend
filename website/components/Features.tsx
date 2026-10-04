"use client";

import { motion } from "motion/react";
import { useReduced } from "@/lib/useReduced";
import { CURRENCIES } from "@/lib/site";
import { CategoryDonut } from "./bento/CategoryDonut";
import { TimeWheel } from "./bento/TimeWheel";
import { MonthCalendar } from "./bento/MonthCalendar";
import { RestorePoints } from "./bento/RestorePoints";
import { PaymentCards } from "./bento/PaymentCards";
import { ExportShare } from "./bento/ExportShare";
import { InsightTip } from "./bento/InsightTip";

function Cell({
  className = "",
  style,
  title,
  body,
  children,
  i,
}: {
  className?: string;
  style?: React.CSSProperties;
  title: string;
  body: string;
  children: React.ReactNode;
  i: number;
}) {
  const reduce = useReduced();
  return (
    <motion.article
      initial={reduce ? false : { opacity: 0, y: 48 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.25 }}
      transition={{ delay: (i % 2) * 0.08, duration: 0.8, ease: [0.2, 0, 0, 1] }}
      style={style}
      className={`relative flex flex-col overflow-hidden rounded-[var(--radius-card)] p-6 sm:p-8 ${className}`}
    >
      <h3 className="relative text-[clamp(1.35rem,1.9vw,1.7rem)] leading-tight font-bold tracking-[-0.035em]">{title}</h3>
      <p className="relative mt-2 max-w-[42ch] text-[15.5px] leading-relaxed text-ink-2">{body}</p>
      <div className="relative mt-8 flex-1">{children}</div>
    </motion.article>
  );
}

export function Features() {
  return (
    <section id="features" className="mx-auto max-w-[1400px] px-4 pt-24 pb-12 sm:px-8 md:pt-32">
      <h2 className="max-w-[16ch] text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.05em]">
        The small things, <span className="text-ink-2">worked out.</span>
      </h2>

      <div className="mt-16 grid grid-cols-1 gap-3.5 md:grid-cols-6">
        <Cell
          i={0}
          className="bg-card md:col-span-4"
          title="See where it goes"
          body="Spending by category, from the 10 built-ins and any you make yourself."
        >
          <div className="pointer-events-none absolute -right-24 -bottom-32 h-80 w-80 rounded-full bg-glow/20 blur-3xl" />
          <CategoryDonut />
        </Cell>

        <Cell
          i={1}
          className="md:col-span-2"
          style={{ background: "linear-gradient(180deg, #1c1c1e, #111113)" }}
          title="Remind me at nine"
          body="Scroll the wheel. Each subscription can keep its own time."
        >
          <TimeWheel />
        </Cell>

        <Cell
          i={2}
          className="md:col-span-3"
          style={{ background: "radial-gradient(120% 90% at 0% 100%, rgb(40 53 147 / 0.35), transparent 60%), #1c1c1e" }}
          title="Every card, accounted for"
          body="See which subscriptions each card pays, and get a heads-up before one expires."
        >
          <PaymentCards />
        </Cell>

        <Cell
          i={3}
          className="bg-card md:col-span-3"
          title="The month at a glance"
          body="Tap a day to see what it charges."
        >
          <MonthCalendar />
        </Cell>

        <Cell
          i={4}
          className="md:col-span-2"
          style={{ background: "radial-gradient(120% 80% at 100% 0%, rgb(251 140 0 / 0.16), transparent 60%), #1c1c1e" }}
          title="Undo the big stuff"
          body="A restore point is saved before every Replace or Clear all. The last five are kept."
        >
          <RestorePoints />
        </Cell>

        <Cell
          i={5}
          className="bg-card md:col-span-2"
          title="Take it anywhere"
          body="A PDF report, a spreadsheet, a text summary, or renewals for your calendar."
        >
          <ExportShare />
        </Cell>

        <Cell
          i={6}
          className="md:col-span-2"
          style={{ background: "linear-gradient(180deg, #1c1c1e, #131315)" }}
          title="Tips that know your numbers"
          body="One at a time, only when there is something worth saying."
        >
          <InsightTip />
        </Cell>

        <Cell
          i={7}
          className="bg-card md:col-span-6"
          title={`${CURRENCIES.length} currencies`}
          body="Each subscription bills in its own currency. Totals convert to yours."
        >
          <div className="-mx-6 overflow-hidden [mask-image:linear-gradient(90deg,transparent,#000_12%,#000_88%,transparent)] sm:-mx-8">
            <div className="marquee-track flex w-max gap-2.5">
              {[...CURRENCIES, ...CURRENCIES].map((c, i) => (
                <span
                  key={i}
                  aria-hidden={i >= CURRENCIES.length}
                  className="tabular rounded-[var(--radius-pill)] bg-pill px-5 py-2.5 text-[15px] font-semibold text-section"
                >
                  {c}
                </span>
              ))}
            </div>
          </div>
        </Cell>
      </div>
    </section>
  );
}
