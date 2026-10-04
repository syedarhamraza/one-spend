"use client";

import { useState } from "react";
import { useMotionValueEvent, useScroll } from "motion/react";

/**
 * The id of the last listed section whose top has passed the middle of the viewport.
 * Pinned scenes add spacer height, so reading rects is more reliable than intersection bands.
 */
export function useActiveSection(ids: readonly string[]) {
  const [active, setActive] = useState(ids[0]);
  const { scrollY } = useScroll();
  useMotionValueEvent(scrollY, "change", () => {
    const mid = window.innerHeight * 0.5;
    let id = ids[0];
    for (const s of ids) {
      const el = document.getElementById(s);
      if (el && el.getBoundingClientRect().top <= mid) id = s;
    }
    setActive((prev) => (prev === id ? prev : id));
  });
  return active;
}
