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
6. **Respect the user's style settings.** Cards and floating elements get their colour, border and shadow from `OneUITheme` getters, because users can switch 3D effects on and off in Settings. Don't hardcode them.

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

**Dynamic getters.** Always use these for cards and floating UI:
- cards: `cardColor`, `cardBorder`, `cardShadow`
- floating UI: `floatingColor`, `floatingGradient`, `floatingBorder`, `floatingShadow`, `navbarShadow`, `fabShadow`

They follow `OneUIEffectsController`, which holds the user's 3D-effects settings.

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
| `OneUISelectionCountPill`, `OneUISelectionCancelPill` | `one_ui_selection_header_pills.dart` | Selection-mode header capsules (select-all + count, Cancel). Pass them as `selectionLeading` / `selectionTrailing` |
| `OneUISegmentedPills` | `one_ui_segmented_pills.dart` | A few mutually exclusive ranges/modes in one capsule with a sliding thumb (e.g. Upcoming's 7 days · 30 days · 3 months · 12 months) |
| `OneUIMonthCalendar` + `CalendarDayMarker` | `one_ui_month_calendar.dart` | Samsung Calendar style swipeable month grid: today ring, filled selected day, up to 3 colour dots + "+N", and a heat tint per day |
| `OneUIFloatingModal` | `one_ui_floating_modal.dart` | Floating bottom sheets: `show`, `showTextInputDialog`, `showConfirmationDialog` (destructive confirms) |
| `OneUIToast` | `one_ui_toast.dart` | Brief feedback ("Netflix added"). Replaces snackbars. Pass `actionLabel: 'Undo', onAction: …` for reversible actions; it then stays up for 4 s |
| `OneUIFloatingNavBar` | `one_ui_floating_nav_bar.dart` | The 4-tab bottom capsule (owned by `HomeScreen`) |
| `OneUIFloatingSearchPill` | `one_ui_floating_search_pill.dart` | In-screen search |
| `OneUISelectionPills`, `OneUISelectionActionBar`, `OneUIFloatingActionBar` | `one_ui_selection_*.dart`, `one_ui_floating_action_bar.dart` | Multi-select mode: top capsules + bottom action bar |
| `OneUISortBottomSheet`, `OneUIFilterBottomSheet`, `OneUIFloatingMenu` | respective files | Sort / filter sheets and overflow menus |
| `OneUIScrollToTopButton` | `one_ui_scroll_to_top_button.dart` | Long lists |
| `OneUIBrandIcon`, `OneUIPaymentBrandIcon` | respective files | Service logos and card-network logos |

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

### 5.2 Add a settings row
Add an `OneUIGroupItem` to the right list in `settings_screen.dart`, with:
- a solid circular badge
- a title
- a subtitle showing the **current value**
- a trailing chevron, or a `OneUISwitch` for booleans
- an `onTap` that opens a subpage via its `open()`

Rows are filtered by the Settings search, so keep titles descriptive.

### 5.3 Quick actions, confirmation, and long-press
- **Money-moving actions** (mark paid, skip a cycle) use a **confirmation**: `OneUIFloatingModal.showConfirmationDialog`. The title is a question ("Mark Netflix as paid?"), the message says what will happen ("Logs a $15.49 payment and moves the next renewal to Nov 5"), and `confirmTextColor` uses the action's accent. Follow it with a plain `OneUIToast`.
- **Undo** (`OneUIToast.show(…, actionLabel: 'Undo', onAction: …)`) suits cheap, non-financial changes, where a snapshot restores the previous state.
- **Long-press always enters selection mode**, never a sheet or menu. The recipe (see `upcoming_screen.dart` and `subscriptions_screen.dart`):
  1. Track `_isSelectionMode` and `_selectedIds`. Tapping toggles selection, and rows show a selection circle instead of their actions.
  2. Pass `isSelectionMode`, `selectionLeading: OneUISelectionCountPill(…)` and `selectionTrailing: OneUISelectionCancelPill(…)` to the header.
  3. Slide the tab bar away via the tab's `HomeChrome` flag, and slide in a `OneUIFloatingActionBar` with the batch actions.
  4. Wrap the scaffold in `PopScope(canPop: !_isSelectionMode)`, so system back exits selection first.

### 5.4 Confirm a destructive action
Use `OneUIFloatingModal.showConfirmationDialog(title, message, confirmLabel: 'Delete', …)`, then `OneUIToast.show(context, '… deleted')`.

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
