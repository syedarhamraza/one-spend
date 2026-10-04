"use client";

import { useState } from "react";
import { motion } from "motion/react";
import { CreditCardIcon } from "@phosphor-icons/react";
import { PAYMENT_CARDS } from "@/lib/site";

/**
 * Payment methods as the app draws them (OneUIPaymentBrandIcon): network colour, a generic card
 * glyph, the nickname as text and the last four digits. Never a bank or network logo.
 * The stack fans out on hover or tap to show what each card pays for.
 */
export function PaymentCards() {
  const [open, setOpen] = useState(false);
  const n = PAYMENT_CARDS.length;

  return (
    <div
      className="relative h-[300px] cursor-pointer select-none"
      onPointerEnter={(e) => e.pointerType === "mouse" && setOpen(true)}
      onPointerLeave={(e) => e.pointerType === "mouse" && setOpen(false)}
      onClick={() => setOpen((o) => !o)}
      role="button"
      tabIndex={0}
      aria-expanded={open}
      aria-label="Show payment cards"
      onKeyDown={(e) => (e.key === "Enter" || e.key === " ") && setOpen((o) => !o)}
    >
      {PAYMENT_CARDS.map((c, i) => {
        const back = n - 1 - i; // 0 = front card
        return (
          <motion.div
            key={c.last4}
            className="absolute top-0 left-1/2 w-[min(100%,300px)] origin-bottom"
            style={{ zIndex: i }}
            initial={false}
            animate={
              open
                ? { x: "-50%", y: 110 - back * 55, rotate: 0, scale: 1 }
                : { x: "-50%", y: 70 - back * 18, rotate: (back - 1) * -4, scale: 1 - back * 0.05 }
            }
            transition={{ type: "spring", stiffness: 260, damping: 26 }}
          >
            <div
              className="aspect-[1.586] rounded-[20px] p-4 shadow-[0_18px_40px_-12px_rgb(0_0_0/0.8),inset_0_1px_0_rgb(255_255_255/0.18)]"
              style={{ background: `linear-gradient(135deg, ${c.color}, color-mix(in srgb, ${c.color} 55%, #000))` }}
            >
              <div className="flex items-start justify-between">
                <span className="text-[15px] font-semibold">{c.name}</span>
                <CreditCardIcon size={22} weight="fill" className="text-white/80" />
              </div>
              <motion.div
                animate={{ opacity: open ? 1 : 0 }}
                transition={{ duration: 0.25, delay: open ? 0.12 : 0 }}
                className="mt-2 flex flex-wrap gap-1"
              >
                <span className="text-[12px] text-white/75">Pays {c.pays.join(", ")}</span>
              </motion.div>
            </div>
            <div className="absolute right-4 bottom-3.5 left-4 flex items-center justify-between">
              <span className="tabular text-[14px] tracking-[0.12em] text-white/90">•••• {c.last4}</span>
              {c.expiring && (
                <span className="rounded-full bg-black/35 px-2.5 py-0.5 text-[11.5px] font-semibold text-amber">Expires {c.expiring}</span>
              )}
            </div>
          </motion.div>
        );
      })}
    </div>
  );
}
