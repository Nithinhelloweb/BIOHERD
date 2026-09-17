# BIOHERD — SIH26128 Design System & UI Guidelines
## Livestock Disease Management Platform

This file governs all visual design decisions across the Flutter app (mobile + web) and is the single source of truth for UI/UX. Every screen, component, and interaction must conform to these specifications.

---

## Design Philosophy

**Accessible first.** The primary users are rural farmers in Maharashtra — many using budget Android phones on 2G/3G, with limited English proficiency. Every design decision is tested against this baseline user, not an urban tech-savvy user.

**Information clarity over visual flair.** Livestock health is a high-stakes domain. Disease alerts, medication dosages, and outbreak warnings must never be buried in decoration. Hierarchy and legibility beat aesthetics.

**Trust through consistency.** Government-adjacent products live or die by perceived credibility. A consistent, clean, and predictable interface signals reliability. No surprise interactions.

**Performance is design.** Skeleton loaders, optimistic UI, and offline indicators are first-class design elements — not afterthoughts.

---

## Brand Identity

### Name
**BIOHERD** (बायोहर्ड / पशुसेवा) — Bio-surveillance & Herd Health Management.
Tagline: *"Healthy Animals. Prosperous Farmers."* / *"निरोगी जनावरे. समृद्ध शेतकरी."*

### Logo
- Wordmark: "BIOHERD" in Gilroy Semi-Bold
- Icon: a stylised cow silhouette formed from a continuous line, enclosed in a soft rounded square
- Icon is used as app icon, favicon, and loading splash
- Minimum clear space: equal to the height of the "B" glyph on all sides

### Brand Voice
- Farmer-facing: warm, simple, reassuring. No medical jargon. Plain language.
- Vet-facing: clinical, efficient, precise.
- Government-facing: formal, data-driven, authoritative.

---

## Color System

All colors are defined as Flutter `Color` constants in `lib/core/theme/app_colors.dart`.

### Primary Palette

| Token | Hex | Flutter const | Usage |
|---|---|---|---|
| `primary-600` | `#1B6B3A` | `Color(0xFF1B6B3A)` | Primary buttons, key icons, active nav |
| `primary-500` | `#228B47` | `Color(0xFF228B47)` | Hover/press states on primary |
| `primary-400` | `#2DAE5A` | `Color(0xFF2DAE5A)` | Accent highlights, progress bars |
| `primary-100` | `#D4EDDA` | `Color(0xFFD4EDDA)` | Light fills, success banners |
| `primary-50` | `#EAF7EE` | `Color(0xFFEAF7EE)` | Page section backgrounds |

Forest green is chosen deliberately — it signals agriculture, health, and trust. It is also high-contrast against white (WCAG AA on all primary stops).

### Semantic Colors

| Token | Hex | Usage |
|---|---|---|
| `danger-600` | `#C0392B` | Critical alerts, destructive actions, high severity |
| `danger-100` | `#FADBD8` | Danger background fills |
| `warning-600` | `#D35400` | Medium severity, caution states |
| `warning-100` | `#FAE5D3` | Warning background fills |
| `info-600` | `#1A5276` | Informational, IoT data |
| `info-100` | `#D6EAF8` | Info background fills |
| `success-600` | `#1E8449` | Confirmation, resolved cases, healthy readings |
| `success-100` | `#D5F5E3` | Success background fills |

### Neutral Palette

| Token | Hex | Usage |
|---|---|---|
| `neutral-900` | `#1A1A1A` | Primary text |
| `neutral-700` | `#3D3D3D` | Secondary text, labels |
| `neutral-500` | `#6B6B6B` | Placeholder, hint text |
| `neutral-300` | `#BDBDBD` | Disabled states, dividers |
| `neutral-100` | `#F2F2F2` | Card backgrounds, input fills |
| `neutral-50` | `#FAFAFA` | Page background |
| `white` | `#FFFFFF` | Surface |

### Dark Mode Equivalents
Every token has a dark-mode counterpart. Dark mode is supported but secondary — prioritise light mode for field use in bright sunlight.

| Light token | Dark equivalent |
|---|---|
| `neutral-50` (page bg) | `#121212` |
| `white` (surface) | `#1E1E1E` |
| `neutral-100` (card) | `#2C2C2C` |
| `primary-600` | `#2DAE5A` (lightened for dark bg contrast) |
| `neutral-900` (text) | `#F0F0F0` |

