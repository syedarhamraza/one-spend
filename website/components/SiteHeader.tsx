"use client";

import { useState } from "react";
import Image from "next/image";
import { motion, useMotionValueEvent, useScroll } from "motion/react";
import { useSite } from "./Providers";
import { PlayButton } from "./PlayButton";

/**
 * A full-width bar over the hero that morphs into a compact glass pill once you scroll past it
 * (the same surface reshaping, never a swap). It slides away while you scroll down and comes
 * back as soon as you scroll up.
 */
export function SiteHeader() {
  const { introDone, float3d } = useSite();
  const [compact, setCompact] = useState(false);
  const [hidden, setHidden] = useState(false);
  const { scrollY } = useScroll();

  useMotionValueEvent(scrollY, "change", (y) => {
    const prev = scrollY.getPrevious() ?? 0;
    const c = y > window.innerHeight * 0.55;
    setCompact((v) => (v === c ? v : c));
    const h = c && y > prev + 2;
    const shown = y < prev - 2;
    setHidden((v) => (h ? true : shown ? false : v));
  });

  const glass = float3d ? "glass-3d rim" : "glass";

  return (
    <motion.header
      initial={{ y: -90, opacity: 0 }}
      animate={introDone ? { y: hidden ? -100 : 0, opacity: 1 } : undefined}
      transition={{ duration: 0.45, ease: [0.65, 0, 0.35, 1] }}
      className="pointer-events-none fixed inset-x-0 top-0 z-50 flex justify-center px-4 pt-3 sm:px-8"
    >
      <motion.div
        layout
        transition={{ layout: { duration: 0.5, ease: [0.2, 0, 0, 1] } }}
        style={{ borderRadius: 34 }}
        className={`pointer-events-auto flex items-center justify-between ${
          compact ? `${glass} gap-6 py-1.5 pr-1.5 pl-3` : "w-full max-w-[1400px] py-1.5"
        }`}
      >
        <motion.a layout="position" href="#overview" className="flex items-center gap-2.5 text-[17px] font-semibold tracking-[-0.02em]">
          <Image src="/brand/icon.png" alt="" width={32} height={32} className="rounded-[9px]" priority />
          <span className={compact ? "max-sm:hidden" : ""}>One Spend</span>
        </motion.a>
        <motion.span layout="position" className={compact ? "" : "max-sm:hidden"}>
          <PlayButton size="sm" />
        </motion.span>
      </motion.div>
    </motion.header>
  );
}
