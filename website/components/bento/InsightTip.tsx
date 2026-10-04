"use client";

import { useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { XIcon } from "@phosphor-icons/react";
import { INSIGHTS } from "@/lib/site";

/**
 * OneUIInsightCard: one tip at a time, tone-coloured centred headline, light grey pill action,
 * a glow in the tone colour. Swipe it away or tap Got it; "Show dismissed tips" brings them back.
 */
export function InsightTip() {
  const [i, setI] = useState(0);
  const tip = INSIGHTS[i];

  return (
    <div className="relative h-[230px]">
      <AnimatePresence mode="popLayout" initial={false}>
        {tip ? (
          <motion.div
            key={tip.title}
            drag="x"
            dragSnapToOrigin
            onDragEnd={(_, info) => Math.abs(info.offset.x) > 90 && setI((v) => v + 1)}
            initial={{ opacity: 0, y: 30, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, x: 140, rotate: 6 }}
            transition={{ type: "spring", stiffness: 300, damping: 28 }}
            className="relative cursor-grab overflow-hidden rounded-[var(--radius-card)] bg-black/45 px-5 pt-6 pb-5 text-center active:cursor-grabbing"
          >
            <div
              className="pointer-events-none absolute -bottom-20 left-1/2 h-40 w-64 -translate-x-1/2 rounded-full opacity-35 blur-3xl"
              style={{ background: tip.tone }}
            />
            <button
              type="button"
              aria-label="Dismiss tip"
              onClick={() => setI((v) => v + 1)}
              className="absolute top-3 right-3 grid h-7 w-7 place-items-center rounded-full text-ink-3 hover:bg-white/[0.06] hover:text-ink-2"
            >
              <XIcon size={14} weight="bold" />
            </button>
            <p className="relative text-[19px] leading-tight font-bold tracking-[-0.02em]" style={{ color: tip.tone }}>
              {tip.title}
            </p>
            <p className="relative mt-2 text-[14px] text-section">{tip.body}</p>
            <p className="tabular relative mt-1 text-[12px] text-ink-3">
              {i + 1} of {INSIGHTS.length}
            </p>
            <button
              type="button"
              onClick={() => setI((v) => v + 1)}
              className="relative mt-4 w-full rounded-[var(--radius-pill)] bg-[#b5b5ba] py-2.5 text-[15px] font-semibold text-[#0e0e10] active:scale-[0.98]"
            >
              Got it
            </button>
          </motion.div>
        ) : (
          <motion.div
            key="empty"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="grid h-full place-items-center rounded-[var(--radius-card)] bg-black/30 text-center"
          >
            <div>
              <p className="text-[15px] text-ink-2">No more tips.</p>
              <button type="button" onClick={() => setI(0)} className="mt-2 text-[15px] font-semibold text-accent">
                Show dismissed tips
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
