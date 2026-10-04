import {
  CloudIcon,
  CodeIcon,
  EnvelopeSimpleIcon,
  FilmSlateIcon,
  MusicNoteIcon,
  PaletteIcon,
  SparkleIcon,
} from "@phosphor-icons/react/dist/ssr";
import type { SampleSub } from "@/lib/site";

const ICONS = {
  film: FilmSlateIcon,
  music: MusicNoteIcon,
  sparkle: SparkleIcon,
  palette: PaletteIcon,
  mail: EnvelopeSimpleIcon,
  code: CodeIcon,
  cloud: CloudIcon,
};

/** The app's glyph-on-colour subscription icon (OneUIBrandIcon): a squircle in the service colour. */
export function SubIcon({ sub, size = 48 }: { sub: Pick<SampleSub, "icon" | "color">; size?: number }) {
  const Icon = ICONS[sub.icon];
  return (
    <span
      className="grid shrink-0 place-items-center"
      style={{ width: size, height: size, borderRadius: size * 0.3, background: sub.color }}
    >
      <Icon size={size * 0.5} weight="fill" color="#fff" />
    </span>
  );
}
