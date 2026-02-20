import os
import json

# Helper function to convert hex to RGB components
def hex_to_rgb(hex_code):
    return {
        "red": str(int(hex_code[0:2], 16) / 255),
        "green": str(int(hex_code[2:4], 16) / 255),
        "blue": str(int(hex_code[4:6], 16) / 255),
        "alpha": "1.000"
    }

# Prompt the user for the list of colors
print("🎨 Please enter your list of colors in JSON format.")
print("   Each color should have a 'name', 'light', and 'dark' hex codes.")
print("   Paste your JSON and enter 'END' on a new line when you're done.")
print("   For example:")
print("""
[
  {
    "name": "Bittersweet",
    "light": "EE6352",
    "dark": "C24B42"
  },
  {
    "name": "Emerald",
    "light": "59CD90",
    "dark": "3A8A60"
  }
]
""")

# Read multi-line JSON input until 'END' is entered
print("Enter your colors JSON (end with 'END'):")
lines = []
while True:
    line = input()
    if line.strip() == 'END':
        break
    lines.append(line)
colors_input = '\n'.join(lines)

# Parse the colors JSON
try:
    colors = json.loads(colors_input)
except json.JSONDecodeError as e:
    print("❌ Error parsing JSON:", e)
    exit(1)

# Prompt the user for the output directory
output_dir = input("📂 Enter the directory to save the colorsets (default is current directory): ")
if not output_dir:
    output_dir = '.'

# Generate colorset directories
for color in colors:
    folder_name = f"{color['name']}.colorset"
    folder_path = os.path.join(output_dir, folder_name)
    os.makedirs(folder_path, exist_ok=True)

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

    with open(os.path.join(folder_path, "Contents.json"), "w") as json_file:
        json.dump(contents, json_file, indent=2)

print("✅ Colorset files have been generated successfully!")
