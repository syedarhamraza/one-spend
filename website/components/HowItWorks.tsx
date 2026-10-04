"use client";

import { useRef, useState } from "react";
import {
  AnimatePresence,
  motion,
  useMotionValueEvent,
  useScroll,
  useTransform,
  type MotionValue,
} from "motion/react";
import { BellSimpleIcon, CheckIcon, PlusIcon } from "@phosphor-icons/react";
import Image from "next/image";
import { NOTIFICATIONS, SAMPLE_SUBS } from "@/lib/site";
import { SubIcon } from "./SubIcon";

const settle = [0.2, 0, 0, 1] as const;

/* ---------- Step 1: one-tap popular starts (FirstRunEmptyState / popular presets) ---------- */

function AddDemo() {
  const [added, setAdded] = useState<string[]>([]);
  const list = SAMPLE_SUBS.filter((s) => added.includes(s.name));
  const total = list.reduce((a, s) => a + parseFloat(s.price.slice(1)), 0);

  return (
    <div className="grid gap-4 sm:grid-cols-[1.1fr_1fr]">
      <div className="grid grid-cols-3 gap-2.5">
        {SAMPLE_SUBS.map((s) => {
          const on = added.includes(s.name);
          return (
            <button
              key={s.name}
              type="button"
              onClick={() => setAdded((a) => (on ? a.filter((n) => n !== s.name) : [...a, s.name]))}
              aria-pressed={on}
              className={`relative flex flex-col items-center gap-2 rounded-[var(--radius-inner)] px-2 py-4 transition-[background-color,transform] duration-300 active:scale-[0.96] ${
                on ? "bg-white/[0.09]" : "bg-white/[0.04] hover:bg-white/[0.07]"
              }`}
            >
              <SubIcon sub={s} size={44} />
              <span className="line-clamp-1 text-[13px]">{s.name}</span>
              <span className={`absolute top-2 right-2 grid h-5 w-5 place-items-center rounded-full transition-colors ${on ? "bg-accent" : "bg-white/10"}`}>
                {on ? <CheckIcon size={12} weight="bold" /> : <PlusIcon size={12} weight="bold" />}
              </span>
            </button>
          );
        })}
      </div>

      <div className="flex min-h-[260px] flex-col rounded-[var(--radius-card)] bg-black/50 p-4">
        <div className="mb-2 flex items-baseline justify-between px-1">
          <span className="text-[13.5px] font-bold text-section">Your subscriptions</span>
          <motion.span key={total} initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} className="tabular text-[13.5px] text-ink-2">
            ${total.toFixed(2)} / month
          </motion.span>
        </div>
        {list.length === 0 ? (
          <p className="m-auto max-w-[22ch] text-center text-[14px] text-ink-3">Tap a service to add it. Prices and dates stay editable.</p>
        ) : (
          <ul className="space-y-1">
            <AnimatePresence initial={false}>
              {list.map((s) => (
                <motion.li
                  key={s.name}
                  layout
                  initial={{ opacity: 0, y: 24, scale: 0.96 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, x: 30 }}
                  transition={{ type: "spring", stiffness: 380, damping: 30 }}
                  className="flex items-center gap-3 rounded-[16px] px-2 py-2"
                >
                  <SubIcon sub={s} size={30} />
                  <span className="flex-1 truncate text-[14.5px]">{s.name}</span>
                  <span className="tabular text-[14px] font-bold">{s.price}</span>
                </motion.li>
              ))}
            </AnimatePresence>
          </ul>
        )}
      </div>
    </div>
  );
}

/* ---------- Step 2: the notification shade, with NotificationPlanner's wording ---------- */

