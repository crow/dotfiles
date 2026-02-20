# PPTX Layout Map — Airship 2026 Master

28 custom layouts, all placeholder-based. Original deck is 10" × 5.625" (widescreen).

## Layout Categories

### Cover/Title Slides (Layouts 0-5)
| Layout | Name | Placeholders | Use |
|---|---|---|---|
| 0 | CUSTOM_5 | title, subtitle, slide# | Cover with page number |
| 1 | CUSTOM_5_2 | title, subtitle, slide# | Cover variant 2 |
| 2 | CUSTOM_5_2_1 | title, subtitle | Cover variant (no slide#) |
| 3 | CUSTOM_5_1 | title, subtitle | Cover variant |
| 4 | CUSTOM_5_1_1 | title, subtitle | Cover variant |
| 5 | CUSTOM_5_1_1_1 | title, subtitle | Cover variant |

### Section Dividers (Layouts 6-9)
| Layout | Name | Placeholders | Use |
|---|---|---|---|
| 6 | SECTION_HEADER_4_1 | title, slide# | Feature text (wide title) |
| 7 | SECTION_HEADER_4_1_3 | title, slide# | Feature text variant |
| 8 | SECTION_HEADER_4_1_2_2 | title, subtitle, slide# | Section with label |
| 9 | SECTION_HEADER_4_1_2_1 | title, subtitle, slide# | Section with label |

### Content Slides (Layouts 10-17)
| Layout | Name | Key Placeholders | Use |
|---|---|---|---|
| 10 | ONE_COLUMN_TEXT | title, body, 2×subtitle, slide# | Full content with tag |
| 11 | ONE_COLUMN_TEXT_7 | title, slide# | Blank with title (for tables) |
| 12 | ONE_COLUMN_TEXT_6 | title, body, 2×subtitle, slide# | Content variant |
| 13 | ONE_COLUMN_TEXT_5 | title, body, subtitle, slide# | Content (fewer subtitles) |
| 14 | ONE_COLUMN_TEXT_4_1_2 | title, 2×body, 2×subtitle, slide# | Two-column text |
| 15 | ONE_COLUMN_TEXT_4_1_2_1 | title, 2×body, subtitle, slide# | Two-column variant |
| 16 | ONE_COLUMN_TEXT_4_1_1_1 | title, 3×body, 2×subtitle, slide# | Three-column text |
| 17 | ONE_COLUMN_TEXT_4_1_1_1_2 | title, 3×body+subtitle, 3×picture, slide# | 3-icon grid |

### Icon/Image Grid Slides (Layouts 18-22)
| Layout | Name | Key Placeholders | Use |
|---|---|---|---|
| 18 | CUSTOM_8 | title, 3×body, 3×title(card), subtitle, slide# | Card feature grid |
| 19 | CUSTOM_8_2 | title, 3×body+subtitle, 3×picture, slide# | 3-image grid |
| 20 | CUSTOM_8_2_1 | title, 4×body+subtitle, 4×picture, slide# | 4-image grid |
| 21 | CUSTOM_8_1 | title, 3×body+picture+subtitle, body+subtitle, slide# | Cool card feature |
| 22 | ONE_COLUMN_TEXT_4_1_1_1_2_1 | title, 4×body+subtitle+picture, slide# | 4-icon grid |

### Split Slides (Layouts 23-26)
| Layout | Name | Key Placeholders | Use |
|---|---|---|---|
| 23 | ONE_COLUMN_TEXT_4_1_1_1_1 | title, 3×body, subtitle, slide# | Three-column body |
| 24 | CUSTOM_7 | title, body, subtitle, 2×picture, slide# | 50/50 (text left, image right) |
| 25 | CUSTOM_7_1 | title, body, subtitle, 2×picture, slide# | 50/50 (image left, text right) |
| 26 | CUSTOM_7_1_1 | title, 2×body, subtitle, slide# | Chart/graph with callout |

### Other (Layout 27)
| Layout | Name | Placeholders | Use |
|---|---|---|---|
| 27 | CUSTOM_6 | title | Closing/thank you |

## Placeholder Index Reference

Common indices across layouts:
- `idx=0` → TITLE (main heading)
- `idx=1` → SUBTITLE or BODY (first content area)
- `idx=2` → SUBTITLE (tag/label) or secondary content
- `idx=12` → SLIDE_NUMBER
- `idx=3+` → Additional content areas, pictures

## python-pptx Usage Pattern

```python
from pptx import Presentation

# Load template
prs = Presentation("AIRSHIP 2026 Master.pptx")

# Delete existing slides (keep layouts)
while len(prs.slides) > 0:
    rId = prs.slides._sldIdLst[0].rId
    prs.part.drop_rel(rId)
    del prs.slides._sldIdLst[0]

# Add slide using layout
layout = prs.slide_layouts[0]  # CUSTOM_5 (cover)
slide = prs.slides.add_slide(layout)

# Fill placeholders
slide.placeholders[0].text = "Presentation Title"
slide.placeholders[1].text = "Subtitle"

prs.save("output.pptx")
```
