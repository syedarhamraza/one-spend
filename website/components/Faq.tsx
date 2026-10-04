"use client";

import { useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { CaretDownIcon } from "@phosphor-icons/react";
import { FAQ } from "@/lib/site";

/** Questions as One UI group-card rows. One answer open at a time; it grows out of its row. */
export function Faq() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section id="faq" className="mx-auto grid max-w-[1400px] grid-cols-1 gap-10 px-4 py-28 sm:px-8 md:py-36 lg:grid-cols-12">
      <h2 className="text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.05em] lg:col-span-4">
        Questions, <span className="text-ink-2">answered.</span>
      </h2>
      <div className="overflow-hidden rounded-[var(--radius-card)] bg-card lg:col-span-8">
        {FAQ.map((f, i) => {
          const on = open === i;
          return (
            <div key={f.q} className={i ? "border-t border-white/[0.06]" : ""}>
              <h3>
                <button
                  type="button"
                  aria-expanded={on}
                  aria-controls={`faq-${i}`}
                  onClick={() => setOpen(on ? null : i)}
                  className="flex w-full items-center gap-4 px-6 py-5 text-left transition-colors hover:bg-white/[0.02] sm:px-8"
                >
                  <span className={`flex-1 text-[17px] sm:text-[18px] ${on ? "font-semibold" : ""}`}>{f.q}</span>
                  <motion.span
                    animate={{ rotate: on ? 180 : 0 }}
                    transition={{ duration: 0.34, ease: [0.2, 0, 0, 1] }}
                    className={`grid h-8 w-8 shrink-0 place-items-center rounded-full ${on ? "bg-accent/15 text-accent" : "bg-white/[0.05] text-ink-2"}`}
                  >
                    <CaretDownIcon size={16} weight="bold" />
                  </motion.span>
                </button>
              </h3>
              <AnimatePresence initial={false}>
                {on && (
                  <motion.div
                    id={`faq-${i}`}
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: "auto", opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.34, ease: [0.2, 0, 0, 1] }}
                    className="overflow-hidden"
                  >
                    <p className="max-w-[62ch] px-6 pb-6 text-[16px] leading-relaxed text-ink-2 sm:px-8">{f.a}</p>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          );
        })}
      </div>
    </section>
  );
}