---

## Typography

### Font Families
- **Latin / English**: Nunito (Google Fonts). Warm, rounded, highly legible at small sizes.
- **Devanagari (Marathi / Hindi)**: Noto Sans Devanagari (Google Fonts). Excellent Unicode coverage.
- Fallback stack: `Nunito, Noto Sans Devanagari, sans-serif`

Load both fonts via `google_fonts` package. Preload Noto Sans Devanagari if system locale is Marathi/Hindi.

### Type Scale

| Role | Size | Weight | Line Height | Flutter TextStyle name |
|---|---|---|---|---|
| Display | 28sp | 700 | 1.2 | `AppTextStyles.display` |
| Headline 1 | 24sp | 700 | 1.25 | `AppTextStyles.h1` |
| Headline 2 | 20sp | 600 | 1.3 | `AppTextStyles.h2` |
| Headline 3 | 18sp | 600 | 1.35 | `AppTextStyles.h3` |
| Body Large | 16sp | 400 | 1.6 | `AppTextStyles.bodyLarge` |
| Body | 14sp | 400 | 1.6 | `AppTextStyles.body` |
| Body Small | 12sp | 400 | 1.5 | `AppTextStyles.bodySmall` |
| Label | 12sp | 600 | 1.4 | `AppTextStyles.label` |
| Caption | 11sp | 400 | 1.4 | `AppTextStyles.caption` |

**Never go below 11sp on any production screen.** On Marathi text, add 10% line height to all styles to accommodate diacritics.

---

## Spacing System

Use an 8dp base grid. All spacing values are multiples of 4.

| Token | Value | Usage |
|---|---|---|
| `space-4` | 4dp | Icon-to-label gap, tight inline spacing |
| `space-8` | 8dp | Inner component padding (compact) |
| `space-12` | 12dp | List item vertical padding |
| `space-16` | 16dp | Standard card padding, screen horizontal margin |
| `space-20` | 20dp | Section spacing within a screen |
| `space-24` | 24dp | Card-to-card gap, section header bottom margin |
| `space-32` | 32dp | Major section separation |
| `space-48` | 48dp | Full-page section separation |

Screen horizontal padding: **16dp** on mobile, **24dp** on tablet/desktop web.
Maximum content width on web: **1200px**, centered.

---

## Shape & Elevation

### Border Radius
| Token | Value | Usage |
|---|---|---|
| `radius-sm` | 6dp | Chips, tags, small badges |
| `radius-md` | 12dp | Input fields, cards, buttons |
| `radius-lg` | 16dp | Bottom sheets, dialogs, large cards |
| `radius-xl` | 24dp | Floating action elements, hero cards |
| `radius-full` | 999dp | Pill buttons, avatar badges, toggle switches |

### Elevation (Material 3 tonal elevation)
- Level 0: `#FAFAFA` — page background (no shadow)
- Level 1: `#FFFFFF` + `BoxShadow(0 1 3 rgba(0,0,0,0.08))` — standard cards
- Level 2: `#FFFFFF` + `BoxShadow(0 2 8 rgba(0,0,0,0.10))` — focused cards, drawers
- Level 3: `#FFFFFF` + `BoxShadow(0 4 16 rgba(0,0,0,0.12))` — modals, bottom sheets

No more than 3 elevation levels visible on a single screen.

---

## Iconography

Use **Phosphor Icons** (`phosphor_flutter` package) — weight `regular` for navigation, `bold` for primary actions and alerts.

### Icon mapping (key)
| Concept | Phosphor icon |
|---|---|
| Animal / livestock | `PhosphorIcons.cow` |
| Disease / diagnosis | `PhosphorIcons.stethoscope` |
| Alert / warning | `PhosphorIcons.warning` |
| Vaccination | `PhosphorIcons.syringe` |
| Veterinarian | `PhosphorIcons.userMd` (or `userCheck`) |
| GPS / location | `PhosphorIcons.mapPin` |
| Camera / photo | `PhosphorIcons.camera` |
| QR code | `PhosphorIcons.qrCode` |
| Temperature | `PhosphorIcons.thermometer` |
| Heart rate | `PhosphorIcons.heartbeat` |
| Report / document | `PhosphorIcons.filePdf` |
| Video call | `PhosphorIcons.videoCamera` |
| Offline | `PhosphorIcons.wifiSlash` |
| Notification | `PhosphorIcons.bell` |
| Settings | `PhosphorIcons.gear` |
| Sync | `PhosphorIcons.arrowsClockwise` |
| Outbreak / heatmap | `PhosphorIcons.mapTrifold` |

