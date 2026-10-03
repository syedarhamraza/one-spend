# OneSpend Design Language

OneSpend follows **Samsung One UI 8.5** on a pure-black (OLED) dark theme. This document is the source of truth for UI work. Read it before adding a screen, option or widget, and reuse the widgets listed here rather than Material defaults.

Everything below is backed by real code: tokens live in [`lib/theme/one_ui_theme.dart`](../lib/theme/one_ui_theme.dart) and components in [`lib/widgets/`](../lib/widgets).

---

## 1. Principles

1. **Black canvas, calm surfaces.** Screens sit on true black (`surfacePitch`). Content lives in soft, rounded charcoal cards. There are no hard dividers between cards, no outlines, and no Material elevation.
2. **Reachability.** Titles start large and collapse on scroll, so the top of the screen is for reading. Actions live in floating pills at the bottom, within thumb reach.
3. **Every option is a subpage.** Tapping a setting opens a full **subpage** with a small header, a back button and a floating **Cancel | Save** pill. Never use a Material dialog, date/time picker or snackbar (see §7).
4. **One accent per meaning.** Colour signals meaning (action, success, danger); it isn't decoration. See §2.2.
5. **Tactile.** Every interaction has a haptic (§6).
6. **Respect the user's style settings.** Floating elements get their colour, border and shadow from `OneUITheme` getters, because users can switch **3D floating elements** on in Settings › Appearance (off by default). Cards are always flat and the bottom vignette is always on. Don't hardcode these values.

---

## 2. Tokens (`OneUITheme`)

### 2.1 Surfaces
| Token | Value | Use |
|---|---|---|
| `surfacePitch` | `#000000` | Scaffold background of every screen |
| `surfaceCard` | `#1C1C1E` | Static card colour (prefer the dynamic `cardColor`) |
| `surfaceCardHighlight` | `#262628` | Pressed / nested surfaces |
| `surfacePill` | `#2C2C2E` | Floating capsules, chips |
| `surfacePillActive` | `#3E3E42` | Active tab capsule, selected pill |
| `surfaceButtonLight` | `#B5B5BA` | Light grey pill button on tip cards, with `textOnLight` (`#0E0E10`) labels |

**Dynamic getters.** Always use these for cards and floating UI:
- cards: `cardColor`, `cardBorder`, `cardShadow`
- floating UI: `floatingColor`, `floatingGradient`, `floatingBorder`, `floatingShadow`, `navbarShadow`, `fabShadow`

The floating getters follow `OneUIEffectsController.floating3dEffect` (one setting for the nav bar, buttons and pills). The card getters always return the flat look (`#1C1C1E`, no border, no shadow).

**Floating surfaces: always use `OneUIGlassSurface`** (`one_ui_glass_surface.dart`). Don't hand-roll `DecoratedBox` + `ClipRRect` + `BackdropFilter` + gradient/border. Pick an `elevation` (`floating` for pills, circular buttons, search and menus; `navbar` for bottom bars and the Cancel | Save pill; `modal` for sheets and modals). Use `.circle(size:)` for round buttons and `progress` for backings that grow in as a header collapses.
- **Flat:** translucent fill + blur, no outline or gradient, a single soft ambient shadow (none for modals).
- **3D** (One UI 8.5): a top-lit gradient body, a gradient *rim light* (bright along the top edge, fading down the sides; `floatingRimGradient`, drawn by `OneUIRimPainter`), and a soft drop shadow.
- **Selected capsule** (nav bar): `activePillColor` / `activePillGradient` (radial sheen in 3D) + `activePillRimGradient`. In the nav bar it is one sliding capsule, `pillOverhang` wider than its slot on each side; the gap between tabs never changes.

