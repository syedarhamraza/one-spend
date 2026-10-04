"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { AnimatePresence, motion } from "motion/react";
import { useSite } from "./Providers";
import { prefersReduced } from "@/lib/useReduced";

const KEY = "onespend.intro.seen";
// Decided once per page load, so a re-run effect (React StrictMode in dev) sees the same answer.
let firstVisit: boolean | undefined;
const settle = [0.2, 0, 0, 1] as const;

/**
 * First-visit intro: the icon's three glass cards stack in, the real icon settles over them,
 * then the black curtain lifts into the hero. Skipped for repeat visits in a session and for
 * reduced motion. The curtain is server-rendered so the hero never flashes before it.
 */
export function Intro() {
  const { setIntroDone } = useSite();
  const [show, setShow] = useState(true);
  const [phase, setPhase] = useState<"stack" | "icon">("stack");

  useEffect(() => {
    if (firstVisit === undefined) {
      firstVisit = true;
      try {
        firstVisit = sessionStorage.getItem(KEY) !== "1";
        sessionStorage.setItem(KEY, "1");
      } catch {}
    }
    if (!firstVisit || prefersReduced()) {
      setShow(false);
      setIntroDone(true);
      return;
    }
    document.documentElement.style.overflow = "hidden";
    const t1 = setTimeout(() => setPhase("icon"), 900);
    const t2 = setTimeout(() => setShow(false), 1600);
    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
      document.documentElement.style.overflow = "";
    };
  }, [setIntroDone]);

  return (
    <AnimatePresence
      onExitComplete={() => {
        document.documentElement.style.overflow = "";
        setIntroDone(true);
      }}
    >
      {show && (
        <motion.div
          key="intro"
          aria-hidden
          className="fixed inset-0 z-[100] grid place-items-center bg-black"
          exit={{ clipPath: "inset(0 0 100% 0)" }}
          initial={{ clipPath: "inset(0 0 0% 0)" }}
          transition={{ duration: 0.9, ease: [0.65, 0, 0.35, 1] }}
        >
          <motion.div
            className="relative h-36 w-36"
            exit={{ y: -60, opacity: 0, scale: 0.9 }}
            transition={{ duration: 0.6, ease: settle }}
          >
            {/* The icon's card stack, as simple glass slabs. */}
            {[0, 1, 2].map((i) => (
              <motion.span
                key={i}
                className="absolute inset-x-[14%] h-[44%] rounded-[20px] border border-white/30 bg-[#4d8dff]/25 backdrop-blur-sm"
                style={{ top: `${16 + i * 11}%`, zIndex: i }}
                initial={{ y: 80, opacity: 0, scale: 0.86 }}
                animate={phase === "stack" ? { y: 0, opacity: 1, scale: 1 - (2 - i) * 0.07 } : { opacity: 0, scale: 1 }}
                transition={{ delay: phase === "stack" ? 0.12 + i * 0.12 : 0, duration: 0.6, ease: settle }}
              />
            ))}
            <motion.div
              className="absolute inset-0"
              initial={{ opacity: 0, scale: 0.8 }}
              animate={phase === "icon" ? { opacity: 1, scale: 1 } : undefined}
              transition={{ type: "spring", stiffness: 260, damping: 20 }}
            >
              <Image
                src="/brand/icon.png"
                alt=""
                width={144}
                height={144}
                priority
                className="rounded-[38px] shadow-[0_24px_80px_-10px_rgb(3_129_254/0.7)]"
              />
            </motion.div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
