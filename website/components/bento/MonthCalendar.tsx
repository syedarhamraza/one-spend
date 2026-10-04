"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { SAMPLE_SUBS } from "@/lib/site";
import { SubIcon } from "../SubIcon";

// October 2026 starts on a Thursday. Today is the 3rd, matching the store captures.
const FIRST_WEEKDAY = 4;
const DAYS = 31;
const TODAY = 3;
const CHARGES: Record<number, number[]> = { 5: [0], 6: [1], 9: [2], 14: [3], 21: [5], 27: [0, 1] };

/** OneUIMonthCalendar: today ring, filled selected day, colour dots per charge. */
export function MonthCalendar() {
  const [sel, setSel] = useState(5);
  const cells = [...Array(FIRST_WEEKDAY).fill(null), ...Array.from({ length: DAYS }, (_, i) => i + 1)];
  const charges = (CHARGES[sel] ?? []).map((i) => SAMPLE_SUBS[i]);

  return (
    <div>
      <div className="mb-3 flex items-baseline justify-between">
        <p className="text-[17px] font-semibold">October 2026</p>
        <p className="tabular text-[14px] text-ink-2">7 charges</p>
      </div>
      <div className="grid grid-cols-7 text-center text-[12px] text-ink-3">
        {["S", "M", "T", "W", "T", "F", "S"].map((d, i) => (
          <span key={i} className="pb-2">
            {d}
          </span>
        ))}
      </div>
      <div className="grid grid-cols-7 gap-y-1">
        {cells.map((d, i) =>
          d == null ? (
            <span key={`e${i}`} />
          ) : (
            <button
              key={d}
              type="button"
              onClick={() => setSel(d)}
              aria-pressed={sel === d}
              aria-label={`October ${d}${CHARGES[d] ? `, ${CHARGES[d].length} charge` : ""}`}
              className="group flex flex-col items-center gap-[3px] py-0.5"
            >
              <span
                className={`tabular grid h-9 w-9 place-items-center rounded-full text-[14px] transition-colors duration-200 ${
                  sel === d
                    ? "bg-accent font-semibold text-white"
                    : d === TODAY
                      ? "ring-1 ring-ink-2 ring-inset"
                      : "group-hover:bg-white/[0.06]"
                } ${d < TODAY && sel !== d ? "text-ink-3" : ""}`}
              >
                {d}
              </span>
              <span className="flex h-1 gap-[3px]">
                {(CHARGES[d] ?? []).map((ci) => (
                  <span key={ci} className="h-1 w-1 rounded-full" style={{ background: SAMPLE_SUBS[ci].color }} />
                ))}
              </span>
            </button>
          ),
        )}
      </div>
      <div className="mt-4 min-h-[60px]">
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.div
            key={sel}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.22, ease: [0.33, 1, 0.68, 1] }}
            className="space-y-2"
          >
            {charges.length ? (
              charges.map((s) => (
                <div key={s.name} className="flex items-center gap-3 rounded-[var(--radius-inner)] bg-white/[0.04] px-3 py-2.5">
                  <SubIcon sub={s} size={30} />
                  <span className="flex-1 text-[15px]">{s.name}</span>
                  <span className="tabular text-[15px] font-bold">{s.price}</span>
                </div>
              ))
            ) : (
              <p className="px-1 pt-3 text-[14px] text-ink-3">Nothing renews on Oct {sel}.</p>
            )}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}
