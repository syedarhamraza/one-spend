"use client";

import { motion } from "motion/react";
import {
  CompassIcon,
  PaintBrushIcon,
  QuestionIcon,
  SquaresFourIcon,
  WalletIcon,
} from "@phosphor-icons/react";
import { SECTIONS } from "@/lib/site";
import { useActiveSection } from "@/lib/useActiveSection";
import { useSite } from "./Providers";

const ICONS = { overview: WalletIcon, tour: CompassIcon, features: SquaresFourIcon, yours: PaintBrushIcon, faq: QuestionIcon };
const IDS = SECTIONS.map((s) => s.id);

/**
 * The app's floating nav bar (OneUIFloatingNavBar) as page navigation: a bottom glass capsule
 * within thumb reach, with one sliding active capsule that follows the section in view.
 * It switches to the 3D glass when the customizer's "3D floating elements" is on.
 */
export function GlassNav() {
  const active = useActiveSection(IDS);
  const { introDone, float3d } = useSite();

  return (
    <>
      {/* OneUIBottomVignette: keeps content legible under the floating capsule. */}
      <div className="pointer-events-none fixed inset-x-0 bottom-0 z-30 h-32 bg-gradient-to-t from-black via-black/70 to-transparent" />
      <motion.nav
        aria-label="Sections"
        initial={{ y: 120, opacity: 0 }}
        animate={introDone ? { y: 0, opacity: 1 } : undefined}
        transition={{ delay: 0.9, duration: 0.7, ease: [0.2, 0, 0, 1] }}
        className={`${float3d ? "glass-3d rim" : "glass"} fixed bottom-[max(14px,env(safe-area-inset-bottom))] left-1/2 z-40 flex -translate-x-1/2 gap-0.5 rounded-[var(--radius-pill)] p-[6px] transition-[background,box-shadow] duration-500`}
      >
        {SECTIONS.map((s) => {
          const Icon = ICONS[s.id];
          const on = active === s.id;
          return (
            <a
              key={s.id}
              href={`#${s.id}`}
              aria-current={on ? "true" : undefined}
              className="relative flex w-[66px] flex-col items-center gap-0.5 rounded-[28px] py-2 text-[11.5px] outline-none transition-[transform] duration-200 active:scale-[0.96] focus-visible:ring-2 focus-visible:ring-accent sm:w-[84px] sm:text-[12px]"
            >
              {on && (
                <motion.span
                  layoutId="nav-capsule"
                  className={`absolute -inset-x-[4px] inset-y-0 rounded-[28px] ${
                    float3d
                      ? "bg-[radial-gradient(120%_120%_at_50%_0%,#5a5a60,#3a3a3e_60%)] shadow-[inset_0_1px_0_rgb(255_255_255/0.22)]"
                      : "bg-pill-active shadow-[inset_0_1px_0_rgb(255_255_255/0.12)]"
                  }`}
                  transition={{ type: "spring", stiffness: 420, damping: 36 }}
                />
              )}
              <Icon size={22} weight={on ? "fill" : "regular"} className={`relative ${on ? "text-ink" : "text-ink-2"}`} />
              <span className={`relative ${on ? "font-semibold text-ink" : "text-ink-2"}`}>{s.label}</span>
            </a>
          );
        })}
      </motion.nav>
    </>
  );
}
