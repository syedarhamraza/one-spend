"use client";

import { useId } from "react";
import { motion } from "motion/react";

/** OneUISegmentedPills (dense): a few exclusive options in one capsule with a sliding thumb. */
export function SegmentedPills<T extends string>({
  options,
  value,
  onChange,
  label,
}: {
  options: { value: T; label: string }[];
  value: T;
  onChange: (v: T) => void;
  label: string;
}) {
  const id = useId();
  return (
    <div role="radiogroup" aria-label={label} className="flex rounded-[var(--radius-pill)] bg-black/50 p-1">
      {options.map((o) => {
        const on = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            role="radio"
            aria-checked={on}
            onClick={() => onChange(o.value)}
            className={`relative flex-1 rounded-[var(--radius-pill)] px-2 py-2 text-[13px] whitespace-nowrap transition-colors ${
              on ? "font-semibold text-ink" : "text-ink-2 hover:text-ink"
            }`}
          >
            {on && (
              <motion.span
                layoutId={`seg-${id}`}
                transition={{ type: "spring", stiffness: 420, damping: 36 }}
                className="absolute inset-0 rounded-[var(--radius-pill)] bg-pill-active"
              />
            )}
            <span className="relative">{o.label}</span>
          </button>
        );
      })}
    </div>
  );
}