Icon size: 20dp inline, 24dp for navigation, 32dp for empty states and illustration icons.

---

## Component Library

All components live in `lib/core/widgets/`. They must be self-contained and accept only typed parameters.

### BioHerdButton
Three variants:
- **Primary**: `primary-600` fill, white text, 12dp radius, 48dp height minimum, full-width by default on mobile.
- **Secondary**: transparent fill, `primary-600` border (1.5dp), `primary-600` text.
- **Danger**: `danger-600` fill, white text.

Loading state: replace label with a 20dp `CircularProgressIndicator.adaptive()` in the button's colour, disable tap.
Disabled state: 40% opacity, no interaction.

### BioHerdInputField
- Fill: `neutral-100`, border: 1dp `neutral-300`, focused border: 2dp `primary-500`
- Error state: 2dp `danger-600` border + red helper text below
- 12dp border radius, 16dp horizontal padding, 14dp vertical padding
- Always has a floating label (AnimatedLabel behaviour)
- Voice input icon on the right for symptom text fields

### BioHerdCard
- White fill, Level-1 shadow, 12dp radius, 16dp padding
- A `severity` prop tints the left border: green (low), amber (medium), orange (warning), red (critical/high)
- Tappable cards get an InkWell ripple in `primary-50`

### SeverityBadge
Pill shape (radius-full), 10sp bold label.
- Low: `success-100` fill, `success-600` text
- Medium: `warning-100` fill, `warning-600` text
- High: `danger-100` fill, `danger-600` text, pulsing dot animation
- Critical: `danger-600` fill, white text, persistent shake animation on first render

### AIConfidenceMeter
Horizontal bar with a percentage label.
- 0–40%: `danger-600` bar
- 41–70%: `warning-600` bar
- 71–100%: `success-600` bar
- Always shows: model name label, confidence %, "AI assisted" disclaimer in 11sp neutral-500

### AnimalCard (list item)
- Left: circular avatar showing species icon (phosphor) on `primary-50` background, size 48dp
- Centre: animal tag ID (bold, 14sp), species + breed (12sp neutral-500), last event date (12sp)
- Right: SeverityBadge if there's an active health event
- Entire card is tappable → Animal Detail screen

### OfflineBanner
Persistent amber bar at the top of the screen when offline.
- Left: `PhosphorIcons.wifiSlash` 16dp
- Text: "You're offline. Data will sync when connected." in the farmer's language
- Dismissible: no (always visible while offline)
- When a sync is in progress: replace static text with "Syncing… X items pending" + a linear progress indicator

### SkeletonLoader
Shimmer-effect rectangles matching the layout of the actual content. Every screen that fetches data must show a skeleton during load — no spinner-only states except for button loading.

### MapWidget
Built on `flutter_map` with MapLibre/OpenStreetMap tiles.
- Farmer home: shows their farm pin + nearest vet centre
- Government dashboard: choropleth layer (GeoJSON fill + opacity based on outbreak risk score)
- Cluster markers when zoomed out (>10 farms in viewport)
- Accessible: map has a descriptive `Semantics` label; all critical data is also available in a table below the map

---

## Screen-by-Screen UX Specifications

### Farmer — Home Dashboard
Layout: vertical scroll, top-to-bottom priority.
1. **Header bar**: greeting ("Namaste, [First Name]"), farm name, notification bell icon with unread badge.
2. **Active alert card** (if any): BioHerdCard with red severity border, alert title, tap → Alert detail. This card is always first when present.
3. **Quick actions row**: 4 equal buttons — "Report Symptom", "Scan QR", "My Animals", "Vaccinations". Icon above, label below. 80dp tap area each.
4. **My herd summary**: horizontal scroll row of AnimalCards (max 5 visible, "See all" link).
5. **Upcoming vaccinations**: next 3 due vaccinations in a list, sorted by due date.
6. **Recent activity**: last 5 health events in a timeline view.

### Farmer — Symptom Report Wizard
Multi-step with a step indicator at the top (dots, current step filled green).

