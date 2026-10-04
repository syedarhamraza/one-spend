"use client";

import { useEffect, useRef } from "react";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { SAMPLE_SUBS } from "@/lib/site";
import { SubIcon } from "./SubIcon";

gsap.registerPlugin(ScrollTrigger);

/**
 * One UI's collapsible header at page scale. The giant tab title fills the viewport, then shrinks
 * and docks into the app column's header slot while the list rises underneath. It is the app's
 * own scroll behaviour, used to explain why the top of the screen is for reading.
 */
export function CollapsingHeader() {
  const root = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = root.current;
    if (!el) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    const ctx = gsap.context(() => {
      const stage = el.querySelector<HTMLElement>("[data-stage]")!;
      const title = el.querySelector<HTMLElement>("[data-title]")!;
      const slot = el.querySelector<HTMLElement>("[data-slot]")!;

      // Title is laid out at its big size, top-left of the stage; every position is derived from rects.
      const start = () => ({
        x: (stage.offsetWidth - title.offsetWidth) / 2,
        y: stage.offsetHeight * 0.42 - title.offsetHeight / 2,
        scale: 1,
      });
      const end = () => {
        const s = stage.getBoundingClientRect();
        const r = slot.getBoundingClientRect();
        return { x: r.left - s.left, y: r.top - s.top, scale: r.height / title.offsetHeight };
      };

      if (reduce) {
        gsap.set(title, { ...end(), transformOrigin: "0 0" });
        gsap.set("[data-subtitle]", { autoAlpha: 0 });
        return;
      }

      const tl = gsap.timeline({
        defaults: { ease: "none" },
        scrollTrigger: {
          trigger: el,
          start: "top top",
          end: () => `+=${window.innerHeight * 1.3}`,
          pin: stage,
          scrub: 0.6,
          invalidateOnRefresh: true,
        },
      });

      tl.fromTo(title, { ...start(), transformOrigin: "0 0" }, {
        x: () => end().x,
        y: () => end().y,
        scale: () => end().scale,
        duration: 1,
        ease: "power2.inOut",
      }, 0)
        .fromTo("[data-subtitle]", { opacity: 1, y: 0 }, { opacity: 0, y: -30, duration: 0.3 }, 0)
        .fromTo("[data-card]", { opacity: 0, y: 140 }, { opacity: 1, y: 0, duration: 0.5, ease: "power3.out" }, 0.55)
        .fromTo("[data-row]", { opacity: 0, y: 40 }, { opacity: 1, y: 0, duration: 0.4, stagger: 0.06, ease: "power3.out" }, 0.65)
        .fromTo("[data-copy] > *", { opacity: 0, y: 40 }, { opacity: 1, y: 0, duration: 0.4, stagger: 0.08, ease: "power3.out" }, 0.7);
    }, el);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={root} id="tour" className="relative">
      <div data-stage className="relative h-[100dvh] overflow-hidden">
        <h2
          data-title
          className="absolute top-0 left-0 text-[clamp(4rem,15vw,15rem)] leading-[1] font-bold tracking-[-0.06em] whitespace-nowrap will-change-transform"
        >
          Subscriptions
        </h2>
        <p
          data-subtitle
          className="tabular absolute inset-x-0 top-[calc(42%+clamp(2.6rem,8.6vw,8.6rem))] text-center text-[clamp(1rem,1.6vw,1.4rem)] text-ink-2"
        >
          10 active · $106.18 / month
        </p>

        <div className="mx-auto grid h-full max-w-[1200px] grid-cols-1 content-center gap-7 px-4 pb-24 sm:px-8 md:grid-cols-12 md:items-center md:gap-10 md:pb-0">
          <div data-copy className="order-2 md:order-1 md:col-span-5">
            <h3 className="text-[clamp(1.75rem,3.6vw,3.25rem)] leading-[1.02] font-bold tracking-[-0.045em]">
              Read up top.
              <br />
              <span className="text-ink-2">Reach down low.</span>
            </h3>
            <p className="mt-4 max-w-[38ch] text-[15px] leading-relaxed text-ink-2 md:mt-5 md:text-[17px]">
              Titles start big and step aside as you scroll. Actions float in pills at the bottom of the screen, right
              under your thumb.
            </p>
          </div>

          <div className="order-1 mx-auto w-full max-w-[420px] md:order-2 md:col-span-6 md:col-start-7">
            {/* Header slot the giant title docks into. */}
            <div data-slot className="mb-4 ml-2 h-[30px] w-px" aria-hidden />
            <div data-card className="rounded-[var(--radius-card)] bg-card px-4 py-2">
              {SAMPLE_SUBS.map((s, i) => (
                <div
                  key={s.name}
                  data-row
                  className={`flex items-center gap-4 py-2.5 md:py-3.5 ${i > 3 ? "max-md:hidden" : ""} ${
                    i ? "border-t border-white/[0.06]" : ""
                  }`}
                >
                  <SubIcon sub={s} size={46} />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[16px]">{s.name}</p>
                    <p className={`truncate text-[13.5px] ${s.captionTone === "due" ? "text-red" : "text-ink-2"}`}>
                      {s.caption}
                    </p>
                  </div>
                  <span className="tabular text-[16px] font-bold">{s.price}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
