---
name: airship-slides-v2
description: Create branded Airship presentations as fully editable PPTX files. Use when the user asks to create, build, or generate a presentation, slide deck, pitch deck, or slides. Uses the original Airship brand template with all 28 layouts — output is pixel-perfect and fully editable in PowerPoint, Google Slides, or Keynote. No Slidev or Node.js required — just Python.
---

# Airship Slides v2 — Native PPTX Generation

Generate branded Airship presentations as fully editable PowerPoint files using the original brand template.

## Prerequisites

- Python 3 with `python-pptx` installed (`pip3 install python-pptx`)

## Workflow

1. **Gather requirements** — topic, audience, key messages, approximate slide count
2. **Read `references/branding.md`** for brand colors, typography, and visual rules
3. **Read `references/layout-map.md`** for available layouts and their placeholder structure
4. **Create a JSON input file** with slide content mapped to layouts
5. **Run `scripts/generate.py`** to produce the PPTX
6. **Deliver the file** — copy to Desktop, send via message tool, or open directly

## How It Works

The script uses the original Airship PPTX as a template (`assets/template/airship-master.pptx`). Each slide layout has pre-designed backgrounds, shapes, colors, fonts, and placeholder slots. The script fills the placeholders with content — so output is identical to hand-crafted Airship slides.

## Available Layouts

| Layout Name | Description | When to Use |
|---|---|---|
| `cover` through `cover_6` | Title slide (6 background variants) | Opening slide |
| `section`, `section_2` | Section divider with label | New section |
| `feature_text`, `feature_text_2` | Large statement text | Big quote or key message |
| `content` through `content_3` | Title + body + tag | General content |
| `two_column`, `two_column_2` | Two text columns | Comparing two things |
| `three_column` | Three text columns | Three parallel concepts |
| `three_icon` | 3 icons with titles + body | 3 features/benefits |
| `four_icon` | 4 icons with titles + body | 4 features/benefits |
| `three_image` | 3 images with captions | Visual showcase (3) |
| `four_image` | 4 images with captions | Visual showcase (4) |
| `split_left` | Text left, image right | Feature + visual |
| `split_right` | Image left, text right | Visual + feature |
| `chart` | Chart area + callout | Data/metrics |
| `card_grid` | 3 feature cards | Feature highlights |
| `cool_cards` | Cards with icons + side content | Detailed features |
| `blank_title` | Title only (for tables/custom) | Custom content |
| `closing` | Thank you / closing | Last slide |

## JSON Input Format

```json
{
    "slides": [
        {
            "layout": "cover",
            "title": "Presentation Title",
            "subtitle": "Subtitle text"
        },
        {
            "layout": "section",
            "title": "Chapter Title",
            "label": "SECTION 01"
        },
        {
            "layout": "three_icon",
            "title": "Slide Title",
            "tag": "TAG IN CAPS",
            "columns": [
                {"icon": "/path/to/icon.png", "subtitle": "Label", "body": "Description"},
                {"icon": "/path/to/icon.png", "subtitle": "Label", "body": "Description"},
                {"icon": "/path/to/icon.png", "subtitle": "Label", "body": "Description"}
            ]
        },
        {
            "layout": "content",
            "title": "Slide Title",
            "tag": "TAG IN CAPS",
            "body": "Body text. Use \\n\\n for paragraph breaks."
        },
        {
            "layout": "closing",
            "title": "Thank You"
        }
    ]
}
```

See `scripts/generate.py` docstring for all layout-specific fields.

## Running the Generator

```bash
python3 scripts/generate.py input.json output.pptx
```

Or with explicit template path:
```bash
python3 scripts/generate.py input.json output.pptx path/to/template.pptx
```

## Content Guidelines

- **Tags** are always ALL CAPS (e.g., "SET TAG IN CAPS", "SECTION 01")
- **Titles** are concise — one line preferred
- **Body text** uses `\n\n` for paragraph breaks, `\n` for line breaks
- **One key message per slide**
- Use cover variants (cover through cover_6) to get different background styles
- Section dividers should have a label (e.g., "SECTION 01") and a chapter title

## Post-Generation

After creating the PPTX:
1. **Open directly** — Double-click to open in PowerPoint, Keynote, or upload to Google Slides
2. **All text is editable** — Click any text to modify it
3. **Layouts are preserved** — Moving or resizing elements stays on-brand
4. **Add images** — Click picture placeholders to insert photos
5. **Export** — Save as PDF from any presentation app

## References

- **Brand guidelines:** Read `references/branding.md`
- **Layout structure:** Read `references/layout-map.md`
