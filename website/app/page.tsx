import { SmoothScroll } from "@/components/SmoothScroll";
import { Intro } from "@/components/Intro";
import { AmbientGlow } from "@/components/AmbientGlow";
import { SiteHeader } from "@/components/SiteHeader";
import { GlassNav } from "@/components/GlassNav";
import { Hero } from "@/components/Hero";
import { CollapsingHeader } from "@/components/CollapsingHeader";
import { ScreensPan } from "@/components/ScreensPan";
import { HowItWorks } from "@/components/HowItWorks";
import { Features } from "@/components/Features";
import { Customizer } from "@/components/Customizer";
import { MorphDemo } from "@/components/MorphDemo";
import { Manifesto } from "@/components/Manifesto";
import { Faq } from "@/components/Faq";
import { Finale } from "@/components/Finale";

export default function Home() {
  return (
    <>
      <SmoothScroll />
      <Intro />
      <AmbientGlow />
      <SiteHeader />
      <main>
        <Hero />
        <CollapsingHeader />
        <ScreensPan />
        <HowItWorks />
        <Features />
        <Customizer />
        <MorphDemo />
        <Manifesto />
        <Faq />
      </main>
      <Finale />
      <GlassNav />
    </>
  );
}
