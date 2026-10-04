"use client";

import { useEffect, useRef } from "react";
import { animate, motion, useInView } from "motion/react";
import { useReduced } from "@/lib/useReduced";
import { CaretRightIcon } from "@phosphor-icons/react";

const SPENT = 106.18;
const BUDGET = 150;
const PCT = Math.round((SPENT / BUDGET) * 100);

/**
 * A faithful port of the app's Monthly budget glass card, with the numbers from the demo catalog.
 * The amount counts up and the track fills when it comes into view.
 */
export function BudgetCard({ delay = 0.9, still = false }: { delay?: number; still?: boolean }) {
  const ref = useRef<HTMLDivElement>(null);
  const amount = useRef<HTMLSpanElement>(null);
  const pct = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, amount: 0.4 });
  const reduce = useReduced() || still;

  useEffect(() => {
    if (!inView || reduce) return;
    const c = animate(0, 1, {
      delay,
      duration: 1.5,
      ease: [0.33, 1, 0.68, 1],
      onUpdate: (t) => {
        if (amount.current) amount.current.textContent = `$${(SPENT * t).toFixed(2)}`;
        if (pct.current) pct.current.textContent = `${Math.round(PCT * t)}%`;
      },
    });
    return () => c.stop();
  }, [inView, reduce, delay]);

  return (
    <div
      ref={ref}
      className="rim relative overflow-hidden rounded-[var(--radius-card)] bg-[#18181a] p-5 shadow-[0_30px_80px_-20px_rgb(0_0_0/0.9)] sm:p-6"
    >
      {/* OneUIAmbientGlow: blue while under budget. */}
      <div className="pointer-events-none absolute -top-24 -left-16 h-64 w-64 rounded-full bg-glow/25 blur-3xl" />
      <div className="relative flex items-center justify-between">
        <span className="flex items-center gap-1 text-[15px] font-semibold text-ink-2">
          Monthly budget <CaretRightIcon size={13} weight="bold" />
        </span>
        <span className="rounded-full bg-green/15 px-3 py-1 text-[13px] font-semibold text-green tabular">$44 left</span>
      </div>
      <div className="relative mt-4 flex items-end justify-between">
        <p className="flex items-baseline gap-2">
          <span ref={amount} className="tabular text-[34px] leading-none font-bold tracking-[-0.03em]">
            ${reduce ? SPENT.toFixed(2) : "0.00"}
          </span>
          <span className="tabular text-[17px] text-ink-2">/ ${BUDGET}</span>
        </p>
        <span ref={pct} className="tabular text-[19px] font-bold text-accent">
          {reduce ? PCT : 0}%
        </span>
      </div>
      <div className="relative mt-4 h-2.5 overflow-hidden rounded-full bg-white/8">
        <motion.div
          className="h-full origin-left rounded-full bg-[linear-gradient(90deg,#0b5fe8,#2f8bff_50%,#f4a261_78%,#fb8c00)]"
          style={{ width: `${PCT}%` }}
          initial={reduce ? false : { scaleX: 0 }}
          animate={inView ? { scaleX: 1 } : undefined}
          transition={{ delay, duration: 1.5, ease: [0.33, 1, 0.68, 1] }}
        />
      </div>
      <div className="relative mt-4 space-y-3 rounded-[var(--radius-inner)] bg-white/[0.04] px-4 py-3.5 text-[14px]">
        <div className="flex justify-between">
          <span className="text-ink-2">Daily burn</span>
          <span className="tabular font-bold">~$3.54 / day</span>
        </div>
        <div className="h-px bg-white/[0.06]" />
        <div className="flex justify-between">
          <span className="text-ink-2">Next renewal</span>
          <span className="text-right">
            <span className="block font-bold">Streamly</span>
            <span className="tabular text-[13px] text-ink-2">Oct 05, in 2 days</span>
          </span>
        </div>
      </div>
    </div>
  );
}
