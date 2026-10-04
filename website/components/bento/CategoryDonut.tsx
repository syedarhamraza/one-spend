"use client";

import { useState } from "react";
import { motion } from "motion/react";
import { useReduced } from "@/lib/useReduced";
import { CATEGORY_SLICES } from "@/lib/site";

const R = 80;
const GAP = 0.006; // fraction of the ring left dark between slices, as in OneUICategoryRing

/** OneUICategoryRing: slices draw in on view; hovering a legend row dims the others. */
export function CategoryDonut() {
  const reduce = useReduced();
  const [hi, setHi] = useState<number | null>(null);
  const total = CATEGORY_SLICES.reduce((a, s) => a + s.share, 0);
  let acc = 0;

  const selected = hi == null ? null : CATEGORY_SLICES[hi];

  return (
    <div className="grid h-full grid-cols-1 items-center gap-8 sm:grid-cols-2">
      <div className="relative mx-auto aspect-square w-full max-w-[300px]">
        <svg viewBox="0 0 200 200" className="h-full w-full -rotate-90">
          {CATEGORY_SLICES.map((s, i) => {
            const frac = s.share / total;
            const start = acc;
            acc += frac;
            return (
              <motion.circle
                key={s.label}
                cx="100"
                cy="100"
                r={R}
                fill="none"
                stroke={s.color}
                strokeWidth={hi === i ? 26 : 22}
                transform={`rotate(${start * 360} 100 100)`}
                initial={reduce ? { pathLength: frac - GAP } : { pathLength: 0 }}
                whileInView={{ pathLength: frac - GAP }}
                animate={{ opacity: hi == null || hi === i ? 1 : 0.25 }}
                viewport={{ once: true, amount: 0.5 }}
                transition={{ delay: reduce ? 0 : i * 0.07, duration: 0.5, ease: [0.33, 1, 0.68, 1] }}
                style={{ transition: "stroke-width 300ms cubic-bezier(0.33,1,0.68,1)" }}
              />
            );
          })}
        </svg>
        <div className="absolute inset-0 grid place-items-center text-center">
          <div>
            <p className="tabular text-[clamp(1.4rem,2.4vw,1.9rem)] font-bold tracking-[-0.03em]">
              {selected ? `${selected.share}%` : "$106.18/mo"}
            </p>
            <p className="mt-0.5 text-[14px] text-ink-2">{selected ? selected.label : "9 categories"}</p>
          </div>
        </div>
      </div>
      <ul className="space-y-1" onPointerLeave={() => setHi(null)}>
        {CATEGORY_SLICES.slice(0, 5).map((s, i) => (
          <li key={s.label}>
            <button
              type="button"
              onPointerEnter={() => setHi(i)}
              onFocus={() => setHi(i)}
              onBlur={() => setHi(null)}
              className={`flex w-full items-center gap-3 rounded-2xl px-3 py-2 text-left transition-[background-color,opacity] duration-300 ${
                hi != null && hi !== i ? "opacity-45" : ""
              } ${hi === i ? "bg-white/[0.05]" : ""}`}
            >
              <span className="h-3 w-3 shrink-0 rounded-full" style={{ background: s.color }} />
              <span className="flex-1 text-[15px]">{s.label}</span>
              <span className="tabular text-[14px] text-ink-2">{s.share}%</span>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