### 2.2 Accents
| Token | Value | Meaning |
|---|---|---|
| `accentBlue` | `#5390F5` | Primary action, selection, links, radios, switches, wheel accents |
| `accentGreen` | `#00C05A` | Success, "left in budget", active status |
| `accentRed` | `#F07167` | Destructive actions, errors, blocked / expired states |
| `accentTeal` | `#48B5A0` | Reminders, scheduling, secondary info badges |
| `accentAmber` | `#F4A261` | Notifications, warnings that aren't errors |
| `accentPurple` | `#7E57C2` | Appearance / customisation, help |
| `accentOrange` | `#FB8C00` | Reset / restore actions |

**Category colours.** A custom category picks from `OneUITheme.categorySwatches`: 12 colours that stay distinct on black, in the donut and as chip tints. Never offer white, grey or charcoal there.

**Insight tone.** Tip cards reuse the accents by meaning: `accentRed` = bad news (over budget, spending up), `accentAmber` = heads-up (renewal soon, heavy month), `accentGreen` = good news (under budget, savings), `accentBlue` = neutral information.

**Hero glow.** The glass hero cards glow in a colour that reflects state, never decoration: the Budget card follows its track (blue → orange → red as spending nears the limit), the Upcoming hero takes the biggest charge's brand colour (crimson when anything is overdue), and the Analytics hero takes the largest (or selected) category's colour. Pass raw brand/category colours through `OneUITheme.glowTint` so dark or grey ones still read on black; `glowDefault` (`#0381FE`) is the fallback.

Need a new colour? Add a token to `OneUITheme` first. Don't inline `Color(0x…)` in screens.

### 2.3 Text
| Token | Value | Use |
|---|---|---|
| `textPrimary` | `#FFFFFF` | Titles, values, selected wheel items |
| `textSecondary` | `#9E9EA4` | Subtitles, captions, secondary values |
| `textTertiary` | `#6A6A70` | Disabled text, hints |
| Section header | `#D4D4D8` | `OneUISection` titles only |

