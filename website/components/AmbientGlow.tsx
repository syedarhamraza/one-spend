"use client";

import { motion } from "motion/react";
import { GLOW_SECTIONS } from "@/lib/site";
import { useActiveSection } from "@/lib/useActiveSection";

const IDS = GLOW_SECTIONS.map((s) => s.id);

/**
 * One fixed glow behind the whole page that cross-fades to each scene's colour, like
 * OneUIAmbientGlow behind the app's hero cards. The colour always carries a meaning.
 */
export function AmbientGlow() {
  const active = useActiveSection(IDS);
  const color = GLOW_SECTIONS.find((s) => s.id === active)?.color ?? "#0381fe";

  return (
    <div aria-hidden className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
      <motion.div
        className="absolute -right-[20vmax] -bottom-[30vmax] h-[80vmax] w-[80vmax] rounded-full opacity-[0.16] blur-[90px]"
        animate={{ backgroundColor: color }}
        transition={{ duration: 1.2, ease: [0.65, 0, 0.35, 1] }}
      />
      <motion.div
        className="absolute -top-[35vmax] -left-[25vmax] h-[60vmax] w-[60vmax] rounded-full opacity-[0.08] blur-[90px]"
        animate={{ backgroundColor: color }}
        transition={{ duration: 1.6, ease: [0.65, 0, 0.35, 1] }}
      />
    </div>
  );
}
