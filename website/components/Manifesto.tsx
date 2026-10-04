"use client";

import { useRef } from "react";
import { motion, useScroll, useTransform, type MotionValue } from "motion/react";
import { useReduced } from "@/lib/useReduced";

const TEXT =
  "No account. No sign-in. Your subscriptions, prices and cards stay on your phone, and leave it only when you save a backup or export a file.";
const KEY = new Set(["account.", "sign-in.", "phone,"]);

function Word({ word, i, n, progress }: { word: string; i: number; n: number; progress: MotionValue<number> }) {
  const start = i / n;
  const opacity = useTransform(progress, [start, start + 1 / n], [0.16, 1]);
  return (
    <motion.span style={{ opacity }} className={KEY.has(word) ? "text-accent" : ""}>
      {word}{" "}
    </motion.span>
  );
}

/** The privacy statement lights up word by word as you read down, then the fine print. */
export function Manifesto() {
  const ref = useRef<HTMLDivElement>(null);
  const reduce = useReduced();
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start 80%", "end 45%"] });
  const words = TEXT.split(" ");

  return (
    <section id="privacy" className="mx-auto max-w-[1400px] px-4 py-24 sm:px-8 md:py-32">
      <div ref={ref}>
        <p className="max-w-[22ch] text-[clamp(2.25rem,5.4vw,5.4rem)] leading-[1.04] font-bold tracking-[-0.05em]">
          {reduce
            ? TEXT
            : words.map((w, i) => <Word key={i} word={w} i={i} n={words.length} progress={scrollYProgress} />)}
        </p>
      </div>
      <div className="mt-16 grid gap-10 md:ml-[40%] md:grid-cols-2">
        <p className="text-[16px] leading-relaxed text-ink-2">
          Payment cards are stored as a nickname and the last four digits. Never a full card number.
        </p>
        <p className="text-[16px] leading-relaxed text-ink-2">
          Anonymous crash reports and usage stats help fix bugs. They never include names, prices, notes or anything you
          type.{" "}
          <a href="/privacy/" className="text-ink underline decoration-ink-3 underline-offset-4 hover:decoration-ink">
            Privacy policy
          </a>
        </p>
      </div>
    </section>
  );
}
