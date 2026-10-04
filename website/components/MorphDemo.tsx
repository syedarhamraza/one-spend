"use client";

import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { useReduced } from "@/lib/useReduced";
import {
  ArrowCounterClockwiseIcon,
  PauseIcon,
  ShareNetworkIcon,
  TrashIcon,
} from "@phosphor-icons/react";
import { SubIcon } from "./SubIcon";
import { SAMPLE_SUBS } from "@/lib/site";

const UNDO_MS = 8000;
const lumen = SAMPLE_SUBS[2];

/**
 * The detail screen's action bar. Renew morphs the same glass surface into an inline Undo for
 * 8 seconds, with OneUIMorphSwitcher timing: old content clears in ~110 ms, the shape resizes
 * over 340 ms on an emphasized curve, then the new content settles in.
 */
export function MorphDemo() {
  const [renewed, setRenewed] = useState(false);
  const reduce = useReduced();

  useEffect(() => {
    if (!renewed) return;
    const t = setTimeout(() => setRenewed(false), UNDO_MS);
    return () => clearTimeout(t);
  }, [renewed]);

  const shape = reduce ? { duration: 0 } : { duration: 0.34, ease: [0.2, 0, 0, 1] as const };
  const swap = reduce ? { duration: 0 } : { duration: 0.2, delay: 0.12, ease: [0.33, 1, 0.68, 1] as const };

  return (
    <section id="morph" className="relative isolate overflow-hidden px-4 py-24 sm:px-8 md:py-32">
      <div className="pointer-events-none absolute top-1/2 left-1/2 -z-10 h-[60vmax] w-[60vmax] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[radial-gradient(closest-side,rgb(126_87_194/0.16),transparent)]" />
      <div className="mx-auto max-w-[900px] text-center">
        <h2 className="text-[clamp(2.75rem,7vw,6.5rem)] leading-[0.95] font-bold tracking-[-0.055em]">
          Morph, <span className="text-ink-2">don&rsquo;t swap.</span>
        </h2>
        <p className="mx-auto mt-6 max-w-[44ch] text-[17px] leading-relaxed text-ink-2">
          When something changes mode, the same surface reshapes. Try it: renew Lumen AI, then take it back.
        </p>
      </div>

      <div className="mx-auto mt-16 max-w-[420px]">
        <div className="rounded-[var(--radius-card)] bg-card p-5">
          <div className="flex items-center gap-4">
            <SubIcon sub={lumen} size={56} />
            <div className="flex-1">
              <p className="text-[19px] font-bold tracking-[-0.02em]">Lumen AI Plan</p>
              <p className="tabular text-[14px] text-ink-2">$20, monthly</p>
            </div>
          </div>
          <div className="mt-5 flex items-center justify-between rounded-[var(--radius-inner)] bg-white/[0.04] px-4 py-3.5">
            <span className="text-[15px] text-ink-2">Next billing</span>
            <span className="text-right">
              <AnimatePresence mode="popLayout" initial={false}>
                <motion.span
                  key={String(renewed)}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  transition={{ duration: 0.25, ease: [0.33, 1, 0.68, 1] }}
                  className="tabular block text-[15px] font-bold"
                >
                  {renewed ? "Nov 09, 2026" : "Oct 09, 2026"}
                </motion.span>
              </AnimatePresence>
              <span className="tabular block text-[13px] text-amber">{renewed ? "in 37 days" : "in 6 days"}</span>
            </span>
          </div>
        </div>

        <div className="mt-6 flex justify-center">
          <motion.div layout transition={shape} className="glass rim overflow-hidden rounded-[var(--radius-pill)]" style={{ borderRadius: 34 }}>
            <AnimatePresence mode="popLayout" initial={false}>
              {renewed ? (
                <motion.div
                  key="undo"
                  layout="position"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1, transition: swap }}
                  exit={{ opacity: 0, transition: { duration: 0.11 } }}
                  className="flex items-center gap-4 py-2 pr-2 pl-6"
                >
                  <span className="text-[15px] whitespace-nowrap text-ink-2">Renewed to Nov 9</span>
                  <button
                    type="button"
                    onClick={() => setRenewed(false)}
                    className="relative overflow-hidden rounded-[var(--radius-pill)] bg-accent/15 px-5 py-2.5 text-[15px] font-semibold text-accent active:scale-[0.96]"
                  >
                    {!reduce && (
                      <motion.span
                        className="absolute inset-y-0 left-0 w-full origin-left bg-accent/15"
                        initial={{ scaleX: 1 }}
                        animate={{ scaleX: 0 }}
                        transition={{ duration: UNDO_MS / 1000, ease: "linear" }}
                      />
                    )}
                    <span className="relative">Undo</span>
                  </button>
                </motion.div>
              ) : (
                <motion.div
                  key="actions"
                  layout="position"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1, transition: swap }}
                  exit={{ opacity: 0, transition: { duration: 0.11 } }}
                  className="flex items-center px-2 py-1.5"
                >
                  {[
                    { label: "Renew", Icon: ArrowCounterClockwiseIcon, onClick: () => setRenewed(true), tone: "" },
                    { label: "Pause", Icon: PauseIcon, tone: "" },
                    { label: "Share", Icon: ShareNetworkIcon, tone: "" },
                    { label: "Delete", Icon: TrashIcon, tone: "text-red" },
                  ].map(({ label, Icon, onClick, tone }) => (
                    <button
                      key={label}
                      type="button"
                      onClick={onClick}
                      disabled={!onClick}
                      className={`flex w-[72px] flex-col items-center gap-1 rounded-[26px] py-2 text-[12.5px] transition-transform active:scale-[0.94] disabled:cursor-default ${tone} ${
                        onClick ? "hover:bg-white/[0.06]" : "opacity-60"
                      }`}
                    >
                      <Icon size={21} weight={label === "Renew" ? "bold" : "regular"} className={label === "Renew" ? "-scale-x-100" : ""} />
                      {label}
                    </button>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
