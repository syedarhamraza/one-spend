"use client";

import { useState } from "react";
import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { CubeIcon, CreditCardIcon, TagIcon, ArrowsClockwiseIcon } from "@phosphor-icons/react";
import { SubIcon } from "./SubIcon";
import { Switch } from "./ui/Switch";
import { SegmentedPills } from "./ui/SegmentedPills";
import { useSite } from "./Providers";

type PriceMode = "billed" | "monthly" | "amount";
type BadgeMode = "countdown" | "date" | "both";

const SUBS = [
  { name: "Streamly", icon: "film", color: "#e5484d", price: 15.99, yearly: false, days: 2, date: "Oct 5", category: "Entertainment", catColor: "#e5484d", card: "#283593" },
  { name: "Lumen AI", icon: "sparkle", color: "#8b5cf6", price: 20, yearly: false, days: 6, date: "Oct 9", category: "Productivity & AI", catColor: "#5390f5", card: "#283593" },
  { name: "Mailbox Pro", icon: "mail", color: "#1aa7ec", price: 39, yearly: true, days: 47, date: "Nov 19", category: "Cloud", catColor: "#34aadc", card: "#c62828" },
] as const;

function price(s: (typeof SUBS)[number], mode: PriceMode) {
  if (mode === "monthly") return { main: `$${(s.yearly ? s.price / 12 : s.price).toFixed(2)}`, unit: "/mo" };
  if (mode === "amount") return { main: `$${Number.isInteger(s.price) ? s.price : s.price.toFixed(2)}`, unit: "" };
  return { main: `$${s.price.toFixed(2)}`, unit: s.yearly ? "/yr" : "/mo" };
}

function badge(s: (typeof SUBS)[number], mode: BadgeMode) {
  const count = `In ${s.days} days`;
  if (mode === "date") return s.date;
  if (mode === "both") return `${count}, ${s.date}`;
  return count;
}

function Row({
  icon,
  title,
  subtitle,
  on,
  onToggle,
}: {
  icon: React.ReactNode;
  title: string;
  subtitle: string;
  on: boolean;
  onToggle: () => void;
}) {
  return (
    <button type="button" role="switch" aria-checked={on} onClick={onToggle} className="flex w-full items-center gap-3.5 px-4 py-3.5 text-left hover:bg-white/[0.02]">
      {icon}
      <span className="min-w-0 flex-1">
        <span className="block text-[16px]">{title}</span>
        <span className="block text-[13.5px] text-ink-2">{subtitle}</span>
      </span>
      <Switch on={on} />
    </button>
  );
}

const Badge = ({ color, children }: { color: string; children: React.ReactNode }) => (
  <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full" style={{ background: color }}>
    {children}
  </span>
);

/**
 * Settings › Subscription cards, live. The preview list reshapes as you change options, and the
 * 3D switch restyles this page's own floating chrome the way it does the app's.
 */