**Step 1 — Select animal**: search field + list of AnimalCards. Or tap "Scan QR". Selected animal shows a confirmation card.

**Step 2 — Photos**: camera capture + gallery pick. Up to 5 photos. Each photo shows a thumbnail + delete icon. Instruction text: "Take clear photos of the affected area" in farmer's language. No photo is allowed — system notes text-only mode.

**Step 3 — Symptom checklist**: scrollable list of checkboxes grouped by body system (General, Respiratory, Digestive, Skin, Locomotion). Each item has an icon and plain-language label in the farmer's language.

**Step 4 — Describe**: BioHerdInputField with voice input. 400 character limit shown as a counter. Helper text: "Describe what you noticed, when it started, and any changes."

**Step 5 — Review & Submit**: summary card showing: animal, selected symptoms (chips), photo count, description excerpt. Primary button "Submit Report". On tap: optimistic local write → show progress → gRPC stream connected → show "AI is analysing…" with animated icon.

**AI Result Screen**: Arrived at after inference completes (streaming progress shown during wait).
- Header: animal name + photo
- Top disease prediction: large disease name, confidence meter, plain-language description
- Alternative predictions: compact list of top-3
- Severity badge (prominent, centre-aligned)
- "What to do next" section: actionable plain-language steps (e.g., "A vet will review this shortly. Keep the animal separated. Provide fresh water.")
- CTA button: "Track Case Status"

### Veterinarian — Case Queue
- Segmented control at top: All / Pending / In Review / Resolved
- Sorted by severity (critical first) then date
- Each case row: animal species icon, disease prediction name, farmer village, severity badge, time since submission
- Swipe right on a row → Accept case (haptic feedback)
- Pull to refresh

### Government — Outbreak Map
- Full-bleed map of Maharashtra, 60% of screen height
- Bottom sheet (draggable, default half-height): stats panel
- Map: district polygons filled by outbreak risk score (green → yellow → orange → red). Hover/tap shows district name + active case count tooltip.
- Stats panel tabs: Overview / By Disease / Vaccination Coverage
- Each tab shows charts built with `fl_chart` — clean, minimal axes, legend below the chart
- Export button (top right): triggers async report generation → shows download progress → opens share sheet

---

## Motion & Animation

Use Flutter's built-in animation system. Keep motion purposeful and short.

| Interaction | Animation | Duration | Curve |
|---|---|---|---|
| Screen navigation | Slide from right (material default) | 300ms | `Curves.easeInOut` |
| Bottom sheet open | Slide up + fade | 250ms | `Curves.easeOut` |
| Card tap / expand | Scale 1.0 → 0.98 → 1.0 | 150ms | `Curves.easeInOut` |
| Alert appear | Slide down from top + fade | 200ms | `Curves.easeOut` |
| Skeleton → content | Cross-fade | 300ms | `Curves.easeIn` |
| AI analysis progress | Rotating icon + pulsing ring | Loop | `Curves.linear` |
| SeverityBadge (critical) | Horizontal shake on first show | 400ms | Custom bounce curve |
| Sync icon (syncing) | Continuous rotation | Loop | `Curves.linear` |

Respect `MediaQuery.of(context).disableAnimations` — disable all non-essential animations when the user has the Reduce Motion accessibility setting on.

---

## Responsive Layout

### Breakpoints
| Breakpoint | Min width | Target |
|---|---|---|
| `mobile` | 0dp | Phones (farmer + vet primary) |
| `tablet` | 600dp | Tablets, foldables |
| `desktop` | 1024dp | Web dashboard (government) |

Use `LayoutBuilder` + `AdaptiveLayout` from `adaptive_breakpoints`. Never hard-code device checks.

### Layout changes by breakpoint
- **Navigation**: mobile = bottom nav bar (5 items max), tablet = nav rail (left side), desktop = persistent side drawer
- **Content grid**: mobile = 1 column, tablet = 2 columns, desktop = 3+ columns with sidebar
- **Cards**: mobile = full-width, tablet = 2-up grid, desktop = 3-up grid
- **Map**: mobile = bottom sheet controls, desktop = side panel

---

## Accessibility Checklist

