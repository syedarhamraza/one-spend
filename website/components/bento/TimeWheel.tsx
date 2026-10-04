"use client";

import { useEffect, useRef, useState } from "react";

const ITEM = 64;
const HOURS = Array.from({ length: 12 }, (_, i) => String(i + 1));
const MINUTES = Array.from({ length: 12 }, (_, i) => String(i * 5).padStart(2, "0"));
const PERIOD = ["AM", "PM"];

/**
 * A web take on OneUITimeWheel: flat scroll columns that snap, with the centred value in white.
 * Selection is read with an IntersectionObserver on each column, never a scroll listener.
 */
function Column({
  items,
  initial,
  onPick,
  label,
  wide = false,
}: {
  items: string[];
  initial: number;
  onPick: (v: string) => void;
  label: string;
  wide?: boolean;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [sel, setSel] = useState(initial);

  useEffect(() => {
    const col = ref.current!;
    col.scrollTop = initial * ITEM;
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (!e.isIntersecting) continue;
          const i = Number((e.target as HTMLElement).dataset.i);
          setSel(i);
          onPick(items[i]);
        }
      },
      { root: col, rootMargin: `-${ITEM - 2}px 0px -${ITEM - 2}px 0px`, threshold: 0.5 },
    );
    col.querySelectorAll("[data-i]").forEach((el) => io.observe(el));
    return () => io.disconnect();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div
      ref={ref}
      role="listbox"
      aria-label={label}
      tabIndex={0}
      data-lenis-prevent
      className="no-scrollbar h-[192px] snap-y snap-mandatory overflow-y-auto overscroll-contain py-[64px] outline-none [mask-image:linear-gradient(transparent,#000_30%,#000_70%,transparent)]"
    >
      {items.map((v, i) => (
        <div
          key={v}
          data-i={i}
          role="option"
          aria-selected={sel === i}
          className={`tabular grid h-[64px] snap-center place-items-center font-semibold tracking-[-0.03em] transition-[color,transform] duration-200 ${
            wide ? "text-[34px] font-bold" : "text-[52px]"
          } ${sel === i ? "scale-100 text-ink" : "scale-[0.86] text-ink-3/70"}`}
        >
          {v}
        </div>
      ))}
    </div>
  );
}

export function TimeWheel() {
  const [h, setH] = useState("9");
  const [m, setM] = useState("00");
  const [p, setP] = useState("AM");

  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center justify-center gap-1">
        <div className="w-[76px]">
          <Column items={HOURS} initial={8} onPick={setH} label="Hour" />
        </div>
        <span className="pb-1 text-[44px] font-bold text-ink">:</span>
        <div className="w-[84px]">
          <Column items={MINUTES} initial={0} onPick={setM} label="Minute" />
        </div>
        <div className="ml-2 w-[64px]">
          <Column items={PERIOD} initial={0} onPick={setP} label="AM or PM" wide />
        </div>
      </div>
      <p className="mt-auto pt-6 text-[15px] text-ink-2" aria-live="polite">
        Alerts are delivered at{" "}
        <span className="tabular font-semibold text-ink">
          {h}:{m} {p}
        </span>
      </p>
    </div>
  );
}
