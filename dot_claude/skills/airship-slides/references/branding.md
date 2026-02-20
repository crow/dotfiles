# Airship Brand Guidelines

Extracted from AIRSHIP 2026 Master.pptx brand deck.

## Color Palette

### Primary Colors
| Name | Hex | Usage |
|---|---|---|
| Dark Navy | `#0B1026` | Primary backgrounds, dark mode surfaces |
| Chartreuse / Lime | `#D2F34C` | Primary accent — CTAs, highlights, badges, icons, emphasis text |
| White | `#FFFFFF` | Text on dark backgrounds, light mode backgrounds |

### Secondary / Data Viz Colors
| Name | Hex | Usage |
|---|---|---|
| Bright Blue | `#1E90FF` | Data viz primary, secondary accent, logo color |
| Teal / Mint | `#3CDBC0` | Data viz secondary, UI highlights |
| Cyan | `#4AEADC` | Tertiary UI accent, borders |
| Medium Blue | `#7CB8E4` | Data viz tertiary |
| Light Blue | `#B8D4F0` | Data viz quaternary |

### Neutral Colors
| Name | Hex | Usage |
|---|---|---|
| Dark Card Surface | `#1A1E30` | Card backgrounds on dark navy |
| Medium Gray | `#5A5E6E` | Form fields, UI surfaces on dark |
| Light Gray | `#C8CAD0` | Secondary/body text on dark |
| Divider Gray | `#D6D8E0` | Data viz lowest priority, dividers |

### Data Visualization Sequence
Use this order for charts/graphs: Bright Blue → Teal → Chartreuse → Medium Blue → Light Blue → Light Gray → Very Light Gray → Medium Gray

## Typography

- **Primary Font:** Instrument Sans
- **Weights observed:** Medium (confirmed), likely Regular and Bold also used
- **Headings:** Large, bold, often white on dark navy or dark on white
- **Body text:** Medium weight, ~9-14pt range
- **Highlight text:** Chartreuse color for emphasis within body copy
- **Tags/labels:** ALL CAPS, smaller size (e.g., "SET TAG IN CAPS", "SECTION 01")
- **Google Fonts:** Instrument Sans is available on Google Fonts — use `@import` or `<link>` in Slidev theme

## Logo Usage

### Variants Available (in assets/logos/)
- `airship-logo-white.png` — White logo on transparent, for dark backgrounds
- `airship-wordmark-white.png` — White wordmark on transparent, for dark backgrounds
- `airship-logo-blue.png` — Blue (#1E90FF) full horizontal lockup (icon + "AIRSHIP" wordmark + ®)
- `airship-icon-blue.png` — Blue standalone icon/mark (diamond/kite shape with wave cutout and porthole)

### Logo Description
The Airship icon is a diamond/kite shape rotated ~45°, with a curved wave/swoosh cutting through the lower portion and a small circular dot (porthole) in the upper area. It evokes a stingray, kite, or stylized airship.

### Placement Rules
- Logo typically appears in the upper-left or lower-left of slides
- Page numbers appear bottom-right as `‹#›`
- Allow adequate clear space around logo

## Visual System

### Signature Motif: Organic Blob/Pebble Shape
- Asymmetric, rounded "pebble" shapes used for photo masking and decorative framing
- Photos of people using mobile phones are clipped into these blob shapes
- Available as outline elements in assets/graphics/

### Orbital Lines
- Thin concentric dashed and solid elliptical lines overlaid on or around content
- Create depth and suggest connectivity/movement
- Available in assets/graphics/orbital-lines.png

### Icon Illustration System
Two icon sets are available:

**Chartreuse line-art icons** (assets/icons/icon-*.png without "-blue"):
- Thin outlined shapes + dashed connector lines + solid filled circle "nodes"
- Represent: connection, orchestration, messaging, broadcast, conversation, security, mobile
- Use on white backgrounds

**Blue line-art icons** (assets/icons/*-blue.png):
- Same style but in Airship Blue with gray line work
- Feature orbital/dashed line decorative elements
- Represent: collaboration, global, engagement, security
- Use on white backgrounds

### Photography Style
- Lifestyle photos of people using mobile phones in urban/transit settings
- Young, diverse, connected demographic
- Cool-toned color grading with slight teal shift
- Always masked into the organic blob shape, never rectangular

## Slide Layout Patterns

### Title Slides (6 variants)
- Dark navy background with large white heading text
- Chartreuse accent elements or subtle decorative shapes
- Subtitle in lighter weight below heading
- Some variants include blob-masked lifestyle photography

### Section Dividers
- "SECTION 01" tag in caps
- "Chapter title goes in this space" as large heading
- Dark background with page number

### Content Slides
- **3-Icon Grid:** Three columns with icon + subtitle + body text, tag in caps above
- **4-Icon Grid:** Four columns, same pattern, slightly smaller text
- **3-Image Grid:** Three image slots with subtitles and body text
- **4-Image Grid:** Four image slots in 2x2 or row layout
- **50/50 Split:** Left text (tag + heading + bullets + body) / Right image or graphic
- **Chart/Graph:** Tag + heading + description, chart area, highlight callout box
- **Table:** Clean data table on white
- **Roadmap:** Timeline with labeled milestones (Instrument Sans Medium, 9pt labels)
- **Card Feature:** Cards with subtitle + body text, arranged in grid
- **Quote/Feature Text:** Large mid-length text with chartreuse highlights

### Consistent Elements Across All Slides
- Page number indicator bottom-right: `‹#›`
- Dark navy (`#0B1026`) or white backgrounds — no other background colors
- Chartreuse for all accent/highlight elements
- Tags always in ALL CAPS
- Clean, spacious layouts with generous whitespace

## Tone & Voice (Visual)
- Modern, tech-forward, confident
- Clean and minimal — not cluttered
- Data-driven (charts, metrics, roadmaps)
- Mobile-first focus throughout imagery
- Professional but not corporate — energetic chartreuse prevents stuffiness