All screens must pass before merge:
- [ ] WCAG AA contrast ratio on all text/background pairs (minimum 4.5:1 for body text)
- [ ] All interactive elements have `Semantics` label (buttons, icons, input fields)
- [ ] No element relies solely on color to convey meaning (always pair with icon or label)
- [ ] Minimum tap target 48×48dp on all tappable elements
- [ ] Screen reader traversal order is logical (matches visual reading order)
- [ ] All images have `semanticLabel` or `excludeFromSemantics: true` if decorative
- [ ] Focus ring is visible on web (keyboard navigation)
- [ ] Forms announce validation errors to screen reader (`Semantics(liveRegion: true)`)
- [ ] Video call has a mute and end-call button that are always reachable without scrolling

---

## Offline & Error States

Every data-fetching screen must implement all four states:

| State | Component to show |
|---|---|
| Loading | SkeletonLoader matching the content layout |
| Success | Actual content |
| Empty | Illustration icon (64dp, neutral-300) + descriptive text + CTA button if applicable |
| Error | `PhosphorIcons.warning` icon + error message + "Try Again" button |

Empty state illustrations: use simple single-colour SVG illustrations (neutral-200 fill) depicting the concept — e.g., an empty barn for no animals, a clear sky for no active alerts. Keep them small (120dp max), non-distracting.

Error messages must be human-readable in the farmer's language — never show raw API error codes or stack traces.

---

## Notification Design

### Push notification anatomy
- **Title**: max 50 chars, disease name or event type prominent
- **Body**: max 100 chars, actionable plain language ("Your report is ready. Tap to view.")
- **Icon**: app icon (Notification trays strip the icon on Android 5+)
- **Color**: `primary-600` hex for Android notification accent
- **Category / channel**:
  - `ALERT_CRITICAL` — critical disease or outbreak → high importance, sound on
  - `CASE_UPDATE` — vet updated your case → default importance
  - `REMINDER` — vaccination due → low importance, no sound if DND

### In-app notification centre
- List of all notifications, sorted by date descending
- Unread notifications have a `primary-50` background tint
- Tap marks as read and navigates to the relevant screen
- "Mark all as read" button in app bar
- Each item: icon (matching alert type), title (bold), time relative ("2 hours ago"), body text (2-line clamp)

---

## Web Dashboard — Additional Design Notes

The government web dashboard uses the same design tokens but with a desktop-first layout.

### Data visualisation principles
- **Chart library**: `fl_chart` (Flutter web). Consistent with mobile.
- **Choropleth map**: district polygons from GeoJSON, fill-opacity driven by outbreak risk score (0.1 = low, 0.9 = critical). Always include a legend.
- **Color scale for outbreak risk**: `#D5F5E3` (0–20%) → `#FAE5D3` (20–50%) → `#FADBD8` (50–80%) → `#C0392B` (80–100%). This scale is also readable by people with red-green colour blindness (it uses orange/red not green/red as the contrast).
- **Charts must have accessible alt text**: each chart widget wraps in `Semantics(label: "Chart showing [description]")`.
- **Axes**: minimal tick marks (5 max per axis), no gridlines unless necessary, label every axis.
- **No pie charts** — they are perceptually inaccurate for comparative data. Use bar or donut with a centre label instead.

### Table design
- Zebra striping: alternating `white` / `neutral-50` rows
- Sortable columns: icon (↑↓) on sort header, active sort column shows direction arrow
- Sticky header row
- Pagination: 25 rows per page, prev/next buttons + page number input
- Row hover: `primary-50` tint
- Selected row (for bulk actions): `primary-100` tint + checkbox on left

---

## Design Handoff Notes

When implementing screens:

1. Always use `Theme.of(context)` and `AppTheme` constants — never hardcode colors or font sizes inline.
2. The `AppTheme` class in `lib/core/theme/app_theme.dart` exports `light` and `dark` `ThemeData` using Material 3 (`useMaterial3: true`).
3. `ColorScheme.fromSeed(seedColor: AppColors.primary600)` is used to generate the full M3 color scheme, then overridden where the design requires specific values.
4. Text styles are defined in `AppTextStyles` and referenced via the theme's `textTheme`.
5. All `SizedBox` spacing uses `AppSpacing.x` constants — never `SizedBox(height: 16)` directly.
6. Components in `lib/core/widgets/` must not import from feature modules. Feature modules can import from core.
7. Dark mode: wrap any screen in `MediaQuery` to detect brightness, pass to `AppTheme.dark`. Never check `Theme.of(context).brightness` inside a component — pass the color as a parameter.

