import os
import json

# Color definitions
colors = [
    {"name": "Bittersweet", "light": "EE6352", "dark": "C24B42"},
    {"name": "Emerald", "light": "59CD90", "dark": "3A8A60"},
    {"name": "PictonBlue", "light": "3FA7D6", "dark": "2B7FA2"},
    {"name": "Xanthous", "light": "FAC05E", "dark": "D59A42"},
    {"name": "AtomicTangerine", "light": "F79D84", "dark": "C47860"}
]

# Helper function to convert hex to RGB components
def hex_to_rgb(hex_code):
    return {
        "red": str(int(hex_code[0:2], 16) / 255),
        "green": str(int(hex_code[2:4], 16) / 255),
        "blue": str(int(hex_code[4:6], 16) / 255),
        "alpha": "1.000"
    }

# Generate colorset directories
for color in colors:
    folder_name = f"{color['name']}.colorset"
    os.makedirs(folder_name, exist_ok=True)

    contents = {
        "info": {
            "author": "xcode",
            "version": 1
        },
        "colors": [
            {
                "color": {
                    "color-space": "srgb",
                    "components": hex_to_rgb(color["light"])
                },
                "idiom": "universal"
            },
            {
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "dark"
                    }
                ],
                "color": {
                    "color-space": "srgb",
                    "components": hex_to_rgb(color["dark"])
                },
                "idiom": "universal"
            }
        ]
    }

    with open(os.path.join(folder_name, "Contents.json"), "w") as json_file:
        json.dump(contents, json_file, indent=2)