function NotifyDemo() {
  return (
    <div className="mx-auto w-full max-w-[440px] rounded-[30px] bg-[#0d0d0f] p-3 shadow-[0_30px_80px_-20px_rgb(0_0_0/0.9)]">
      <div className="flex items-baseline justify-between px-3 pt-2 pb-3">
        <span className="tabular text-[34px] font-semibold tracking-[-0.03em]">9:00</span>
        <span className="text-[13px] text-ink-2">Sun, October 4</span>
      </div>
      <div className="space-y-2">
        {NOTIFICATIONS.map((n, i) => (
          <motion.div
            key={n.title}
            initial={{ opacity: 0, y: -24, scale: 0.97 }}
            whileInView={{ opacity: 1, y: 0, scale: 1 }}
            viewport={{ once: true, amount: 0.6 }}
            transition={{ delay: 0.25 + i * 0.45, type: "spring", stiffness: 260, damping: 24 }}
            className="rounded-[22px] bg-[#232326] p-3.5"
          >
            <div className="flex items-center gap-2 text-[12px] text-ink-2">
              <Image src="/brand/icon.png" alt="" width={18} height={18} className="rounded-[5px]" />
              One Spend <span className="text-ink-3">· {n.channel}</span>
              <span className="ml-auto text-ink-3">{i === 0 ? "now" : `${i * 2}h ago`}</span>
            </div>
            <p className="mt-1.5 text-[15px] font-semibold">{n.title}</p>
            <p className="mt-0.5 text-[13.5px] leading-snug text-ink-2">{n.body}</p>
          </motion.div>
        ))}
      </div>
    </div>
  );
}

/* ---------- Step 3: the budget card filling as renewals land (scroll-scrubbed) ---------- */

const BUDGET = 150;
function trackColor(p: number) {
  // The app's budget track: blue, then orange near the limit, red over it.
  return p < 0.75 ? "#2f8bff" : p < 1 ? "#fb8c00" : "#f07167";
}

function BudgetDemo({ progress }: { progress: MotionValue<number> }) {
  const spent = useTransform(progress, [0, 1], [61.2, 158.4]);
  const amount = useRef<HTMLSpanElement>(null);
  const left = useRef<HTMLSpanElement>(null);
  const [tone, setTone] = useState("#2f8bff");
  const width = useTransform(spent, (v) => `${Math.min(v / BUDGET, 1) * 100}%`);

  useMotionValueEvent(spent, "change", (v) => {
    if (amount.current) amount.current.textContent = `$${v.toFixed(2)}`;
    if (left.current) left.current.textContent = v <= BUDGET ? `$${Math.round(BUDGET - v)} left` : `$${Math.round(v - BUDGET)} over`;
    const c = trackColor(v / BUDGET);
    setTone((t) => (t === c ? t : c));
  });

  return (
    <div className="relative mx-auto w-full max-w-[540px]">
      <motion.div
        className="pointer-events-none absolute -inset-16 rounded-full blur-3xl"
        animate={{ backgroundColor: tone }}
        style={{ opacity: 0.22 }}
        transition={{ duration: 0.6 }}
      />
      <div className="rim relative rounded-[var(--radius-card)] bg-[#18181a] p-7 sm:p-8">
        <div className="flex items-center justify-between">
          <span className="text-[15px] font-semibold text-ink-2">Monthly budget</span>
          <motion.span
            ref={left}
            animate={{ color: tone === "#f07167" ? "#f07167" : "#00c05a", backgroundColor: tone === "#f07167" ? "rgb(240 113 103 / 0.15)" : "rgb(0 192 90 / 0.15)" }}
            className="tabular rounded-full px-3 py-1 text-[13px] font-semibold"
          >
            $89 left
          </motion.span>
        </div>
        <p className="mt-4 flex items-baseline gap-2">
          <span ref={amount} className="tabular text-[clamp(2.5rem,4vw,3.4rem)] leading-none font-bold tracking-[-0.035em]">
            $61.20
          </span>
          <span className="tabular text-[17px] text-ink-2">/ ${BUDGET}</span>
        </p>
        <div className="mt-6 h-3.5 overflow-hidden rounded-full bg-white/8">
          <motion.div className="h-full rounded-full" style={{ width }} animate={{ backgroundColor: tone }} transition={{ duration: 0.5 }} />
        </div>
        <p className="mt-4 text-[13.5px] text-ink-2">Scroll to let the month's renewals land.</p>
      </div>
    </div>
  );
}

