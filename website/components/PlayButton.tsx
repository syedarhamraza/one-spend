"use client";

import { motion, useMotionValue, useSpring } from "motion/react";
import { GooglePlayLogoIcon } from "@phosphor-icons/react";
import { PLAY_LABEL, PLAY_URL } from "@/lib/site";
import { prefersReduced } from "@/lib/useReduced";

const PULL = 0.28;

/**
 * The page's single download action. Same label everywhere it appears. The large size leans
 * toward a mouse pointer (motion values only, no re-renders) and springs back when it leaves.
 */
export function PlayButton({ size = "lg" }: { size?: "sm" | "lg" }) {
  const lg = size === "lg";
  const mx = useMotionValue(0);
  const my = useMotionValue(0);
  const x = useSpring(mx, { stiffness: 220, damping: 18, mass: 0.6 });
  const y = useSpring(my, { stiffness: 220, damping: 18, mass: 0.6 });

  function onMove(e: React.PointerEvent<HTMLAnchorElement>) {
    if (!lg || e.pointerType !== "mouse" || prefersReduced()) return;
    const r = e.currentTarget.getBoundingClientRect();
    mx.set((e.clientX - (r.left + r.width / 2)) * PULL);
    my.set((e.clientY - (r.top + r.height / 2)) * PULL);
  }

  return (
    <motion.a
      href={PLAY_URL}
      target="_blank"
      rel="noopener"
      onPointerMove={onMove}
      onPointerLeave={() => {
        mx.set(0);
        my.set(0);
      }}
      style={{ x, y }}
      className={`group inline-flex items-center gap-2.5 rounded-[var(--radius-pill)] bg-ink font-semibold whitespace-nowrap text-[#0e0e10] transition-[background-color] duration-300 hover:bg-[#e9e9ee] active:scale-[0.97] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-accent ${
        lg ? "h-14 px-7 text-[16px]" : "h-10 px-4 text-[14px]"
      }`}
    >
      <GooglePlayLogoIcon
        size={lg ? 22 : 17}
        weight="fill"
        className="transition-transform duration-500 ease-[var(--ease-settle)] group-hover:-rotate-12"
      />
      {PLAY_LABEL}
    </motion.a>
  );
}
