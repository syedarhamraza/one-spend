"use client";

import Image from "next/image";
import { motion } from "motion/react";
import { GithubLogoIcon } from "@phosphor-icons/react";
import { GITHUB_URL } from "@/lib/site";
import { PlayButton } from "./PlayButton";

const WORD = "One Spend";
const settle = [0.2, 0, 0, 1] as const;

const COLUMNS = [
  {
    title: "Product",
    links: [
      { label: "Tour", href: "#tour" },
      { label: "Features", href: "#features" },
      { label: "Make it yours", href: "#yours" },
      { label: "FAQ", href: "#faq" },
    ],
  },
  { title: "Legal", links: [{ label: "Privacy policy", href: "/privacy/" }] },
  { title: "Source", links: [{ label: "GitHub", href: GITHUB_URL, external: true }] },
];

export function Finale() {
  return (
    <footer className="relative isolate overflow-hidden pt-24 pb-36">
      <div className="pointer-events-none absolute bottom-[-30vmax] left-1/2 -z-10 h-[70vmax] w-[70vmax] -translate-x-1/2 rounded-full bg-[radial-gradient(closest-side,rgb(3_129_254/0.3),rgb(3_129_254/0.05)_60%,transparent)]" />

      <div className="mx-auto flex max-w-[1400px] flex-col items-start gap-10 px-4 sm:px-8 md:flex-row md:items-end md:justify-between">
        <div>
          <motion.div
            initial={{ y: 40, rotate: -12, scale: 0.8, opacity: 0 }}
            whileInView={{ y: 0, rotate: 0, scale: 1, opacity: 1 }}
            viewport={{ once: true, amount: 0.6 }}
            transition={{ type: "spring", stiffness: 140, damping: 16 }}
            className="w-fit"
          >
            <Image
              src="/brand/icon.png"
              alt="One Spend app icon"
              width={96}
              height={96}
              className="rounded-[26px] shadow-[0_24px_80px_-10px_rgb(3_129_254/0.6)]"
            />
          </motion.div>
          <h2 className="mt-8 max-w-[14ch] text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.05em]">
            Start with the one you forgot about.
          </h2>
        </div>
        <div className="flex flex-col items-start gap-4 md:items-end">
          <PlayButton />
          <p className="text-[14px] text-ink-2">Free. Android 7.0 and up.</p>
        </div>
      </div>

      <nav aria-label="Footer" className="mx-auto mt-24 grid max-w-[1400px] grid-cols-2 gap-10 px-4 sm:grid-cols-3 sm:px-8 md:grid-cols-12">
        {COLUMNS.map((c) => (
          <div key={c.title} className="md:col-span-2">
            <p className="text-[13.5px] font-bold text-section">{c.title}</p>
            <ul className="mt-3 space-y-2.5">
              {c.links.map((l) => (
                <li key={l.label}>
                  <a
                    href={l.href}
                    {...("external" in l ? { target: "_blank", rel: "noopener" } : {})}
                    className="inline-flex items-center gap-1.5 text-[15px] text-ink-2 transition-colors hover:text-ink"
                  >
                    {"external" in l && <GithubLogoIcon size={16} />}
                    {l.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ))}
        <p className="col-span-2 self-end text-[14px] text-ink-3 sm:col-span-3 md:col-span-6 md:text-right">© 2026 Syed Arham Raza</p>
      </nav>

      {/* The sign-off: the name, set as large as the page allows, rising letter by letter. */}
      {/* The parent watches the viewport: IntersectionObserver ignores children clipped by overflow. */}
      <motion.p
        aria-hidden
        initial="hidden"
        whileInView="show"
        viewport={{ once: true, amount: 0.3 }}
        className="mt-16 overflow-hidden px-2 text-center text-[19.5vw] leading-[0.8] font-bold tracking-[-0.065em] whitespace-nowrap select-none"
      >
        {WORD.split("").map((ch, i) => (
          <motion.span
            key={i}
            className="inline-block bg-gradient-to-b from-white to-white/25 bg-clip-text pb-[0.06em] text-transparent"
            variants={{ hidden: { y: "100%" }, show: { y: 0, transition: { delay: i * 0.05, duration: 0.9, ease: settle } } }}
          >
            {ch === " " ? " " : ch}
          </motion.span>
        ))}
      </motion.p>
    </footer>
  );
}