/* ---------- The stack ---------- */

const STEPS = [
  {
    title: "Add.",
    body: "Start from a popular service with one tap, or build your own with a custom icon, price and billing cycle.",
  },
  {
    title: "Get reminded.",
    body: "A notice before each renewal, at the time you choose. Cards about to expire and months heading over budget get one too.",
    icon: true,
  },
  {
    title: "Stay on budget.",
    body: "Set a monthly limit. The budget card fills as renewals land and turns orange, then red, as you get close.",
  },
];

function StackCard({
  i,
  next,
  children,
}: {
  i: number;
  next: React.RefObject<HTMLDivElement | null> | null;
  children: React.ReactNode;
}) {
  // The card shrinks and dims as the next one slides over it (skill §5.A, done with CSS sticky + Motion).
  const { scrollYProgress } = useScroll({ target: next ?? undefined, offset: ["start end", "start start"] });
  const scale = useTransform(scrollYProgress, [0, 1], [1, next ? 0.92 : 1]);
  const dim = useTransform(scrollYProgress, [0, 1], [0, next ? 0.55 : 0]);
  const step = STEPS[i];

  return (
    <motion.div style={{ scale }} className="relative h-full origin-top">
      <div className="relative grid h-full grid-cols-1 content-center gap-8 overflow-hidden rounded-[var(--radius-card)] bg-[#111113] p-6 sm:p-10 md:grid-cols-12 md:gap-10 md:p-14">
        <div className="pointer-events-none absolute -top-40 -left-40 h-96 w-96 rounded-full bg-[#48b5a0]/12 blur-3xl" />
        <div className="relative md:col-span-5">
          <h3 className="text-[clamp(2.5rem,5vw,4.75rem)] leading-[0.95] font-bold tracking-[-0.055em]">{step.title}</h3>
          <p className="mt-5 max-w-[36ch] text-[16.5px] leading-relaxed text-ink-2">{step.body}</p>
          {step.icon && (
            <p className="mt-6 inline-flex items-center gap-2 rounded-full bg-white/[0.05] px-4 py-2 text-[13.5px] text-ink-2">
              <BellSimpleIcon size={16} weight="fill" className="text-[#48b5a0]" /> Local notifications, no server
            </p>
          )}
        </div>
        <div className="relative md:col-span-7">{children}</div>
        <motion.div style={{ opacity: dim }} className="pointer-events-none absolute inset-0 rounded-[inherit] bg-black" />
      </div>
    </motion.div>
  );
}

export function HowItWorks() {
  const c2 = useRef<HTMLDivElement>(null);
  const c3 = useRef<HTMLDivElement>(null);
  const tail = useRef<HTMLDivElement>(null);
  // Step 3's budget fills while the last card stays pinned over the tail spacer.
  const { scrollYProgress: fill } = useScroll({ target: tail, offset: ["start end", "end end"] });

  const wrap = "sticky top-0 flex h-[100dvh] items-center px-3 py-20 sm:px-8 md:py-24";

  return (
    <section id="how" className="relative mx-auto max-w-[1400px] pt-24 md:pt-36">
      <h2 className="px-4 text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.05em] sm:px-8">
        Three steps. <span className="text-ink-2">Then it runs itself.</span>
      </h2>
      <div className="relative">
        <div className={wrap}>
          <StackCard i={0} next={c2}>
            <AddDemo />
          </StackCard>
        </div>
        <div ref={c2} className={wrap}>
          <StackCard i={1} next={c3}>
            <NotifyDemo />
          </StackCard>
        </div>
        <div ref={c3} className={wrap}>
          <StackCard i={2} next={null}>
            <BudgetDemo progress={fill} />
          </StackCard>
        </div>
        <div ref={tail} className="h-[70vh]" aria-hidden />
      </div>
    </section>
  );
}