### 2.4 Radii
| Token | Value | Use |
|---|---|---|
| `radiusPill` / `pillBorderRadius` | 34 | Floating pills, nav bar, search pill |
| `fieldBorderRadius` | pill | Every single-line text field box (name, amount, URL, card fields). Multi-line fields (notes) keep `cardBorderRadius` |
| `radiusCard` / `cardBorderRadius` | 26 | Cards and group cards |
| `radiusInner` / `innerBorderRadius` | 20 | Cards nested inside cards (e.g. the budget card's inner panel) |
| `radiusBadge` | 16 | Badges, chips |
| Icon squircle | 12–14 | Tinted icon tiles in hero / summary banners |

### 2.5 Typography
The font is Roboto (set in `OneUITheme.darkTheme`). Use tight letter spacing on large text.

| Role | Size / weight | Where |
|---|---|---|
| Big header title | 34 / bold | `OneUICollapsibleHeaderDelegate` with `hasBigHeader: true` (tabs) |
| Big header subtitle | 14.5 | Under the big title |
| Small header title | 22 | Collapsed header, and subpages (`hasBigHeader: false`) |
| Hero number | 32 / bold | Budget card amount |
| Section header | 13.5 / w700, `#D4D4D8`, letterSpacing −0.2 | `OneUISection` |
| List item title | 16 | `OneUIGroupItem` |
| List item subtitle | 13.5, `textSecondary` | `OneUIGroupItem` |
| Pill button label | 16 | `OneUIFloatingCancelSavePill` |
| Toast | 14.5 | `OneUIToast` |
| Wheel digits | 72 / w600, tabular figures; AM/PM 44 / w700 | `OneUITimeWheel` |
| Date wheel | 52 / w600, tabular figures | `OneUIDateWheel` |

---

## 3. Layout

- **Side gutters:** 16 px.
- **Subpage content padding:** `EdgeInsets.fromLTRB(16, 12, 16, 140)`. The **140 px bottom** keeps the last row clear of the floating pill and the vignette.
- **Vertical rhythm:** 14 px between group cards / sections; 12–20 px between a hero element and the list below it.
- **Headers:** a pinned `SliverPersistentHeader` with `OneUICollapsibleHeaderDelegate`.
  - Tabs: `hasBigHeader: true`, with optional `subtitle` and `actions` (`OneUIHeaderAction`).
  - Subpages: `hasBigHeader: false, showBackButton: true`.
- **Scrims:**
  - `OneUIStatusBarScrim` at the top of tab screens.
  - `OneUIBottomVignette` at the bottom of any screen with floating elements. Pass `hasFloatingElements: false` when there's no pill.
- **Scrolling:** `CustomScrollView` with `BouncingScrollPhysics`.

---

## 4. Components

| Component | File | Use it for |
|---|---|---|
| `OneUICollapsibleHeaderDelegate`, `OneUIHeaderAction` | `one_ui_collapsible_header.dart` | Every screen's header; circular header actions (add, search, more) |
| `OneUISection` | `one_ui_card.dart` | A titled group: small grey title above a card |
| `OneUIGroupCard` + `OneUIGroupItem` | `one_ui_group_card.dart` | **The default list.** Rows with optional `leading` badge, `title`, `subtitle` (with `subtitleColor`), and `trailing` (chevron / radio / switch / value). `headerTitle` adds a section title |
| `OneUICard` | `one_ui_card.dart` | A single standalone tappable row-card |
| `OneUIRadio` | `one_ui_radio.dart` | Single choice in a list (trailing) |
| `OneUISwitch` | `one_ui_switch.dart` | On/off settings (trailing). The row's `onTap` should toggle too |
| `OneUIFloatingCancelSavePill` | `one_ui_cancel_save_pill.dart` | The Cancel \| Save capsule at the bottom of every option subpage |
| `OneUITimeWheel` | `one_ui_time_wheel.dart` | Time-of-day selection (hour : minute AM/PM wheels). Use it via `TimePickerScreen.open` |
| `OneUIDateWheel` | `one_ui_date_wheel.dart` | Date selection (month / day / year wheels, clamped to a range). Use it via `DatePickerScreen.open` |
| `OneUIWheelColumn` | `one_ui_wheel_column.dart` | The single flat scroll-wheel column both pickers are built from. Reuse it for any new wheel picker |
| `OneUIUpcomingHeroCard` | `one_ui_upcoming_hero_card.dart` | Upcoming tab hero: the budget card's glass + glow recipe, hero amount, 12dp track split by payment method, Device Care key-value rows |
| `OneUIAnalyticsHeroCard` | `one_ui_analytics_hero_card.dart` | Analytics tab hero (the page's only glass card): same glass + glow recipe, yearly amount, 12dp track split by category colour, key-value rows (per month, budget, paused, and the Pro year-end projection: "On track for 2026", or "Oct – Dec 2026" when tracking began mid-year; free users see it locked with a Pro chip). A row can take a `trailing` widget and `onTap` |
| `CategoryEditorScreen` | `screens/category_editor_screen.dart` | Create or edit a custom category (Pro): live preview, pill name field, inline icon grid (`supportedSubscriptionIcons`) and colour swatches (`categorySwatches`), Cancel \| Save. Editing adds Delete, which first asks where to move the category's subscriptions |
| `OneUIKeyValueRow` | `one_ui_key_value_row.dart` | The key-value rows inside both hero cards' panels: grey label left, bold value over a grey caption right. When they don't fit side by side (big amounts, long currency codes or names, large text) the value moves under the label rather than being cut off. Never truncate an amount |
| `OneUISpendingTrendsCard` + `OneUILineChart` | `one_ui_spending_chart.dart` | Spending trend (titled by its `OneUISection`): month amount beside the 6M · 1Y · 2Y pills, then month · chip · change; 6M · 1Y · 2Y of past months (solid) and forecast (dashed, from `ChargeSchedule`), budget guide, scrubbing with a tooltip, and the charges behind the highlighted month |
| `OneUIAmbientGlow` | `one_ui_ambient_glow.dart` | The radial glow behind glass hero cards (first child of the card's `Stack`); cross-fades when its `color` changes |
| `OneUISliverScrollAnchor` + `OneUISliverScrollAnchorSpacer` | `one_ui_sliver_scroll_anchor.dart` | Keeps a tapped card still while content above it resizes (e.g. a filter). Put the anchor right before that card's sliver, the spacer at the end instead of the 140 px `SizedBox`, and call `controller.hold()` before the change |
| `OneUIInsightCard` + `InsightCards` | `one_ui_insight_card.dart`, `domain/services/insight_cards.dart` | Digital Wellbeing style tip: tone-coloured centred headline, message, light grey pill action, glow in the tone colour. One at a time; swipe or ✕ to dismiss; the ⋮ menu's "Show dismissed tips" brings them back. Dismissed keys persist in `SubscriptionController.dismissedInsights` |
| `OneUICategoryBreakdownCard` | `one_ui_category_breakdown_card.dart` | Donut with the monthly total (or the selected category's share) in its centre, legend of icon · name · share · amount; tapping a row selects that category. Titled by its `OneUISection` |
| `OneUIEmptyCard` | `one_ui_card.dart` | Every in-page empty state: 40dp grey icon, title, hint, optional tinted pill action |
| `OneUICategoryRing` | `one_ui_category_ring.dart` | Donut split with a centre label; `highlightedIndex` dims the other segments. Colours come from `SubscriptionCategory.color` |
| `OneUISelectionCountPill`, `OneUISelectionCancelPill` | `one_ui_selection_header_pills.dart` | Selection-mode header capsules (select-all + count, Cancel). Pass them as `selectionLeading` / `selectionTrailing` |
| `OneUISegmentedPills` | `one_ui_segmented_pills.dart` | A few mutually exclusive ranges/modes in one capsule with a sliding thumb (e.g. Upcoming's 7 days · 30 days · 3 months · 12 months). Pass `dense: true` for a compact 34dp version inside a card |
| `OneUIMonthCalendar` + `CalendarDayMarker` | `one_ui_month_calendar.dart` | Samsung Calendar style swipeable month grid: today ring, filled selected day, up to 3 colour dots + "+N", and a heat tint per day |
| `OneUIFloatingModal` | `one_ui_floating_modal.dart` | Floating bottom sheets: `show`, `showTextInputDialog`, `showConfirmationDialog` (destructive confirms) |
| `OneUIToast` | `one_ui_toast.dart` | Brief, text-only feedback ("Netflix added"). On Android it's the real system toast (the One UI toast on Samsung); an in-app capsule elsewhere and in tests. After copying to the clipboard use `OneUIToast.copied`, which Android 13+ skips because the system confirms copies itself. Replaces snackbars. Never put actions (Undo) in a toast: offer them inline (§5.3) |
| `OneUIMorphSwitcher` | `one_ui_morph_switcher.dart` | Swaps content inside a morphing pill/bar with a fade-through (old content clears in ~110 ms, the shape resizes over 340 ms on an emphasized curve, new content settles in). Sized by the incoming child only; safe to toggle mid-morph. Use it for every in-place mode change |
| `OneUIGlassSurface` | `one_ui_glass_surface.dart` | The only way to draw floating chrome (see §2.1): flat vs 3D glass, rim light, shadow per elevation |
| `OneUIFloatingNavBar` | `one_ui_floating_nav_bar.dart` | The 4-tab bottom capsule (owned by `HomeScreen`) with a sliding active capsule |
| `OneUIFloatingSearchPill` | `one_ui_floating_search_pill.dart` | In-screen search |
| `OneUIFloatingSearchField` | `one_ui_floating_search_field.dart` | The glass search capsule that floats above the keyboard (Subscriptions, Settings); hide the nav bar with a `HomeChrome` flag while it's open. `hintText` is required and says what is searched ("Search subscriptions", "Search currencies"), never a generic prompt |
| `OneUISubpage` | `one_ui_subpage.dart` | Scaffold for every subpage: small header + back, padded content, vignette, optional bottom pill. `builder` + `listenable` for live values. Same file: `OneUIIconBadge` (36dp list badge), `OneUISoonChip` and `OneUIProChip` (amber; for a locked Pro row use `ProGate.chip()`, which hides it once Pro is unlocked) |
| `OneUISelectionPills`, `OneUISelectionActionBar`, `OneUIFloatingActionBar` | `one_ui_selection_*.dart`, `one_ui_floating_action_bar.dart` | Multi-select mode: top capsules + bottom action bar. Pass `docked: true` to get just the action row for the nav bar to host (§5.3) |
| `OneUISortBottomSheet`, `OneUIFilterBottomSheet`, `OneUIFloatingMenu` | respective files | Sort / filter sheets and overflow menus |
| `OneUIScrollToTopButton` | `one_ui_scroll_to_top_button.dart` | Long lists |
| `ExportShareScreen` | `features/reports/presentation/export_share_screen.dart` | The one place to export: PDF report, CSV (subscriptions + payments), text summary, backup file. Open it with `ExportShareScreen.open(context, category:)` rather than adding new export menu items. PDFs are built by `PdfReportBuilder` (light paper style, Noto Sans) from `SpendingReportData`, which uses the app's own stats so the numbers always match |
| `OneUILogoFramer` | `one_ui_logo_framer.dart` | Image editor for a custom logo: the real icon, large, with pinch-to-zoom, drag, a zoom slider and Reset. Produces a `LogoTransform` (zoom + offset as fractions of the icon size) |
| `FirstRunEmptyState` | `features/subscriptions/presentation/widgets/first_run_empty_state.dart` | The Subscriptions tab before anything is added: logo hero (animates once), headline, Add subscription, popular one-tap starts, Restore from backup |
| `OneUIBrandIcon`, `OneUIPaymentBrandIcon` | respective files | Subscription icons (user's own image, a chosen glyph, or initials in the subscription's colour) and payment badges (network colour + generic card or wallet glyph, name as text). **Never ship or draw third-party logos or logo-like glyphs** (no brand SVGs, no `Icons.apple`/`Icons.paypal`, no private-use logo characters): they're trademarks and a Play Store policy risk. Glyphs use `OneUIBrandCatalog.foregroundOn(background)` so they stay legible on light colours. A custom logo honours its `LogoTransform` |

### Data pages (Analytics)
- **One glass hero per tab.** Everything else is a flat card under an `OneUISection` title; don't put titles inside cards.
- **Show each figure once.** A total that's in the hero isn't repeated as another card's headline.
- **List rows** (`OneUIGroupCard`): leading icon, title, a one-line subtitle, and a trailing bold amount (15 / w700) over a grey caption (share, saving). A figure for the whole section goes on the right of its title, in grey.
- **Inset panels** inside a card use `surfaceInset` with `innerBorderRadius`.
- Colour only where it means something (§2.2): category colours for categories, green/red for saving/over budget. Neutral breakdowns (billing cycles) use one accent.

### Leading icon badges
- **In list rows:** a 36 px **solid circle** in an accent colour, with a white 20 px icon (see `_buildIconBadge` in `settings_screen.dart`).
- **In hero / summary banners:** a 36–44 px **tinted squircle**: accent at 15 % alpha, radius 12–14, and an accent-coloured icon.

---

## 5. Recipes

### 5.1 Add an option subpage (the standard pattern)
Use [`billing_cycle_picker_screen.dart`](../lib/screens/billing_cycle_picker_screen.dart) or [`time_picker_screen.dart`](../lib/screens/time_picker_screen.dart) as the template.

1. **Screen:** `Scaffold(backgroundColor: OneUITheme.surfacePitch)` → `Stack`:
   - a `CustomScrollView` with a pinned `OneUICollapsibleHeaderDelegate(title: …, hasBigHeader: false, showBackButton: true, onBack: () => Navigator.pop(context))`
   - a padded `SliverToBoxAdapter` (§3) with `OneUISection` / `OneUIGroupCard` content
   - a `Positioned` `OneUIBottomVignette`
   - a `Positioned` + `SafeArea` + `Padding(bottom: 8)` + `Center` → `OneUIFloatingCancelSavePill(onCancel: () => Navigator.pop(context), onSave: _save)`
2. **Save:** `HapticFeedback.mediumImpact(); Navigator.pop(context, value);`. Cancel and back pop with no value, so the caller gets `null`.
3. **Route:** add a path to `AppRoutes`, plus a typedef record for its arguments if needed, in [`app_router.dart`](../lib/core/router/app_router.dart), and a `GoRoute` in `buildPageRoutes()` that reads `state.extra`.
4. **Entry point:** add `static Future<T?> open(BuildContext context, {…})` on the screen. It calls `HapticFeedback.lightImpact()`, then `context.push<T>(AppRoutes.x, extra: …)`. Callers use only `open()`.
5. **Test:** host the caller with `routedTestApp(...)` from `test/helpers/test_app.dart`.

### 5.2 Add a setting
Settings follows Samsung Settings: the **main page is titles only**. Each row is a solid circular badge and a short title: no subtitle, no switch, no chevron, and it never opens a dialog. Every option lives on the **subpage** that row opens (`lib/screens/settings/`).

- **New option in an existing area:** add a row to that subpage (built on `OneUISubpage`). Subpage rows show the **current value** as their subtitle, and a `OneUISwitch` is fine here. Also add it to that destination's `options` in `settings_catalog.dart` so search finds it (results show the path, e.g. "Settings › Notifications").
- **New area:** add a `SettingsDestination` to a group in `SettingsCatalog.groups` (icon, colour, `open`, keywords, options), plus a subpage with a route and an `open()` helper (§5.1).
- **Not built yet:** add a `PlannedFeature` and point the row at `ComingSoonScreen.open`; show `OneUISoonChip` (or `OneUIProChip`) as the trailing widget. Wrap the row in `if (FeatureFlags.showPlannedFeatures)` and mark catalog options `placeholder: true`: placeholders appear in **debug builds only**, so release users never see features that don't work yet.
- **Pro-only option:** keep the row visible, give it `trailing: ProGate.chip()` and `onTap: () => ProGate.run(context, …)`, so free users land on the OneSpend Pro page. Add `'pro'` to its catalog keywords.
- **Debug-only tools** go in Developer options, which only exists in debug builds.

### 5.3 Quick actions, confirmation, and long-press
- **Money-moving actions** (mark paid, skip a cycle) use a **confirmation**: `OneUIFloatingModal.showConfirmationDialog`. The title is a question ("Mark Netflix as paid?"), the message says what will happen ("Logs a $15.49 payment and moves the next renewal to Nov 5"), and `confirmTextColor` uses the action's accent. Follow it with a plain `OneUIToast`.
- **Undo is inline, never in a toast** (toasts are text-only system toasts). Morph the control that did the action into Undo for a few seconds, or show a small inline pill where the change happened:
  - **Renew** on the detail screen: the Renew button turns into a blue **Undo** for 8 s (`SubscriptionController.undoRenew` restores only the renewal date and payment history).
  - Where a menu already restores things (Analytics' "Show dismissed tips"), no inline Undo is needed.
- **Morph, don't swap.** When chrome changes mode, the same surface reshapes: the header's actions pill becomes the Cancel pill, inside the tab shell the nav bar becomes the selection action bar, and a subpage's Cancel | Save pill becomes its selection actions. Put the changing content in a `OneUIMorphSwitcher` inside one `OneUIGlassSurface` (pass `docked: true` to the action bars / Cancel | Save pill to get just their content). Animations are zero when the system's "Remove animations" is on.
- **Selection mode never moves the page.** Content that doesn't take part in selection (tips, "Other options", per-row edit buttons) stays in the layout, faded and untappable, rather than being removed.
- **Long-press always enters selection mode**, never a sheet or menu. The recipe (see `upcoming_screen.dart` and `subscriptions_screen.dart`):
  1. Track `_isSelectionMode` and `_selectedIds`. Tapping toggles selection, and rows show a selection circle instead of their actions.
  2. Pass `isSelectionMode`, `selectionLeading: OneUISelectionCountPill(…)` and `onSelectionCancel: _exitSelectionMode` to the header (the actions pill morphs into Cancel).
  3. Inside the tab shell (`HomeShellScope.isHosted(context)`), dock the batch actions into the nav bar with `HomeChrome.dockBottomBar(tab, OneUIFloatingActionBar(docked: true, …), width: …)` from `build` (null to withdraw, and in `dispose`). Outside the shell, show your own `OneUIFloatingActionBar`.
  4. Wrap the scaffold in `PopScope(canPop: !_isSelectionMode)`, so system back exits selection first. Inside the tab shell that `PopScope` never sees back presses: also register a `HomeChrome.backHandlers[tab]` callback and keep the tab's `HomeChrome` selection flag in sync.

### 5.4 Confirm a destructive action
Use `OneUIFloatingModal.showConfirmationDialog(title, message, confirmLabel: 'Delete', …)`, then `OneUIToast.show(context, '… deleted')`.

**Bulk data changes are always undoable.** Anything that replaces or wipes the user's data (restoring a backup with "Replace everything", "Clear all subscriptions") goes through `BackupService`, which saves a restore point first. Its `undoableAction` then drives an inline **Undo** row at the top of Backup & data (`BackupService.undoLast`) until the user leaves the screen. There is exactly one backup mechanism: the in-app backup file (Android Auto Backup is disabled in the manifest).

---

## 6. Motion & haptics
| Interaction | Haptic |
|---|---|
| Opening a subpage / tapping a row | `HapticFeedback.lightImpact()` |
| Picking an option, toggling, each wheel tick | `HapticFeedback.selectionClick()` |
| Saving / confirming | `HapticFeedback.mediumImpact()` |
| Long-press into selection mode | `HapticFeedback.mediumImpact()` |

- **Durations:** 200–380 ms.
- **Curves:** `Curves.easeInOutCubic` for show/hide (e.g. the nav bar sliding away), and `Curves.easeOutCubic` for settling (e.g. wheels animating to a quick pick).

---

## 7. Do / Don't

**Do**
- Reuse the components above; extend them before creating look-alikes.
- Use `OneUITheme` tokens and dynamic getters.
- Put floating actions at the bottom with the vignette behind them.
- Show the current value in a row's subtitle.
- Give text in `Row`s a `Flexible` + `maxLines`/`ellipsis`, and check layouts at a **360 dp** width. Card names and subscription names can be long.

**Don't**
- ❌ `showDialog` / `AlertDialog` / `SimpleDialog`: use `OneUIFloatingModal`.
- ❌ `showTimePicker`: use `TimePickerScreen.open` (`OneUITimeWheel`).
- ❌ `showDatePicker`: use `DatePickerScreen.open` (`OneUIDateWheel`).
- ❌ `SnackBar` / `ScaffoldMessenger`: use `OneUIToast`.
- ❌ Material `AppBar`, `ListTile`, `Switch`, `Radio`, `Divider` between cards, or `Card` elevation.
- ❌ Raw `Colors.*` / `Color(0x…)` for surfaces or accents in screens.
- ❌ Light theme assumptions. The app is dark-only.

### Known deviations (to migrate)
- None currently. Add any Material leftovers you find here.
