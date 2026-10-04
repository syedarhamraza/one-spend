"use client";

import { motion } from "motion/react";
import { useReduced } from "@/lib/useReduced";
import { ClockCounterClockwiseIcon } from "@phosphor-icons/react";

const POINTS = [
  { reason: "Before Replace everything", when: "Today, 6:41 PM", size: "11 subscriptions" },
  { reason: "Before Clear all", when: "Sep 28, 9:12 AM", size: "9 subscriptions" },
  { reason: "Before Replace everything", when: "Sep 14, 8:03 PM", size: "8 subscriptions" },
];

/** Backup & data › Restore points: a full snapshot is saved before every Replace or Clear all. */
export function RestorePoints() {
  const reduce = useReduced();
  return (
    <div className="rounded-[var(--radius-card)] bg-black/40 p-2">
      {POINTS.map((p, i) => (
        <motion.div
          key={p.when}
          initial={reduce ? false : { opacity: 0, x: -24 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true, amount: 0.6 }}
          transition={{ delay: i * 0.12, duration: 0.6, ease: [0.33, 1, 0.68, 1] }}
          className="flex items-center gap-3 rounded-[var(--radius-inner)] px-3 py-3"
        >
          <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-orange">
            <ClockCounterClockwiseIcon size={19} weight="bold" color="#fff" />
          </span>
          <span className="min-w-0 flex-1">
            <span className="block truncate text-[15px]">{p.reason}</span>
            <span className="tabular block truncate text-[13px] text-ink-2">
              {p.when}, {p.size}
            </span>
          </span>
        </motion.div>
      ))}
    </div>
  );
}
