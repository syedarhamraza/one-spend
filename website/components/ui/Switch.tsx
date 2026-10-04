"use client";

import { motion } from "motion/react";

/** OneUISwitch (visual only): the row around it carries role="switch", as the app's whole row toggles. */
export function Switch({ on }: { on: boolean }) {
  return (
    <span
      aria-hidden
      className={`relative inline-flex h-[28px] w-[48px] shrink-0 items-center rounded-full px-[3px] transition-colors duration-200 ${
        on ? "bg-accent" : "bg-[#3e3e42]"
      }`}
    >
      <motion.span
        layout
        transition={{ type: "spring", stiffness: 600, damping: 34 }}
        className={`h-[22px] w-[22px] rounded-full bg-white shadow-[0_1px_3px_rgb(0_0_0/0.4)] ${on ? "ml-auto" : ""}`}
      />
    </span>
  );
}