export function Customizer() {
  const { float3d, setFloat3d } = useSite();
  const [priceMode, setPriceMode] = useState<PriceMode>("billed");
  const [badgeMode, setBadgeMode] = useState<BadgeMode>("countdown");
  const [payment, setPayment] = useState(true);
  const [category, setCategory] = useState(false);
  const [cycle, setCycle] = useState(false);

  return (
    <section id="yours" className="mx-auto max-w-[1400px] px-4 pt-28 pb-12 sm:px-8 md:pt-36">
      <h2 className="max-w-[18ch] text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.05em]">
        Make it yours. <span className="text-ink-2">Every card, your way.</span>
      </h2>

      <div className="mt-14 grid grid-cols-1 items-start gap-6 lg:grid-cols-12">
        {/* Preview */}
        <div className="relative overflow-hidden rounded-[var(--radius-card)] bg-[#0c0c0e] p-4 sm:p-8 lg:sticky lg:top-24 lg:col-span-6">
          <div className="pointer-events-none absolute -top-32 -right-24 h-80 w-80 rounded-full bg-green/15 blur-3xl" />
          <p className="relative mb-3 px-2 text-[13.5px] font-bold text-section">All subscriptions (3)</p>
          <LayoutGroup>
            <motion.div layout className="relative rounded-[var(--radius-card)] bg-card px-3 py-1.5">
              {SUBS.map((s, i) => {
                const p = price(s, priceMode);
                return (
                  <motion.div
                    layout
                    key={s.name}
                    transition={{ type: "spring", stiffness: 380, damping: 34 }}
                    className={`flex items-center gap-3.5 px-1 py-3.5 ${i ? "border-t border-white/[0.06]" : ""}`}
                  >
                    <motion.span layout className="relative">
                      <SubIcon sub={s} size={48} />
                      <AnimatePresence>
                        {payment && (
                          <motion.span
                            initial={{ scale: 0, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0, opacity: 0 }}
                            transition={{ type: "spring", stiffness: 500, damping: 28 }}
                            className="absolute -right-1.5 -bottom-1.5 grid h-[18px] w-[26px] place-items-center rounded-[5px] ring-2 ring-card"
                            style={{ background: s.card }}
                          >
                            <CreditCardIcon size={11} weight="fill" color="#fff" />
                          </motion.span>
                        )}
                      </AnimatePresence>
                    </motion.span>
                    <motion.div layout className="min-w-0 flex-1">
                      <p className="truncate text-[16px]">{s.name}</p>
                      <AnimatePresence mode="popLayout" initial={false}>
                        <motion.p
                          key={badgeMode}
                          initial={{ opacity: 0, y: 6 }}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, y: -6 }}
                          transition={{ duration: 0.2 }}
                          className={`truncate text-[13.5px] ${s.days <= 3 ? "text-red" : "text-ink-2"}`}
                        >
                          {badge(s, badgeMode)}
                        </motion.p>
                      </AnimatePresence>
                      <AnimatePresence initial={false}>
                        {(category || cycle) && (
                          <motion.div
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: "auto" }}
                            exit={{ opacity: 0, height: 0 }}
                            transition={{ duration: 0.3, ease: [0.2, 0, 0, 1] }}
                            className="flex flex-wrap gap-1.5 overflow-hidden pt-1.5"
                          >
                            {category && (
                              <span
                                className="rounded-full px-2.5 py-0.5 text-[11.5px] font-semibold"
                                style={{ color: s.catColor, background: `color-mix(in srgb, ${s.catColor} 16%, transparent)` }}
                              >
                                {s.category}
                              </span>
                            )}
                            {cycle && (
                              <span className="rounded-full bg-white/[0.07] px-2.5 py-0.5 text-[11.5px] font-semibold text-ink-2">
                                {s.yearly ? "Yearly" : "Monthly"}
                              </span>
                            )}
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </motion.div>
                    <motion.span layout="position" className="tabular text-right">
                      <AnimatePresence mode="popLayout" initial={false}>
                        <motion.span
                          key={p.main + p.unit}
                          initial={{ opacity: 0, y: 8 }}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, y: -8 }}
                          transition={{ duration: 0.22 }}
                          className="block text-[16px] font-bold"
                        >
                          {p.main}
                          <span className="text-[12.5px] font-semibold text-ink-2">{p.unit}</span>
                        </motion.span>
                      </AnimatePresence>
                    </motion.span>
                  </motion.div>
                );
              })}
            </motion.div>
          </LayoutGroup>
          <div className="relative mt-6 flex justify-center">
            <span
              className={`${float3d ? "glass-3d rim" : "glass"} flex items-center gap-5 rounded-[var(--radius-pill)] px-7 py-3 text-[16px] font-semibold transition-[background,box-shadow] duration-500`}
            >
              <span>Cancel</span>
              <span className="h-5 w-px bg-white/15" />
              <span>Save</span>
            </span>
          </div>
        </div>

        {/* Options, as an OneUIGroupCard */}
        <div className="space-y-6 lg:col-span-6">
          <div>
            <p className="mb-2 px-4 text-[13.5px] font-bold tracking-[-0.2px] text-section">Display options</p>
            <div className="space-y-4 rounded-[var(--radius-card)] bg-card p-4">
              <div>
                <p className="mb-2 px-1 text-[15px]">Price display</p>
                <SegmentedPills
                  label="Price display"
                  value={priceMode}
                  onChange={setPriceMode}
                  options={[
                    { value: "billed", label: "Billed" },
                    { value: "monthly", label: "Monthly" },
                    { value: "amount", label: "Amount only" },
                  ]}
                />
              </div>
              <div>
                <p className="mb-2 px-1 text-[15px]">Renewal badge</p>
                <SegmentedPills
                  label="Renewal badge"
                  value={badgeMode}
                  onChange={setBadgeMode}
                  options={[
                    { value: "countdown", label: "Countdown" },
                    { value: "date", label: "Date" },
                    { value: "both", label: "Both" },
                  ]}
                />
              </div>
            </div>
          </div>

          <div>
            <p className="mb-2 px-4 text-[13.5px] font-bold tracking-[-0.2px] text-section">Card details</p>
            <div className="divide-y divide-white/[0.06] overflow-hidden rounded-[var(--radius-card)] bg-card">
              <Row
                icon={<Badge color="#283593"><CreditCardIcon size={19} weight="fill" color="#fff" /></Badge>}
                title="Payment method"
                subtitle="Corner badge with the linked card"
                on={payment}
                onToggle={() => setPayment((v) => !v)}
              />
              <Row
                icon={<Badge color="#f07167"><TagIcon size={19} weight="fill" color="#fff" /></Badge>}
                title="Category"
                subtitle="Show the category tag"
                on={category}
                onToggle={() => setCategory((v) => !v)}
              />
              <Row
                icon={<Badge color="#48b5a0"><ArrowsClockwiseIcon size={19} weight="bold" color="#fff" /></Badge>}
                title="Billing cycle"
                subtitle="Show the renewal period"
                on={cycle}
                onToggle={() => setCycle((v) => !v)}
              />
            </div>
          </div>

          <div>
            <p className="mb-2 px-4 text-[13.5px] font-bold tracking-[-0.2px] text-section">Appearance</p>
            <div className="overflow-hidden rounded-[var(--radius-card)] bg-card">
              <Row
                icon={<Badge color="#7e57c2"><CubeIcon size={19} weight="fill" color="#fff" /></Badge>}
                title="3D floating elements"
                subtitle={float3d ? "On. Look at the nav bar below." : "Nav bar, buttons and pills. Try it here."}
                on={float3d}
                onToggle={() => setFloat3d(!float3d)}
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
