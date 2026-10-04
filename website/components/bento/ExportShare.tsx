"use client";

import { useRef, useState } from "react";
import { motion } from "motion/react";
import {
  CalendarBlankIcon,
  FileCsvIcon,
  FilePdfIcon,
  FileTextIcon,
  ShareNetworkIcon,
} from "@phosphor-icons/react";

const FILES = [
  { name: "Report.pdf", Icon: FilePdfIcon, x: -88, y: -118, r: -10 },
  { name: "Subscriptions.csv", Icon: FileCsvIcon, x: 70, y: -128, r: 8 },
  { name: "Summary.txt", Icon: FileTextIcon, x: -96, y: -54, r: -4 },
  { name: "Renewals.ics", Icon: CalendarBlankIcon, x: 82, y: -60, r: 5 },
];

/**
 * ExportShareScreen: the one place to export. The files fan out of the share button once the
 * tile is in view and stay out. Hovering the tile spreads them a little further; tapping the
 * button replays the fan.
 */
export function ExportShare() {
  const [shown, setShown] = useState(false);
  const [hover, setHover] = useState(false);
  const replay = useRef<ReturnType<typeof setTimeout>>(undefined);

  function again() {
    clearTimeout(replay.current);
    setShown(false);
    replay.current = setTimeout(() => setShown(true), 260);
  }

  const spread = hover ? 1.12 : 1;

  return (
    <motion.div
      className="relative flex h-[230px] items-end justify-center pb-4"
      onViewportEnter={() => {
        clearTimeout(replay.current);
        replay.current = setTimeout(() => setShown(true), 400);
      }}
      viewport={{ once: true, amount: 0.6 }}
      onPointerEnter={(e) => e.pointerType === "mouse" && setHover(true)}
      onPointerLeave={(e) => e.pointerType === "mouse" && setHover(false)}
    >
      {FILES.map(({ name, Icon, x, y, r }, i) => (
        <motion.span
          key={name}
          className="pointer-events-none absolute bottom-6 flex items-center gap-1.5 rounded-[14px] bg-pill px-3 py-2 text-[12.5px] whitespace-nowrap shadow-[0_10px_24px_-8px_rgb(0_0_0/0.8)]"
          initial={false}
          animate={
            shown
              ? { x: x * spread, y: y * spread, rotate: r * spread, opacity: 1, scale: 1 }
              : { x: 0, y: 0, rotate: 0, opacity: 0, scale: 0.6 }
          }
          transition={{ type: "spring", stiffness: 300, damping: 22, delay: shown && !hover ? i * 0.05 : 0 }}
        >
          <Icon size={16} weight="fill" className="text-accent" />
          {name}
        </motion.span>
      ))}
      <motion.button
        type="button"
        onClick={again}
        whileTap={{ scale: 0.95 }}
        aria-label="Export and share, replay"
        className="glass rim relative z-10 flex items-center gap-2 rounded-[var(--radius-pill)] px-5 py-3 text-[15px] font-semibold"
      >
        <ShareNetworkIcon size={18} weight="bold" /> Export &amp; share
      </motion.button>
    </motion.div>
  );
}
