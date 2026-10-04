"use client";

import { useLayoutEffect, useRef, useState } from "react";
import {
  animate,
  motion,
  useMotionValue,
  useScroll,
  useSpring,
  useTransform,
} from "motion/react";
import { prefersReduced, useReduced } from "@/lib/useReduced";
import { ArrowDownIcon } from "@phosphor-icons/react";
import { PhoneFrame } from "./PhoneFrame";
import { BudgetCard } from "./BudgetCard";
import { PlayButton } from "./PlayButton";
import { useSite } from "./Providers";

const HEADLINE = ["Know", "what", "renews", "before", "it", "does."];
const EMPH = new Set(["renews"]);
const settle = [0.2, 0, 0, 1] as const;

// Where the budget card sits inside the 1-subscriptions capture, as fractions of the capture.
const SLOT = { left: 0.039, top: 0.262, width: 0.922, height: 0.295 };
// PhoneFrame geometry: bezel padding (fraction of frame width) and status bar (fraction of screen height).
const BEZEL = 0.032;
const STATUS = 0.054;

export function Hero() {
  const ref = useRef<HTMLElement>(null);
  const phone = useRef<HTMLDivElement>(null);
  const cardBox = useRef<HTMLDivElement>(null);
  const reduce = useReduced();
  const { introDone } = useSite();
  const [lifted, setLifted] = useState(false);

  // Pointer tilt on the device, kept in motion values so React never re-renders per frame.
  const px = useMotionValue(0);
  const py = useMotionValue(0);
  const rx = useSpring(useTransform(py, [-0.5, 0.5], [6, -6]), { stiffness: 120, damping: 18 });
  const ry = useSpring(useTransform(px, [-0.5, 0.5], [-8, 8]), { stiffness: 120, damping: 18 });

  // The lift: the card starts exactly over its twin in the screenshot, then comes off the screen.
  const liftX = useMotionValue(0);
  const liftY = useMotionValue(0);
  const liftS = useMotionValue(1);
  const liftO = useMotionValue(0);

  // On scroll the phone drifts up slower than the page and the card faster: depth, not decoration.
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end start"] });
  const phoneY = useTransform(scrollYProgress, [0, 1], [0, -90]);
  const cardY = useTransform(scrollYProgress, [0, 1], [0, -220]);
  const fade = useTransform(scrollYProgress, [0.55, 1], [1, 0]);

  useLayoutEffect(() => {
    if (!introDone) return;
    if (prefersReduced()) {
      liftO.set(1);
      return;
    }
    if (!phone.current || !cardBox.current) return;
    // offsetLeft/Top ignore transforms, so this is the resting layout regardless of entry motion.
    const p = phone.current;
    const c = cardBox.current;
    const W = p.offsetWidth;
    const innerW = W * (1 - 2 * BEZEL);
    const innerH = p.offsetHeight - 2 * BEZEL * W;
    const imgTop = p.offsetTop + BEZEL * W + STATUS * innerH;
    const imgH = innerH * (1 - STATUS);
    const scale = (innerW * SLOT.width) / c.offsetWidth;
    liftX.set(p.offsetLeft + BEZEL * W + innerW * SLOT.left - c.offsetLeft);
    liftY.set(imgTop + imgH * SLOT.top - c.offsetTop);
    liftS.set(scale);

    const opts = { delay: 1.45, duration: 1.15, ease: settle };
    const show = animate(liftO, 1, { delay: 1.35, duration: 0.01 });
    const ax = animate(liftX, 0, opts);
    const ay = animate(liftY, 0, opts);
    const as = animate(liftS, 1, opts);
    const t = setTimeout(() => setLifted(true), 1450);
    return () => {
      [show, ax, ay, as].forEach((a) => a.stop());
      clearTimeout(t);
    };
  }, [introDone, liftX, liftY, liftS, liftO]);

  function onMove(e: React.PointerEvent) {
    if (reduce || e.pointerType !== "mouse") return;
    const r = e.currentTarget.getBoundingClientRect();
    px.set((e.clientX - r.left) / r.width - 0.5);
    py.set((e.clientY - r.top) / r.height - 0.5);
  }

  return (
    <section
      id="overview"
      ref={ref}
      onPointerMove={onMove}
      onPointerLeave={() => {
        px.set(0);
        py.set(0);
      }}
      className="relative isolate overflow-hidden md:min-h-[100dvh]"
    >
      {/* Ambient glow, as behind the app's glass hero cards. */}
      <div className="pointer-events-none absolute top-[8%] right-[-12%] -z-10 h-[70vmax] w-[70vmax] rounded-full bg-[radial-gradient(closest-side,rgb(3_129_254/0.28),rgb(3_129_254/0.06)_55%,transparent)] max-md:top-[34%] max-md:right-[-40%]" />

      {/* Room for the fixed SiteHeader. */}
      <div className="h-[72px]" />

      <div className="mx-auto grid max-w-[1400px] grid-cols-1 items-center gap-14 px-4 pt-8 pb-40 sm:px-8 md:grid-cols-12 md:pt-10 md:pb-28">
        <motion.div style={{ opacity: fade }} className="md:col-span-7">
          <h1 className="text-[clamp(3rem,6.2vw,6.25rem)] leading-[0.95] font-bold tracking-[-0.055em]">
            {HEADLINE.map((w, i) => (
              <span key={i} className="inline-block overflow-hidden pb-[0.08em] align-bottom">
                <motion.span
                  className={`inline-block ${EMPH.has(w) ? "text-accent" : ""}`}
                  initial={{ y: "105%", rotate: 4 }}
                  animate={introDone ? { y: 0, rotate: 0 } : undefined}
                  transition={{ delay: 0.15 + i * 0.07, duration: 0.9, ease: settle }}
                >
                  {w}
                </motion.span>
                {i < HEADLINE.length - 1 && " "}
              </span>
            ))}
          </h1>
          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={introDone ? { opacity: 1, y: 0 } : undefined}
            transition={{ delay: 0.7, duration: 0.8, ease: settle }}
            className="mt-7 max-w-[32ch] text-[clamp(1.1rem,1.45vw,1.3rem)] leading-snug text-ink-2"
          >
            Every subscription, card and renewal, tracked on your phone. Built to feel at home on One UI.
          </motion.p>
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={introDone ? { opacity: 1, y: 0 } : undefined}
            transition={{ delay: 0.85, duration: 0.8, ease: settle }}
            className="mt-10 flex flex-wrap items-center gap-3"
          >
            <PlayButton />
            <a
              href="#tour"
              className="group inline-flex h-14 items-center gap-2 rounded-[var(--radius-pill)] px-6 text-[16px] font-semibold text-ink transition-colors hover:bg-white/[0.06] active:scale-[0.97]"
            >
              Take the tour
              <ArrowDownIcon size={18} weight="bold" className="transition-transform duration-300 group-hover:translate-y-0.5" />
            </a>
          </motion.div>
        </motion.div>

        <div className="relative md:col-span-5" style={{ perspective: 1400 }}>
          <motion.div style={{ y: phoneY }}>
            <motion.div
              ref={phone}
              style={{ rotateX: rx, rotateY: ry }}
              initial={{ opacity: 0, y: 120, rotate: -5 }}
              animate={introDone ? { opacity: 1, y: 0, rotate: 0 } : undefined}
              transition={{ delay: 0.2, duration: 1.1, ease: settle }}
              className="relative mx-auto w-[min(70vw,330px)] md:mr-0 md:ml-auto lg:mr-[8%]"
            >
              <PhoneFrame src="/screens/1-subscriptions.webp" alt="One Spend's Subscriptions tab with the monthly budget card" priority>
                {/* The empty slot the card leaves behind once lifted. */}
                <motion.span
                  aria-hidden
                  initial={false}
                  animate={{ opacity: lifted ? 1 : 0 }}
                  transition={{ duration: 0.8, ease: settle }}
                  className="absolute rounded-[7%/14%] bg-black/70 shadow-[inset_0_0_0_1px_rgb(255_255_255/0.06)]"
                  style={{
                    left: `${SLOT.left * 100}%`,
                    width: `${SLOT.width * 100}%`,
                    top: `${(STATUS + (1 - STATUS) * SLOT.top) * 100}%`,
                    height: `${(1 - STATUS) * SLOT.height * 100}%`,
                  }}
                />
              </PhoneFrame>
            </motion.div>
          </motion.div>

          <div
            ref={cardBox}
            className="absolute inset-x-0 bottom-[-14%] mx-auto w-[min(88vw,370px)] md:right-auto md:bottom-[6%] md:left-[-22%] md:mx-0 lg:left-[-12%]"
          >
            <motion.div style={{ y: cardY }}>
              <motion.div
                style={{ x: liftX, y: liftY, scale: liftS, opacity: liftO, transformOrigin: "0 0" }}
                className={`transition-[filter] duration-1000 ${lifted ? "drop-shadow-[0_40px_60px_rgb(0_0_0/0.8)]" : ""}`}
              >
                <BudgetCard still />
              </motion.div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
}
