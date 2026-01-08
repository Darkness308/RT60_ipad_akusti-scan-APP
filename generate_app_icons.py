#!/usr/bin/env python3
"""
Generate placeholder app icons for AcoustiScan iOS app.
Creates solid color PNG icons at all required sizes.
"""

from PIL import Image, ImageDraw, ImageFont
import os

# iOS blue color
ICON_COLOR = "#007AFF"

# Output directory
OUTPUT_DIR = "/home/user/RT60_ipad_akusti-scan-APP/AcoustiScanApp/AcoustiScanApp/Assets.xcassets/AppIcon.appiconset"

# Icon specifications (filename, size)
ICONS = [
    ("icon-20@1x.png", 20),
    ("icon-20@2x.png", 40),
    ("icon-29@1x.png", 29),
    ("icon-29@2x.png", 58),
    ("icon-40@1x.png", 40),
    ("icon-40@2x.png", 80),
    ("icon-76@1x.png", 76),
    ("icon-76@2x.png", 152),
    ("icon-83.5@2x.png", 167),
    ("icon-1024.png", 1024),
]

def create_icon(filename, size, output_dir):
    """Create a solid color icon with optional text overlay."""
    # Create a new image with the iOS blue color
    img = Image.new('RGB', (size, size), ICON_COLOR)
    draw = ImageDraw.Draw(img)

    # Add a simple white circle in the center for visual interest
    margin = size // 6
    circle_bounds = [margin, margin, size - margin, size - margin]
    draw.ellipse(circle_bounds, fill='white', outline='white')

    # Add "AS" text for AcoustiScan (only for larger icons)
    if size >= 76:
        try:
            # Calculate font size based on icon size
            font_size = size // 3
            # Try to use a default font, fallback to PIL's default
            try:
                font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
            except:
                font = ImageFont.load_default()

            text = "AS"
            # Get text bounding box for centering
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]

            position = ((size - text_width) // 2, (size - text_height) // 2 - size // 20)
            draw.text(position, text, fill=ICON_COLOR, font=font)
        except Exception as e:
            print(f"Note: Could not add text to {filename}: {e}")

    # Save the icon
    output_path = os.path.join(output_dir, filename)
    img.save(output_path, "PNG")
    print(f"Created: {filename} ({size}x{size})")

def main():
    """Generate all app icons."""
    print("Generating placeholder app icons for AcoustiScan...")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Icon color: {ICON_COLOR}")
    print("-" * 50)

    # Ensure output directory exists
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Generate each icon
    for filename, size in ICONS:
        create_icon(filename, size, OUTPUT_DIR)

    print("-" * 50)
    print(f"Successfully generated {len(ICONS)} app icons!")
    print("\nGenerated files:")
    for filename, size in ICONS:
        filepath = os.path.join(OUTPUT_DIR, filename)
        if os.path.exists(filepath):
            file_size = os.path.getsize(filepath)
            print(f"  {filename} - {size}x{size} ({file_size:,} bytes)")

if __name__ == "__main__":
    main()
