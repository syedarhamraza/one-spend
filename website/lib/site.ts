// Shared copy and sample data. The sample subscriptions are the same fictional services
// the app's demo catalog and Play Store captures use, so the page and the screenshots agree.

export const PLAY_URL = "https://play.google.com/store/apps/details?id=com.syedarhamraza.onespend";
export const GITHUB_URL = "https://github.com/syedarhamraza/one-spend";
export const PLAY_LABEL = "Get it on Google Play";

export const SECTIONS = [
  { id: "overview", label: "Overview" },
  { id: "tour", label: "Tour" },
  { id: "features", label: "Features" },
  { id: "yours", label: "Yours" },
  { id: "faq", label: "FAQ" },
] as const;

// Page-wide ambient glow per scene. Colour carries meaning, as on the app's hero cards:
// blue for overview and data, teal for reminders, green for personalisation, purple for interaction.
export const GLOW_SECTIONS = [
  { id: "overview", color: "#0381fe" },
  { id: "tour", color: "#0381fe" },
  { id: "how", color: "#48b5a0" },
  { id: "features", color: "#0381fe" },
  { id: "yours", color: "#00c05a" },
  { id: "morph", color: "#7e57c2" },
  { id: "privacy", color: "#0381fe" },
  { id: "faq", color: "#0381fe" },
] as const;

export type PaymentCard = { name: string; last4: string; color: string; pays: string[]; expiring?: string };

export const PAYMENT_CARDS: PaymentCard[] = [
  { name: "Nova Bank", last4: "4821", color: "#283593", pays: ["Streamly", "Lumen AI", "Tunebox"] },
  { name: "Orbit", last4: "1937", color: "#c62828", pays: ["Mailbox Pro", "Pixelcraft Studio"], expiring: "11/26" },
  { name: "Harbor Credit", last4: "6604", color: "#00695c", pays: ["Shellforge"] },
];

// Same wording the app's NotificationPlanner writes.
export const NOTIFICATIONS = [
  { title: "Streamly renews tomorrow", body: "$15.99 will be charged on Oct 5.", channel: "Renewals" },
  { title: "Card expiring soon", body: "Orbit (•••• 1937) expires 11/26. Update the subscriptions that use it.", channel: "Cards" },
  {
    title: "Over budget on Nov 19",
    body: "Mailbox Pro ($39.00) takes November spending to $152, over your $150 budget.",
    channel: "Budget",
  },
];

export const INSIGHTS = [
  { tone: "#00c05a", title: "Pausing saves $12 a month", body: "1 paused subscription, $144 a year." },
  { tone: "#f4a261", title: "Busy week ahead", body: "3 charges between Nov 17 and Nov 23, $61.99 in total." },
  { tone: "#5390f5", title: "Lumen AI is your top expense", body: "$20 a month, 19% of everything you pay." },
];

export const FAQ = [
  {
    q: "Is One Spend free?",
    a: "Yes. Every feature is free. There are no ads, no subscription and nothing locked behind a paywall.",
  },
  {
    q: "Do I need an account or an internet connection?",
    a: "No. There is no sign-in, and everything works offline. The app goes online only to fetch exchange rates, check Google Play for updates, and send anonymous crash reports and usage stats.",
  },
  {
    q: "Does it connect to my bank?",
    a: "No. You add subscriptions yourself, from a one-tap list of popular services or from scratch. Cards are stored as a nickname and the last four digits only.",
  },
  {
    q: "Do I need a Samsung phone?",
    a: "No. It is styled after One UI, but it runs on any phone with Android 7.0 or newer.",
  },
  {
    q: "How do I move to a new phone?",
    a: "Save a backup file from Settings › Backup & data, then restore it on the new phone. You choose whether to add missing items or replace everything.",
  },
  {
    q: "Is there an iPhone version?",
    a: "Not yet. One Spend is Android only for now.",
  },
];

export type SampleSub = {
  name: string;
  price: string;
  caption: string;
  captionTone?: "due" | "muted";
  color: string;
  icon: "film" | "music" | "sparkle" | "palette" | "mail" | "code" | "cloud";
};

export const SAMPLE_SUBS: SampleSub[] = [
  { name: "Streamly", price: "$15.99", caption: "Due in 2 days", captionTone: "due", color: "#e5484d", icon: "film" },
  { name: "Tunebox", price: "$11.99", caption: "Due in 3 days", captionTone: "due", color: "#1fbf75", icon: "music" },
  { name: "Lumen AI", price: "$20.00", caption: "Monthly, renews Oct 9", color: "#8b5cf6", icon: "sparkle" },
  { name: "Pixelcraft Studio", price: "$12.99", caption: "Monthly, renews Oct 14", color: "#f07a1a", icon: "palette" },
  { name: "Mailbox Pro", price: "$39.00", caption: "Yearly, renews Nov 19", color: "#1aa7ec", icon: "mail" },
  { name: "Shellforge", price: "$10.00", caption: "Monthly, renews Oct 21", color: "#e6b422", icon: "code" },
];

// OneUITheme.categorySwatches, in the order the analytics donut shows them.
export const CATEGORY_SLICES = [
  { label: "Productivity & AI", share: 22, color: "#5390f5" },
  { label: "Entertainment", share: 15, color: "#e5484d" },
  { label: "Design & Media", share: 12, color: "#ef6c9a" },
  { label: "Music & Audio", share: 11, color: "#00c05a" },
  { label: "Developer Tools", share: 9, color: "#ffd166" },
  { label: "Cloud", share: 9, color: "#34aadc" },
  { label: "News", share: 8, color: "#7e57c2" },
  { label: "Fitness", share: 7, color: "#f4a261" },
  { label: "Other", share: 7, color: "#48b5a0" },
];

// Every currency the app supports (lib/features/currency/domain/currency.dart).
export const CURRENCIES = ["USD", "EUR", "GBP", "PKR", "INR", "AED", "SAR", "QAR", "KWD", "BHD", "OMR", "CAD", "AUD", "NZD", "JPY", "CNY", "KRW", "HKD", "TWD", "SGD", "MYR", "THB", "IDR", "PHP", "VND", "BDT", "LKR", "NPR", "CHF", "SEK", "NOK", "DKK", "PLN", "CZK", "HUF", "TRY", "RUB", "UAH", "EGP", "NGN", "KES", "ZAR", "BRL", "MXN", "ARS", "CLP", "COP"];
